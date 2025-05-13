------------------------------------------------------------------------
-- Terrain generation.
--
-- Each level generator should be instantiated from a preset as so
-- illustrated:
--
-- local preset = mcl_levelgen.make_overworld_preset (seed, <params>)
-- local state = mcl_levelgen.make_terrain_generator (preset, <chunksize * 16>)
--
-- A table of node content IDs indexed by node positions and another
-- of param2s in the engine's flat array format adequately sized for a
-- single MapChunk, and the block coordinates of its origin in
-- Minecraft's coordinate space (where the Z axis is inverted by
-- comparison with Minetest's), may subsequently be provided to
-- level_state:generate, and will be populated with values derived
-- from noise.
------------------------------------------------------------------------

local toblock = mcl_levelgen.toblock
local toquart = mcl_levelgen.toquart

local terrain_generator = {}
mcl_levelgen.terrain_generator = terrain_generator

local cid_stone, cid_water_source
if core and core.get_content_id then
	cid_stone = core.get_content_id ("mcl_core:stone")
	cid_water_source = core.get_content_id ("mcl_core:water_source")
else
	cid_stone = 0
	cid_water_source = 1
end

------------------------------------------------------------------------
-- Caching density functions.
-- These functions replace their placeholder counterparts in density
-- functions when instantiated, and access the terrain generator's
-- state to perform caching, interpolation, and other analogous
-- transformations.
------------------------------------------------------------------------

local density_function = table.merge (mcl_levelgen.density_function, {
	saved_min_value = false,
	saved_max_value = false,
})
local make_density_function = mcl_levelgen.make_density_function

function density_function:min_value ()
	if self.saved_min_value then
		return self.saved_min_value
	end
	return self.input:min_value ()
end

function density_function:max_value ()
	if self.saved_max_value then
		return self.saved_max_value
	end
	return self.input:max_value ()
end

function density_function:petrify ()
	local func = self.__call
	if not self.saved_min_value then
		self.saved_min_value = self.input:min_value ()
		self.saved_max_value = self.input:max_value ()
		self.input = self.input:petrify ()
	end
	return function (x, y, z, blender)
		return func (self, x, y, z, blender)
	end
end

-- Interpolators.

local interpolator = table.merge (density_function, {
	-- Multidimensional array of noises along the Z and Y axes at
	-- the current X-axis row.
	noises_here = {},

	-- Multidimensional array of noises along the Z and Y axes at
	-- the next X-axis row.
	noises_next = {},

	-- Array holding:
	--   Cached values that correspond to the current and the next
	--   position along each axis.
	--
	--   Values produced by interpolating all pairs of values
	--   along the X and Z axes at the current and the next Y-axis
	--   column.
	--
	--   Values produced by interpolating all pairs of values
	--   along the Z axis at the current X-axis row and Y-axis
	--   column.
	data = {},

	-- Input function whose value to interpolate.
	input = nil,

	-- Value to return; interpolation is conducted in the noise
	-- sampling loop.  If nil, return the value of `input'.
	value = nil,
})

function interpolator:create_noise_arrays (n_cells_y, n_cells_xz)
	local t1 = {}
	local t2 = {}

	self.noises_here = t1
	self.noises_next = t2
	self.value = false

	for i = 1, n_cells_y + 1 do
		local t3, t4 = {}, {}
		t1[i], t2[i] = t3, t4

		for j = 1, n_cells_xz + 1 do
			t3[j], t4[j] = 0.0, 0.0
		end
	end

	local tdata = {}
	for i = 1, 8 + 4 + 2 do
		tdata[i] = 0.0
	end
	self.data = tdata
end

-- Fill this interpolator's `noises_here' or `noises_there' array
-- (according as INITIAL is non-nil or not) with values from the
-- wrapped function originating at X, Z, and
-- each position from Y_BASE to Y_BASE + N_CELLS_Y (inclusive).
--
-- CELL_HEIGHT must be the width and length of each noise cell
-- (element in this array) and its height respectively.

function interpolator:fill_noise_slice (initial, x, z_base, zoff,
					y_base, n_cells_z,
					n_cells_y, cell_width,
					cell_height)
	local array = (initial and self.noises_here or self.noises_next)
	local dst = array[zoff + 1]
	local input = self.input
	local x = x * cell_width
	local z = (z_base + zoff) * cell_width
	local y = y_base * cell_height

	for i = 0, n_cells_y do
		local val = input (x, y + i * cell_height, z)
		dst[i + 1] = val
	end
end

-- Move values along each position in `noises_here' and `noises_y' at
-- Y and Z to the `xyzNNN' fields of this interpolator in preparation
-- for interpolating within cells in this region.  Y must be relative
-- to the Y_BASE which was supplied to `fill_noise_slice'

function interpolator:cache_yz_values (y, z)
	local here, there = self.noises_here, self.noises_next
	local herez2 = here[z + 2]
	local herez1 = here[z + 1]
	local therez2 = there[z + 2]
	local therez1 = there[z + 1]
	local data = self.data

	local xyz000 = 1
	local xyz001 = 2
	local xyz010 = 3
	local xyz011 = 4
	local xyz100 = 5
	local xyz101 = 6
	local xyz110 = 7
	local xyz111 = 8

	data[xyz111] = therez2[y + 2]
	data[xyz110] = therez1[y + 2]
	data[xyz101] = therez2[y + 1]
	data[xyz100] = therez1[y + 1]
	data[xyz011] = herez2[y + 2]
	data[xyz010] = herez1[y + 2]
	data[xyz001] = herez2[y + 1]
	data[xyz000] = herez1[y + 1]
end

local function lerp1d (u, s1, s2)
	return (s2 - s1) * u + s1
end

-- Partially interpolate between the corners of the cells being
-- considered along the X and Z axes by PROGRESS on the Y axis, and
-- cache the products in `self.xz00', `xz10', `xz01', and `xz11'.

function interpolator:y_interpolate (progress)
	local xyz000 = 1
	local xyz001 = 2
	local xyz010 = 3
	local xyz011 = 4
	local xyz100 = 5
	local xyz101 = 6
	local xyz110 = 7
	local xyz111 = 8
	local xz00 = 9
	local xz01 = 10
	local xz10 = 11
	local xz11 = 12
	local data = self.data

	data[xz11] = lerp1d (progress, data[xyz101], data[xyz111])
	data[xz10] = lerp1d (progress, data[xyz100], data[xyz110])
	data[xz01] = lerp1d (progress, data[xyz001], data[xyz011])
	data[xz00] = lerp1d (progress, data[xyz000], data[xyz010])
end

-- Likewise, but along the X axis.

function interpolator:x_interpolate (progress)
	local xz00 = 9
	local xz01 = 10
	local xz10 = 11
	local xz11 = 12
	local z0 = 13
	local z1 = 14
	local data = self.data

	data[z1] = lerp1d (progress, data[xz01], data[xz11])
	data[z0] = lerp1d (progress, data[xz00], data[xz10])
end

-- Complete interpolation.

function interpolator:z_interpolate (progress)
	local z0 = 13
	local z1 = 14
	local data = self.data
	self.value = lerp1d (progress, data[z0], data[z1])
end

function interpolator:__call (x, y, z, blender)
	if self.value then
		return self.value
	else
		return self.input (x, y, z, blender)
	end
end

-- Flat Cache.

local flat_cache = table.merge (density_function, {
	input = nil,
	nvalues = 0,
	values = {},
	chunk_origin_x = false,
	chunk_origin_z = false,
})

function flat_cache:create_noise_arrays (width_and_depth_quart)
	local values = {}

	for x = 1, width_and_depth_quart + 1 do
		local tem = {}
		values[x] = tem
		for z = 1, width_and_depth_quart + 1 do
			tem[z] = 0
		end
	end

	self.values = values
	self.nvalues = #values
end

function flat_cache:clear_cache ()
	self.chunk_origin_x = false
	self.chunk_origin_z = false
end

function flat_cache:prime_noise_arrays (origin_x, origin_z)
	local nvalues = self.nvalues
	local values = self.values
	local input = self.input

	for x = 1, nvalues do
		local tem = values[x]
		for z = 1, nvalues do
			tem[z] = input (origin_x + toblock (x - 1),
					0,
					origin_z + toblock (z - 1),
					nil)
		end
	end

	self.chunk_origin_x = toquart (origin_x)
	self.chunk_origin_z = toquart (origin_z)
end

function flat_cache:__call (x, y, z, blender)
	local origin_x = self.chunk_origin_x
	if origin_x then
		local qx = toquart (x) - origin_x
		local qz = toquart (z) - self.chunk_origin_z
		local nvalues = self.nvalues
		if qx >= 0 and qz >= 0 and qx < nvalues and qz < nvalues then
			return self.values[qx + 1][qz + 1]
		end
	end
	return self.input (x, y, z, blender)
end

-- Cache Once.

local cache_once = table.merge (density_function, {
	input = nil,
	cache = {},
})

local function longhash (x, y, z)
	return (32768 + x) * 65536 * 65536 + (32768 + y) * 65536
		+ (32768 + z)
end

function cache_once:clear_cache ()
	self.cache = {}
end

function cache_once:__call (x, y, z, blender)
	local hash = longhash (x, y, z)
	local val = self.cache[hash]
	if val then
		return val
	end
	local val = self.input (x, y, z, blender)
	self.cache[hash] = val
	return val
end

-- Cache 2D

local cache_2d = table.merge (density_function, {
	input = nil,
	cache = {},
})

local function hash2d (x, z)
	return (32768 + x) * 65536 + (32768 + z)
end

function cache_2d:clear_cache ()
	self.cache = {}
end

function cache_2d:__call (x, y, z, blender)
	local hash = hash2d (x, z)
	local val = self.cache[hash]
	if val then
		return val
	end
	local val = self.input (x, 0, z, blender)
	self.cache[hash] = val
	return val
end

------------------------------------------------------------------------
-- Terrain generation.
------------------------------------------------------------------------

local function fill_interpolators (self, initial, x_cell,
				   z_cell, y_base,
				   n_cells_z, n_cells_y)
	local interpolators = self.interpolators
	for zoff = 0, n_cells_z do
		for _, interpolator in pairs (interpolators) do
			interpolator:fill_noise_slice (initial, x_cell,
						       z_cell, zoff,
						       y_base,
						       n_cells_z, n_cells_y,
						       self.cell_width,
						       self.cell_height)
		end
	end
end

local function interpolator_update (self, y, z)
	for _, interpolator in pairs (self.interpolators) do
		interpolator:cache_yz_values (y, z)
	end
end

local function interpolator_update_y (self, progress)
	for _, interpolator in pairs (self.interpolators) do
		interpolator:y_interpolate (progress)
	end
end

local function interpolator_update_x (self, progress)
	for _, interpolator in pairs (self.interpolators) do
		interpolator:x_interpolate (progress)
	end
end

local function interpolator_update_z (self, progress)
	for _, interpolator in pairs (self.interpolators) do
		interpolator:z_interpolate (progress)
	end
end

local function prepare_interpolation (self, origin_x, origin_z, x_cell,
				      z_cell, y_base, n_cells_xz, n_cells_y)
	local cachers = self.flat_caches
	for _, cacher in pairs (cachers) do
		cacher:prime_noise_arrays (origin_x, origin_z)
	end

	fill_interpolators (self, true, x_cell, z_cell, y_base,
			    n_cells_xz, n_cells_y)
end

local function exchange_slices (self)
	local interpolators = self.interpolators
	for _, interpolator in pairs (interpolators) do
		interpolator.noises_here, interpolator.noises_next
			= interpolator.noises_next, interpolator.noises_here
	end
end

local function reset_interpolators (self)
	local interpolators = self.interpolators
	for _, interpolator in pairs (interpolators) do
		interpolator.value = false
	end

	local caches = self.caches_to_clear
	for _, cache in pairs (caches) do
		cache:clear_cache ()
	end
end

local mathmax = math.max
local mathmin = math.min
local floor = math.floor
local ceil = math.ceil

-- function terrain_generator:generate (x, y, z, cids, param2s, vm_index)
-- 	for x = 0, self.chunksize - 1 do
-- 		for z = 0, self.chunksize - 1 do
-- 			for ny = 0, self.chunksize - 1 do
-- 				local index = vm_index (x, ny, z)
-- 				if ny + y <= 0 then
-- 					cids[index] = cid_stone
-- 				else
-- 					cids[index] = cid_air
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return true
-- end

local function state_from_density (aquifer, get_node, cid_default_block,
				   x, y, z, density)
	if density > 0.0 then
		return cid_default_block, 0
	end
	return get_node (aquifer, x, y, z, density)
end

local function clear_surface_level_cache (self)
	local cache = self.surface_level_cache
	for i, _ in pairs (cache) do
		cache[i] = nil
	end
end

function terrain_generator:generate (x, y, z, cids, param2s, vm_index)
	local y_min = self.y_min
	local chunksize = self.chunksize

	assert (x % 16 == 0)
	assert (z % 16 == 0)
	assert (y % 16 == 0)

	local x_level, y_level, z_level = x, y, z

	-- local x_max = x_level + chunksize - 1
	local y_max = y_level + chunksize - 1
	-- local z_max = z_level + chunksize - 1

	local cell_width = self.cell_width
	local cell_height = self.cell_height
	local x_cell = floor (x / cell_width)
	local z_cell = floor (z / cell_width)
	local level_height = self.level_height
	local horiz_cells = ceil (chunksize / cell_width)

	local level_y_max = y_min + level_height - 1
	local y_bottom_block = mathmax (y, y_min)
	local y_top_block = mathmin (y_max, level_y_max)
	if y_top_block - y_bottom_block < 0 then
		return false
	end
	local y_bottom = floor (y_bottom_block / cell_height)
	local y_top = floor (y_top_block / cell_height)

	-- Reseat the aquifer.
	local aquifer, get_node = self.aquifer, self.aquifer.get_node
	aquifer:reseat (x, y, z)
	local cid_default_block = self.cid_default_block

	-- Initialize flat cachers and interpolators.
	local y_total = y_top - y_bottom + 1
	local final_density = self.final_density
	prepare_interpolation (self, x_level, z_level,
			       x_cell, z_cell,
			       y_bottom, horiz_cells,
			       y_total)

	for x = 0, horiz_cells - 1 do
		local x_cur = x_cell + x
		local x_base = x * cell_width + x_level

		-- This calculates the _next_ slice's values.
		fill_interpolators (self, false, x_cur + 1, z_cell,
				    y_bottom, horiz_cells, y_total)
		local ncalls = 0

		for z = 0, horiz_cells - 1 do
			local z_base = z * cell_width + z_level
			for yblock = 0, y_total - 1 do
				local y = y_top - yblock
				local y_base = y * cell_height
				interpolator_update (self, y - y_bottom, z)

				-- Begin processing individual blocks
				-- in this cell.
				for iy = 1, cell_height do
					local internal_y = cell_height - iy
					local progress = internal_y / cell_height
					local y_pos = y_base + internal_y
					interpolator_update_y (self, progress)

					for internal_x = 0, cell_width - 1 do
						local progress = internal_x / cell_width
						local x_pos = x_base + internal_x
						interpolator_update_x (self, progress)

						for internal_z = 0, cell_width - 1 do
							local progress = internal_z / cell_width
							local z_pos = z_base + internal_z
							interpolator_update_z (self, progress)

							local density = final_density (x_pos, y_pos, z_pos, nil)
							local cid, param2
								= state_from_density (aquifer, get_node,
										      cid_default_block,
										      x_pos, y_pos,
										      z_pos, density)
							local index = vm_index (x_pos - x_level,
										y_pos - y_level,
										z_pos - z_level)
							cids[index] = cid
							param2s[index] = param2
						end
					end
				end
			end
		end

		exchange_slices (self)
		reset_interpolators (self)
	end

	-- Reset flat caches.
	local flat_caches = self.flat_caches
	for _, cache in pairs (flat_caches) do
		cache:clear_cache ()
	end

	-- Reset preliminary surface level cache.
	clear_surface_level_cache (self)
	return true
end

local huge = math.huge

local function sample_preliminary_surface_level (dfn, min_y, max_y, x, z, step)
	for y = max_y, min_y, -step do
		-- This constant is documented on some of the regional
		-- Minecraft wiki editions, and from testing it
		-- appears to be correct.
		if dfn (x, y, z) > 0.390625 then
			return y
		end
	end
	return huge
end

-- X and Z are to be absolute positions.

local lshift = bit.lshift
local bor = bit.bor
local band = bit.band

function terrain_generator:get_preliminary_surface_level (x, z)
	local cache = self.surface_level_cache
	local x = band (x, -4)
	local z = band (z, -4)
	local hash = bor (lshift (x + 0x8000, 16), z + 0x8000)
	local val = cache[hash]
	if val then
		return val
	end
	local dfn = self.initial_density_without_jaggedness
	local min_y = self.y_min
	local max_y = min_y + self.level_height
	local cell_height = self.cell_height
	val = sample_preliminary_surface_level (dfn, min_y, max_y, x, z, cell_height)
	cache[hash] = val
	return val
end

------------------------------------------------------------------------
-- Terrain generator instantiation.
------------------------------------------------------------------------

function mcl_levelgen.make_terrain_generator (preset, chunksize)
	local gen = table.copy (terrain_generator)
	gen.preset = preset
	gen.level_height = preset.height
	gen.y_min = preset.min_y
	gen.chunksize = chunksize
	local cell_width = preset.noise_cell_width
	local cell_height = preset.noise_cell_height
	gen.cell_width = cell_width
	gen.cell_height = cell_height

	-- chunksize is permitted not to be divisible by cell_height
	-- or cell_width.
	gen.n_cells_xz = ceil (chunksize / cell_width)
	gen.n_cells_y = ceil (mathmax (chunksize, preset.height)
			      / cell_height)
	gen.cell_total_width = gen.n_cells_xz * cell_width

	-- Wrap the preset's final density function with functions
	-- that will undertake caching and interpolation.  Save the
	-- results (and the interpolators in particular), for they
	-- must be separately primed before density samping commences
	-- in earnest.

	local density_functions = {}
	local markers = {}

	gen.interpolators = {}
	gen.flat_caches = {}
	gen.caches_to_clear = {}

	local function instantiate_marker_fns (func)
		local fn = density_functions[func]
		if fn then
			return fn
		end

		if func.is_marker then
			if markers[func.input] then
				fn = markers[func.input]
			elseif func.name == "interpolated" then
				fn = table.merge (interpolator, {
					noises_here = {},
					noises_next = {},
					input = func,
				})
				fn = make_density_function (fn)
				table.insert (gen.interpolators, fn)
				fn:create_noise_arrays (gen.n_cells_y,
							gen.n_cells_xz)
			elseif func.name == "flat_cache" then
				fn = table.merge (flat_cache, {
					input = func,
				})
				fn = make_density_function (fn)
				local qsize = toquart (gen.n_cells_xz * gen.cell_width)
				fn:create_noise_arrays (qsize)
				table.insert (gen.flat_caches, fn)
			elseif func.name == "cache_2d" then
				fn = table.merge (cache_2d, {
					input = func,
					cache = {},
				})
				fn = make_density_function (fn)
				table.insert (gen.caches_to_clear, fn)
			elseif func.name == "cache_once" then
				fn = table.merge (cache_once, {
					input = func,
					cache = {},
				})
				fn = make_density_function (fn)
				table.insert (gen.caches_to_clear, fn)
			end
			markers[func.input] = fn
		else
			fn = func
		end
		density_functions[func] = fn
		return fn
	end

	local final_density, visited
		= preset.final_density:wrap (instantiate_marker_fns,
					     mcl_levelgen.identity)
	gen.final_density = final_density:petrify ()


	local function wrapnext (noise)
		return noise:wrap_internal (instantiate_marker_fns,
					    mcl_levelgen.identity,
					    visited):petrify ()
	end
	local input = preset.initial_density_without_jaggedness
	gen.initial_density_without_jaggedness = wrapnext (input)
	gen.erosion = wrapnext (preset.erosion)
	gen.depth = wrapnext (preset.depth)
	gen.floodedness = wrapnext (preset.fluid_level_floodedness_noise)
	gen.fluid_spread = wrapnext (preset.fluid_level_spread_noise)
	gen.lava_noise = wrapnext (preset.lava_noise)
	gen.barrier_noise = wrapnext (preset.barrier_noise)
	gen.surface_level_cache = {}

	if core then
		gen.cid_default_fluid = core.get_content_id (preset.default_fluid)
		gen.cid_default_block = core.get_content_id (preset.default_block)
	else
		gen.cid_default_block = cid_stone
		gen.cid_default_fluid = cid_water_source
	end

	if preset.aquifers_enabled then
		gen.aquifer = mcl_levelgen.create_localized_aquifer (preset, gen)
	else
		gen.aquifer = mcl_levelgen.create_default_aquifer (preset, gen)
	end
	return gen
end
