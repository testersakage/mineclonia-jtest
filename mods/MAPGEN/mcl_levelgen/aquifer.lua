------------------------------------------------------------------------
-- Aquifer processing.
------------------------------------------------------------------------

local cid_air, cid_lava_source

-- local prin = false

if core and core.get_content_id then
	cid_air = core.CONTENT_AIR
	cid_lava_source = core.get_content_id ("mcl_core:lava_source")
else
	cid_air = 0
	cid_lava_source = 4
end

local aquifer = {
	preset = nil,
	sea_level = nil,
	cid_default_fluid = nil,
}

-- Default Overworld aquifer.
local mathmin = math.min
local LAVA_FLOODING_THRESHOLD = -54

function aquifer:get_node (x, y, z, density)
	local sea_level = self.sea_level
	if y < mathmin (LAVA_FLOODING_THRESHOLD, sea_level) then
		return cid_lava_source, 0
	elseif y < sea_level then
		return self.cid_default_fluid, 0
	end
	return cid_air, 0
end

function aquifer:reseat (min_x, min_y, min_z)
end

function aquifer:initialize (preset)
	self.sea_level = preset.sea_level
	self.cid_default_fluid = preset.cid_default_fluid
	self.cid_default_block = preset.cid_default_block
end

function mcl_levelgen.create_default_aquifer (preset)
	local aquifer = table.copy (aquifer)
	aquifer:initialize (preset)
	return aquifer
end

------------------------------------------------------------------------
-- Noise-based aquifers.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/chunk/AquiferSampler.Impl.html
------------------------------------------------------------------------

local CENTER_VARIABILITY_XZ = 10
local CENTER_VARIABILITY_Y = 9

local GRID_UNIT_XZ = 16
local GRID_UNIT_Y = 12

local CHUNK_POS_OFFSETS = {
	{0, 0},
	{-2, -1},
	{-1, -1},
	{0, -1},
	{1, -1},
	{-3, 0},
	{-2, 0},
	{-1, 0},
	{1, 0},
	{-2, 1},
	{-1, 1},
	{0, 1},
	{1, 1},
}

local floor = math.floor
local mathmax = math.max
local abs = math.abs

local localized_aquifer = table.merge (aquifer, {
	content_cache = {},
	location_cache = {},
	terrain_generator = nil,
})

-- These functions are manually open coded in `get_node' for otherwise
-- they tend to be blacklisted and produce trace aborts at the most
-- inopportune moments.
local function togrid_xz (pos)
	return floor (pos / GRID_UNIT_XZ)
end

local function togrid_y (pos)
	return floor (pos / GRID_UNIT_Y)
end

function mcl_levelgen.create_localized_aquifer (preset, terrain_generator)
	local aquifer = table.copy (localized_aquifer)
	aquifer:initialize (preset)

	-- TODO: initialize content IDs.
	local grid_size_horiz = togrid_xz (terrain_generator.chunksize) + 2

	-- Minecraft derives grid positions from absolute coordinates,
	-- but the extents of a mapblock that is being emerged and the
	-- bottommost Y position of the level are liable not to be
	-- divisible by GRID_UNIT_Y.  The chunk size must therefore be
	-- adjusted accordingly.
	local base = preset.min_y % GRID_UNIT_Y
	local grid_size_vert = togrid_y (base + terrain_generator.chunksize) + 3
	aquifer.y_base = base
	aquifer.xz_size = grid_size_horiz
	aquifer.y_size = grid_size_vert
	local cache_size = grid_size_horiz * grid_size_vert * grid_size_horiz
	aquifer.cache_size = cache_size
	aquifer.content_cache = {}
	aquifer.content_cache[cache_size] = nil
	aquifer.location_cache = {}
	aquifer.location_cache[cache_size] = nil
	aquifer.cid_default_block = terrain_generator.cid_default_block
	aquifer.cid_default_fluid = terrain_generator.cid_default_fluid

	local factory = preset.factory ("minecraft:aquifer"):fork_positional ()
	aquifer.rng = factory:create_reseedable ()
	aquifer.terrain_generator = terrain_generator
	aquifer.erosion = terrain_generator.erosion
	aquifer.depth = terrain_generator.depth
	aquifer.floodedness = terrain_generator.floodedness
	aquifer.spread = terrain_generator.fluid_spread
	aquifer.lava = terrain_generator.lava_noise
	aquifer.barrier = terrain_generator.barrier_noise
	return aquifer
end

--- XXX: These values are upvalues to avoid requiring a `self'
--- parameter in `localized_aquifier:get_node' and its callees.
local x_origin
local z_origin
local y_origin
local x_grid_origin
local z_grid_origin
local y_grid_origin
local location_cache
local content_cache
local xz_size
local y_size
local cid_default_fluid
local cid_default_block
local rng
local sea_level
local lavanoise
local erosion
local depth
local floodedness
local spread
local barrier
local terrain_generator

function localized_aquifer:reseat (min_x, min_y, min_z)
	x_origin = min_x - GRID_UNIT_XZ
	z_origin = min_z - GRID_UNIT_XZ
	-- MIN_Y must be relative to the level origin.
	y_origin = min_y - min_y % GRID_UNIT_Y - GRID_UNIT_Y
	assert (x_origin % GRID_UNIT_XZ == 0)
	assert (z_origin % GRID_UNIT_XZ == 0)
	assert (y_origin % GRID_UNIT_Y  == 0)

	x_grid_origin = togrid_xz (min_x) - 1
	z_grid_origin = togrid_xz (min_z) - 1
	y_grid_origin = togrid_y (min_y - min_y % GRID_UNIT_Y) - 1

	location_cache = self.location_cache
	content_cache = self.content_cache
	for i = 1, self.cache_size do
		location_cache[i] = nil
		content_cache[i] = nil
	end
	xz_size = self.xz_size
	y_size = self.y_size
	terrain_generator = self.terrain_generator
	cid_default_block = self.cid_default_block
	cid_default_fluid = self.cid_default_fluid
	rng = self.rng
	sea_level = self.sea_level
	lavanoise = self.lava
	erosion = self.erosion
	depth = self.depth
	floodedness = self.floodedness
	spread = self.spread
	barrier = self.barrier
end

local huge = math.huge
local minuscule_liquid_level = -32768
local bor = bit.bor
local band = bit.band

local function longhash (x, y, z)
	return (32768 + x) * 65536 * 65536
		+ (32768 + y) * 65536
		+ (32768 + z)
end

local function unhash (pos)
	return floor (pos / (65536 * 65536)) - 32768,
		band (floor (pos / 65536), 0xffff) - 32768,
		pos % 65536 - 32768
end

local function gindex (xz_size, y_size, xgrid, ygrid, zgrid)
	-- assert (xgrid >= 0 and ygrid >= 0 and zgrid >= 0)
	-- assert (xgrid < xz_size and ygrid < y_size and zgrid < xz_size,
	-- 	tostring (xgrid) .. ", " .. xz_size .. ", "
	-- 	.. tostring (ygrid) .. ", " .. y_size .. ", "
	-- 	.. tostring (zgrid) .. ", " .. xz_size)
	return xgrid + ((zgrid * y_size) + ygrid) * xz_size + 1
end

local function flood_stochastically (x, y, z, min_surface_top)
	-- These are (global) aquifer section coordinates rather than
	-- aquifer grid positions.
	local x_section = floor (x / 16)
	local y_section = floor (y / 40)
	local z_section = floor (z / 16)
	local section_center = y_section * 40 + 20

	-- Spread noise is sampled once-per-section.
	-- https://gist.github.com/jacobsjo/0ce1f9d02e5c3e490e228ac5ad810482#Randomized_fluid_level
	-- This was overlooked when aquifers were initially
	-- implemented and occasioned hours of fruitless debugging.
	local noise_value
		= spread (x_section, y_section, z_section) * 10.0
	local level = floor (noise_value / 3) * 3
	-- print (x_section, y_section, z_section, level)
	return mathmin (min_surface_top - 8, section_center + level)
end

local parameters_adjoin_deep_dark = mcl_levelgen.parameters_adjoin_deep_dark

local function local_surface_level (x, y, z, sea_level,
				    min_surface_top, submerged_p)
	local erosion, depth = erosion (x, y, z), depth (x, y, z)
	if parameters_adjoin_deep_dark (erosion, depth) then
		return minuscule_liquid_level
	end

	local depth = min_surface_top - y
	local surface_proximity
	if submerged_p then
		local surface_proximity_unscaled = mathmin (mathmax (depth, 0), 64)
		surface_proximity = 1.0 - surface_proximity_unscaled / 64
	else
		surface_proximity = 0.0
	end
	local floodedness = mathmin (mathmax (floodedness (x, y, z),
					      -1.0), 1.0)
	-- if prin then
	-- 	print ("surfaceProximity: ", surface_proximity)
	-- 	print ("floodedness: ", floodedness)
	-- end
	local flood_threshold
		= -0.3 + (1.0 - surface_proximity) * (0.8 + 0.3)
	local stochastic_threshold
		= -0.8 + (1.0 - surface_proximity) * (0.4 + 0.8)

	if floodedness > flood_threshold then
		-- Flood completely.
		return sea_level
	elseif floodedness > stochastic_threshold then
		-- Stochastic flooding.
		return flood_stochastically (x, y, z, min_surface_top)
	else
		-- if prin then
		-- 	print ("no flooding")
		-- end
		-- Don't flood at all.
		return minuscule_liquid_level
	end
end

local LAVA_GENERATION_THRESHOLD = -10

-- Values are the surface height of this fluid and whether it must be
-- lava.
local function compute_fluid_content (x, y, z)
	local sea_level = sea_level
	local y_above = y + GRID_UNIT_Y
	local y_below = y - GRID_UNIT_Y
	local this_pos_submerged_p = false
	local terrain = terrain_generator
	local min_surface_top = huge

	-- Sample chunks around this position to measure the lowest
	-- surface level in the vicinity.  If any surface is submerged
	-- and beneath sea level
	for i, offset in ipairs (CHUNK_POS_OFFSETS) do
		local sx = x + offset[1] * 16
		local sz = z + offset[2] * 16
		local surface = terrain:get_preliminary_surface_level (sx, sz)
		local surface_pos = surface + 8

		-- if prin then
		-- 	print (sx, sz, surface)
		-- end

		-- If the surface is completely beneath the current
		-- position, return the default sea level.
		if i == 1 and y_below > surface_pos then
			return sea_level, false
		end

		-- Likewise if the surface is below sea level and
		-- overlaps a certain vertical interval centered
		-- around the current position.
		local sample_submerged = y_above > surface_pos
		if sample_submerged or i == 1 then
			if surface_pos < sea_level then
				if i == 1 then
					this_pos_submerged_p = true
				end

				if sample_submerged then
					return sea_level, false
				end
			end
		end

		min_surface_top = mathmin (min_surface_top, surface_pos)
	end

	-- if prin then
	-- 	print (" ===> " .. min_surface_top - 8 .. " " .. tostring (this_pos_submerged_p))
	-- end
	local new_surface_level
		= local_surface_level (x, y, z, sea_level,
				       min_surface_top,
				       this_pos_submerged_p)

	-- Decide whether to return lava.  TODO: disable this
	-- mechanism in the Nether.
	if new_surface_level ~= huge
		and new_surface_level < LAVA_GENERATION_THRESHOLD then
		local xsection = floor (x / 64)
		local ysection = floor (y / 40)
		local zsection = floor (z / 64)
		local lava_sample = lavanoise (xsection, ysection, zsection)
		if abs (lava_sample) > 0.3 then
			return new_surface_level, true
		end
	end
	return new_surface_level, false
end

local function encode_fluid_content (level, lava)
	return bor (level + 0x8000, lava and 0x10000 or 0)
end

local function decode_fluid_content (data)
	return band (data, 0xffff) - 0x8000, band (data, 0x10000) ~= 0
end

local function get_fluid_content (x, y, z, cache, gindex)
	local val = cache[gindex]
	if val then
		return decode_fluid_content (val)
	end
	local surface_level, lava = compute_fluid_content (x, y, z)
	val = encode_fluid_content (surface_level, lava)
	cache[gindex] = val
	return surface_level, lava
end

local SQR_5 = 5 * 5

local function closeness (d1, d2)
	return 1.0 - abs (d2 - d1) / SQR_5
end

local function evaluate (depth, lava, y)
	if y < depth then
		return (lava or y < LAVA_FLOODING_THRESHOLD)
			and cid_lava_source or cid_default_fluid, 0
	else
		return cid_air, 0
	end
end

local function get_pressure (x, y, z, level_closest, lava_closest,
			     level_avg, lava_avg)
	-- One or more aquifers are inactive.
	if not (level_closest >= level_avg and level_avg > y)
	-- or both liquids are of identical types.
		or y < LAVA_FLOODING_THRESHOLD
		or lava_closest == lava_avg then
		local level_diff = abs (level_closest - level_avg)
		if level_diff == 0.0 then
			return 0.0
		end
		local center = 0.5 * (level_closest + level_avg)
		local offset_here = y + 0.5 - center
		local raw_pressure

		if offset_here > 0.0 then
			local half_diff = level_diff / 2.0
			local dist_center = half_diff - abs (offset_here)
			if dist_center > 0.0 then
				raw_pressure = dist_center / 1.5
			else
				raw_pressure = dist_center / 2.5
			end
		else
			local half_diff = level_diff / 2.0
			local dist_center = half_diff - abs (offset_here)
			local shifted = 3.0 + dist_center
			if shifted > 0.0 then
				raw_pressure = shifted / 3.0
			else
				raw_pressure = shifted / 10.0
			end
		end

		local barrier_val = 0.0
		if raw_pressure >= -2.0 and raw_pressure <= 2.0 then
			barrier_val = barrier (x, y, z)
		end
		return 2.0 * (barrier_val + raw_pressure)
	end

	-- Return the default pressure if the liquid types differ and
	-- neither is air.
	return 2.0
end

local posbuf = { 0, 0, 0, }
local distbuf = { 0, 0, 0, }
local hashbuf = { }
for i = 1, 12 do
	hashbuf[i] = 0
end

local pos_closest = 1
local pos_average = 2
local pos_furthest = 3
local dist_closest = 1
local dist_average = 2
local dist_furthest = 3

local offsets = {}
for dx = 0, 1 do
	for dy = -1, 1 do
		for dz = 0, 1 do
			table.insert (offsets, dx)
			table.insert (offsets, dy)
			table.insert (offsets, dz)
		end
	end
end

local function pick_grid_positions (rx, ry, rz)
	local hashbuf = hashbuf
	do
		local xstart = floor ((rx - 5) / 16)
		local ystart = floor ((ry + 1) / 12)
		local zstart = floor ((rz - 5) / 16)
		for i = 1, 12 do
			local xgrid = xstart + offsets[(i - 1) * 3 + 1]
			local ygrid = ystart + offsets[(i - 1) * 3 + 2]
			local zgrid = zstart + offsets[(i - 1) * 3 + 3]
			local index = gindex (xz_size, y_size,
					      xgrid, ygrid, zgrid,
					      i, zstart)
			local pos = location_cache[index]
			if not pos then
				local xrnd = xgrid + x_grid_origin
				local yrnd = ygrid + y_grid_origin
				local zrnd = zgrid + z_grid_origin
				rng:reseed_positional (xrnd, yrnd, zrnd)

				local x = rng:next_within (CENTER_VARIABILITY_XZ)
				x = xgrid * GRID_UNIT_XZ + x
				local y = rng:next_within (CENTER_VARIABILITY_Y)
				y = ygrid * GRID_UNIT_Y + y
				local z = rng:next_within (CENTER_VARIABILITY_XZ)
				z = zgrid * GRID_UNIT_XZ + z
				pos = longhash (x, y, z)
				location_cache[index] = pos
			end
			hashbuf[i] = pos
		end
	end

	for _, value in ipairs (hashbuf) do
		local lx, ly, lz = unhash (value)
		local d
		do
			local dx = lx - rx
			local dy = ly - ry
			local dz = lz - rz
			d = dx * dx + dy * dy + dz * dz
		end

		if distbuf[dist_closest] >= d then
			posbuf[pos_furthest] = posbuf[pos_average]
			distbuf[dist_furthest] = distbuf[dist_average]
			posbuf[pos_average] = posbuf[pos_closest]
			distbuf[dist_average] = distbuf[dist_closest]
			posbuf[pos_closest] = value
			distbuf[dist_closest] = d
		elseif distbuf[dist_average] >= d then
			posbuf[pos_furthest] = posbuf[pos_average]
			distbuf[dist_furthest] = distbuf[dist_average]
			posbuf[pos_average] = value
			distbuf[dist_average] = d
		elseif distbuf[dist_furthest] >= d then
			posbuf[pos_furthest] = value
			distbuf[dist_furthest] = d
		end
	end
end

function localized_aquifer.get_node (_, x, y, z, density)
	local xo = x_origin
	local yo = y_origin
	local zo = z_origin

	-- X, Y, Z in block coordinates relative to aquifer origin.
	local rx = x - xo
	local ry = y - yo
	local rz = z - zo
	local xz_size = xz_size
	local y_size = y_size

	if y < LAVA_FLOODING_THRESHOLD then
		return cid_lava_source, 0
	else
		distbuf[dist_closest] = huge
		distbuf[dist_average] = huge
		distbuf[dist_furthest] = huge

		-- Select the three closest positions out of 2x3x2
		-- random positions selected from around the center of
		-- this grid coordinate.
		pick_grid_positions (rx, ry, rz)

		-- Ascertain the fluid content of the nearest position.
		local cache = content_cache
		local lx, ly, lz = unhash (posbuf[pos_closest])
		local gx, gy, gz = floor (lx / 16), floor (ly / 12), floor (lz / 16)
		local index = gindex (xz_size, y_size, gx, gy, gz)
		local depth, lava = get_fluid_content (lx + xo, ly + yo, lz + zo,
						       cache, index)
		local d = closeness (distbuf[dist_closest], distbuf[dist_average])

		-- if x == 26 and y == -4 and z == 31 then
		-- 	print ("D: ", d, distbuf[dist_closest],
		-- 	       distbuf[dist_average])
		-- end

		-- If the nearest aquifer center is too distant from
		-- the second closest to be significant, return the
		-- fluid type derived from the former.
		if (d <= 0.0)
			-- Or if water but one block above lava level
			or (not lava and y == LAVA_FLOODING_THRESHOLD) then
			return evaluate (depth, lava, y)
		else
			-- Otherwise, calculate whether the pressure
			-- differential between the current aquifer
			-- position and its nearest neighbors is
			-- sufficiently great to prompt barrier
			-- formation.
			local index
			do
				lx, ly, lz = unhash (posbuf[pos_average])
				local gx, gy, gz = floor (lx / 16), floor (ly / 12), floor (lz / 16)
				index = gindex (xz_size, y_size, gx, gy, gz)
			end

			-- if x == 26 and y == -4 and z == 31 then
			-- 	prin = true
			-- end
			local avg_depth, avg_lava
				= get_fluid_content (lx + xo, ly + yo, lz + zo,
						     cache, index)
			local pressure
				= get_pressure (x, y, z, depth, lava,
						avg_depth, avg_lava)
			-- if x == 26 and y == -4 and z == 31 then
			-- 	prin = false
			-- 	print (pressure, depth, avg_depth, lx + xo, ly + yo, lz + zo)
			-- end
			if density + pressure * d > 0.0 then
				-- Generate a barrier.
				return cid_default_block, 0
			end

			-- Repeat the process with the remaining
			-- neighbors.
			local d0 = closeness (distbuf[dist_closest], distbuf[dist_furthest])
			local d1 = closeness (distbuf[dist_average], distbuf[dist_furthest])
			local far_depth, far_lava
			if d0 > 0.0 or d1 > 0.0 then
				local lx, ly, lz = unhash (posbuf[pos_furthest])
				local gx, gy, gz = floor (lx / 16), floor (ly / 12), floor (lz / 16)
				local index = gindex (xz_size, y_size, gx, gy, gz)
				far_depth, far_lava
					= get_fluid_content (lx + xo, ly + yo, lz + zo,
							     cache, index)

				if d0 > 0.0 then
					local pressure = get_pressure (x, y, z, depth, lava,
								       far_depth, far_lava)
					if density + d * d0 * pressure > 0.0 then
						-- Generate a barrier.
						return cid_default_block, 0
					end
				end

				if d1 > 0.0 then
					local pressure = get_pressure (x, y, z, avg_depth, avg_lava,
								       far_depth, far_lava)
					if density + d * d1 * pressure > 0.0 then
						-- Generate a barrier.
						return cid_default_block, 0
					end
				end
			end
			return evaluate (depth, lava, y)
		end
	end
end
