------------------------------------------------------------------------
-- Structure generation.
--
-- When a MapChunk is generated, aggregations of structures called
-- structure sets are tested against all neighboring chunks within
-- eight Minecraft chunks of the said MapChunk.  A structure set is
-- an aggregation of structures combined with placement mechanics.
--
-- If a structure set assigns a structure to a chunk, this assignment
-- is referred to as a structure start.  A structure start provides
-- enough data ("structure pieces") deterministically to reproduce a
-- structure throughout all of the MapChunks it spans, and each such
-- chunk is said to hold a reference to structure starts which
-- intersect it.  This data may influence the noise sampling process
-- (by means of "beardifier" values) to adapt terrain to the presence
-- of a structure, and subsequently, when a MapChunk's terrain is
-- generated, those portions of structure starts referenced by the
-- chunks inside which intersect with the MapChunk are placed, and the
-- generated MapChunk is emerged.
------------------------------------------------------------------------

local ull = mcl_levelgen.ull
local insert = table.insert

local function indexof (list, val)
	for i, v in ipairs (list) do
		if v == val then
			return i
		end
	end
	return -1
end

------------------------------------------------------------------------
-- Structure placement.
------------------------------------------------------------------------

local NUM_GENERATION_STEPS = 11

mcl_levelgen.RAW_GENERATION = 1
mcl_levelgen.LAKES = 2
mcl_levelgen.LOCAL_MODIFICATIONS = 3
mcl_levelgen.UNDERGROUND_STRUCTURES = 4
mcl_levelgen.SURFACE_STRUCTURES = 5
mcl_levelgen.STRONGHOLDS = 6
mcl_levelgen.UNDERGROUND_ORES = 7
mcl_levelgen.UNDERGROUND_DECORATION = 8
mcl_levelgen.FLUID_SPRINGS = 9
mcl_levelgen.VEGETAL_DECORATION = 10
mcl_levelgen.TOP_LAYER_MODIFICATION = 11

local floor = math.floor
local ceil = math.ceil
local mathmin = math.min
local mathmax = math.max
local huge = math.huge

-- local structure_placement = {
-- 	locate_offset = { 0, 0, 0, },
-- 	frequency_reduction_method = nil,
-- 	frequency = 1.0,
-- 	salt = 0,
-- 	exclusion_zone = nil,
-- 	chunk_test = nil,
-- }

local function rtz (x)
	if x >= 0 then
		return floor (x)
	else
		return ceil (x)
	end
end

local default_rng = mcl_levelgen.jvm_random (ull (0, 0))
local set_region_seed = mcl_levelgen.set_region_seed
local set_carver_seed = mcl_levelgen.set_carver_seed

-- Distribution methods.

function build_random_spread_chunk_test (spacing, separation, spread_method)
	local function distribute_triangular (rng, n)
		return rtz ((rng:next_within (n) + rng:next_within (n)) / 2)
	end
	local function distribute_linear (rng, n)
		return rng:next_within (n)
	end
	assert (spacing > separation, "Separation cannot be satisfied by spacing")

	local distribute = distribute_linear
	if spread_method == "triangular" then
		distribute = distribute_triangular
	end

	local rng = default_rng
	return function (level_seed, salt, cx, cz)
		-- Divide the level into SPACING sized regions and
		-- select a random chunk within that is at least
		-- SEPARATION removed from adjacent regions.
		local region_x = floor (cx / spacing)
		local region_z = floor (cz / spacing)
		set_region_seed (rng, level_seed, region_x, region_z, salt)
		local cx1 = distribute (rng, spacing - separation)
		local cz1 = distribute (rng, spacing - separation)
		return cx == (region_x * spacing + cx1)
			and cz == (region_z * spacing + cz1)
	end
end

if false then
	local l = build_random_spread_chunk_test (32, 8, "linear")
	local level_seed = ull (0, 0)
	mcl_levelgen.stringtoull (level_seed, "44877572094875933")
	for x = -256, 255 do
		for z = -256, 255 do
			if l (level_seed, 48580, x, z) then
				print ("  (1) structure_start: ", x, z)
			end
		end
	end
end

-- Frequency reduction methods.

local function frequency_reducer_default (level_seed, salt, cx, cz,
					  frequency)
	-- Note: this is intentional as salt and cz are exchanged in
	-- Minecraft.
	set_region_seed (default_rng, level_seed, salt, cx, cz)
	return default_rng:next_float () < frequency
end

if false then
	local level_seed = ull (0, 0)
	mcl_levelgen.stringtoull (level_seed, "44877572094875933")
	for x = -64, 63 do
		for z = -64, 63 do
			if frequency_reducer_default (level_seed, 0, x, z, 1/48) then
				print (" (D) Should generate: " .. x .. ", " .. z)
			end
		end
	end
end

local arshift = bit.arshift
local lshift = bit.lshift
local bxor = bit.bxor
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local tmp = ull (0, 0)
local extkull = mcl_levelgen.extkull
local xorull = mcl_levelgen.xorull

local function frequency_reducer_type_1 (level_seed, salt, cx, cz, frequency)
	local cx_component = arshift (cx, 4)
	local hash = bxor (cx_component, band (cz, bnot (15)))
	extkull (tmp, hash)
	xorull (tmp, level_seed)
	default_rng:reseed (tmp)
	default_rng:next_integer ()
	return default_rng:next_within (floor (1.0 / frequency)) == 0
end

if false then
	local level_seed = ull (0, 0)
	mcl_levelgen.stringtoull (level_seed, "44877572094875933")

	for x = -64, 63 do
		for z = -64, 63 do
			if frequency_reducer_type_1 (level_seed, 0, x, z, 0.3) then
				print ("Should generate: " .. x .. ", " .. z)
			end
		end
	end
end

local function frequency_reducer_type_2 (level_seed, salt, cx, cz, frequency)
	-- https://minecraft.wiki/w/Structure_set
	-- Although this page is still partially incorrect as it
	-- overlooks the other distinction, namely, that cx and the
	-- salt are not exchanged.

	set_region_seed (default_rng, level_seed, cx, cz, 10387320)
	return default_rng:next_float () < frequency
end

if false then
	local level_seed = ull (0, 0)
	mcl_levelgen.stringtoull (level_seed, "44877572094875933")

	for x = -64, 63 do
		for z = -64, 63 do
			if frequency_reducer_type_2 (level_seed, 0, x, z, 1/22) then
				print ("Should generate: " .. x .. ", " .. z)
			end
		end
	end
end

local function frequency_reducer_type_3 (level_seed, salt, cx, cz, frequency)
	set_carver_seed (default_rng, level_seed, cx, cz)
	return default_rng:next_float () < frequency
end

if false then
	local level_seed = ull (0, 0)
	mcl_levelgen.stringtoull (level_seed, "44877572094875933")

	for x = -64, 63 do
		for z = -64, 63 do
			if frequency_reducer_type_3 (level_seed, 0, x, z, 1/409) then
				print ("Should generate: " .. x .. ", " .. z)
			end
		end
	end
end

local frequency_reducers = {
	default = frequency_reducer_default,
	legacy_type_1 = frequency_reducer_type_1,
	legacy_type_2 = frequency_reducer_type_2,
	legacy_type_3 = frequency_reducer_type_3,
}

local function evaluate_exclusions ()
	-- TODO: exclusion zones.
	return true
end

local function structure_starts_in_chunk_p (level, placement, cx, cz)
	local level_seed = level.level_seed
	local method = placement.frequency_reduction_method
	local frequency = placement.frequency
	local salt = placement.salt
	return placement.chunk_test (level_seed, salt, cx, cz)
		and (frequency >= 1.0 or method (level_seed, salt,
						 cx, cz, frequency))
		and evaluate_exclusions (placement)
end

------------------------------------------------------------------------
-- Structure registration.
------------------------------------------------------------------------

-- local structure_def = {
-- 	biomes = {},
-- 	create_start = function (self, level, rng, cx, cz) end,
-- }

-- local structure_set = {
-- 	structures = {}, -- { structure = STRUCTURE, weight = WEIGHT, ... },
-- 	total_weight = nil,
-- 	placement = nil,
-- }

local all_registered_structure_sets = {}
local registered_structures_by_step = {}

for i = 1, NUM_GENERATION_STEPS do
	registered_structures_by_step[i] = {}
end

mcl_levelgen.registered_structures = {}
mcl_levelgen.registered_structure_sets = {}

function mcl_levelgen.build_random_spread_placement (frequency, reduction,
						     spacing, separation,
						     salt, spread_type,
						     locate_offset,
						     exclusion_zone)
	local tbl = {
		frequency = frequency or 1.0,
		frequency_reduction_method
			= (reduction and assert (frequency_reducers[reduction]))
				or frequency_reducer_default,
		chunk_test = build_random_spread_chunk_test (spacing, separation,
							     spread_type),
		locate_offset = locate_offset or { 0, 0, 0, },
		exclusion_zone = exclusion_zone,
		salt = assert (salt),
	}

	return tbl
end

function mcl_levelgen.register_structure_set (keyword, tbl)
	if mcl_levelgen.registered_structure_sets[keyword] then
		error ("Structure set " .. keyword .. " is already defined...")
	end

	assert (tbl.structures)
	assert (tbl.placement)
	local structures = {}
	local total_weight = 0
	for _, structure in ipairs (tbl.structures) do
		if type (structure) == "table" then
			local weight = structure.weight
			local structure = structure.structure
			local def = mcl_levelgen.registered_structures[structure]
			if not def then
				error ("Structure is not defined: " .. structure)
			end
			total_weight = total_weight + weight
			table.insert (structures, {
				weight = weight,
				structure = def,
			})
		else
			local def = mcl_levelgen.registered_structures[structure]
			if not def then
				error ("Structure is not defined: " .. structure)
			end
			total_weight = total_weight + 1
			table.insert (structures, {
				weight = 1,
				structure = def,
			})
		end
	end
	local set = {
		structures = structures,
		total_weight = total_weight,
		placement = tbl.placement,
	}
	table.insert (all_registered_structure_sets, set)
	mcl_levelgen.registered_structure_sets[keyword] = set
	return set
end

function mcl_levelgen.register_structure (keyword, def)
	if mcl_levelgen.registered_structures[keyword] then
		error ("Structure " .. keyword .. " is already defined...")
	end
	assert (def.create_start)
	assert (def.step
		and def.step > 0
		and def.step <= NUM_GENERATION_STEPS)
	def.name = keyword
	mcl_levelgen.registered_structures[keyword] = def
	local by_step = registered_structures_by_step[def.step]
	table.insert (by_step, keyword)
	return def
end

-- Each structure piece should comprise a single function `place',
-- which places its contents strictly within the provided section of
-- the MapChunk being generated, and a field `bbox', holding the
-- bounds of the piece itself.

------------------------------------------------------------------------
-- Level-wide structure generator state.
------------------------------------------------------------------------
local ull = mcl_levelgen.ull

local function set_contains_structure_generating_in_biomes_p (set, biomes)
	for _, structure in ipairs (set.structures) do
		for _, biome in ipairs (structure.structure.biomes) do
			if indexof (biomes, biome) ~= -1 then
				return true
			end
		end
	end
	return false
end

function mcl_levelgen.make_structure_level (preset)
	local structure_level = {
		preset = preset,
		level_seed = preset.seed,
		concentric_rings_seed = preset.seed,
		structure_sets = {},
		structure_starts = {},
		structure_refs = {},
	}
	-- Enumerate all structure sets containing structures eligible
	-- to generate in biomes defined by PRESET.

	local biomes = preset:generated_biomes ()
	for _, set in ipairs (all_registered_structure_sets) do
		if set_contains_structure_generating_in_biomes_p (set, biomes) then
			table.insert (structure_level.structure_sets, set)
		end
	end
	return structure_level
end

local generation_rng = mcl_levelgen.jvm_random (ull (0, 0), ull (0, 0))
local structure_rng = mcl_levelgen.jvm_random (ull (0, 0), ull (0, 0))

-- Invoke CB with each structure start that should generate in the
-- chunk CX, CZ, CX, and CZ, LEVEL, and DATA.  LEVEL must be the
-- structure level representing the level in which structures are to
-- generate.

local function do_nothing ()
end

local function get_structure_starts (level, terrain, cx, cz, cb, data)
	for _, set in ipairs (level.structure_sets) do
		local structures = set.structures
		local total_weight = set.total_weight
		local n_structures = #structures
		local seed = level.level_seed

		if not structure_starts_in_chunk_p (level, set.placement, cx, cz) then
			do_nothing ()
		elseif n_structures == 1 then
			set_carver_seed (structure_rng, seed, cx, cz)
			local start = structures[1].structure:create_start (level, terrain,
									    structure_rng,
									    cx, cz)
			if start then
				cb (start, cx, cz, level, data)
			end
		else
			set_carver_seed (generation_rng, seed, cx, cz)
			local indices_eliminated = {}
			while #indices_eliminated < n_structures do
				local weight = generation_rng:next_within (total_weight)
				local idx = 1
				while idx <= n_structures do
					if indexof (indices_eliminated, idx) == -1 then
						local entry = structures[idx]
						weight = weight - entry.weight

						if weight < 0 then
							break
						end
					end
					idx = idx + 1
				end

				assert (idx <= n_structures, "idx = "
					.. idx .. " eliminated = "
					.. #indices_eliminated
					.. " " .. "total_weight = "
					.. total_weight)
				local entry = structures[idx]
				set_carver_seed (structure_rng, seed, cx, cz)
				local start = entry.structure:create_start (level, terrain,
									    structure_rng,
									    cx, cz)
				if start then
					cb (start, cx, cz, level, data)
					break
				end

				-- Otherwise remove this element from
				-- consideration and try again.
				insert (indices_eliminated, idx)
				total_weight = total_weight - entry.weight
			end
		end
	end
end

-- Prepare structure generation for a MapChunk at X, Z.  TERRAIN
-- should be the terrain generator in use.

local structure_start_x
local structure_start_z
local chunksize

local function struct_hash (cx, cz)
	local x = cx - structure_start_x
	local z = cz - structure_start_z
	assert (x >= 0 and z >= 0)
	return bor (lshift (x, 8), z)
end

local function internal_chunk_hash (dx, dz)
	local x = dx
	local z = dz
	return x * chunksize + z + 1
end

local function insert_structure_start (start, cx, cz, level, data)
	data[#data + 1] = start
end

local function unpack6 (aabb)
	return aabb[1], aabb[2], aabb[3], aabb[4], aabb[5], aabb[6]
end

local function intersect_2d_p (a, x1, z1, x2, z2)
	return a[4] >= x1 and a[1] <= x2
		and a[6] >= z1 and a[3] <= z2
end

local function AABB_intersect_p (a, b)
	local x1a, y1a, z1a, x2a, y2a, z2a = unpack6 (a)
	local x1b, y1b, z1b, x2b, y2b, z2b = unpack6 (b)

	return x1a <= x2b
		and y1a <= y2b
		and z1a <= z2b
		and x2a >= x1b
		and y2a >= y1b
		and z2a >= z1b
end
mcl_levelgen.AABB_intersect_p = AABB_intersect_p

local function AABB_intersect (a, b)
	local x1a, y1a, z1a, x2a, y2a, z2a = unpack6 (a)
	local x1b, y1b, z1b, x2b, y2b, z2b = unpack6 (b)
	return {
		mathmax (x1a, x1b),
		mathmax (y1a, y1b),
		mathmax (z1a, z1b),
		mathmin (x2a, x2b),
		mathmin (y2a, y2b),
		mathmin (z2a, z2b),
	}
end
mcl_levelgen.AABB_intersect = AABB_intersect

local function collect_structure_references (starts, cx, cz)
	local x1, z1 = cx * 16, cz * 16
	local x2, z2 = x1 + 15, z1 + 15
	local refs = {}

	for x = cx - 8, cx + 8 do
		for z = cz - 8, cz + 8 do
			local hash = struct_hash (x, z)
			local local_starts = starts[hash]
			for _, start in ipairs (local_starts) do
				if intersect_2d_p (start.bbox, x1, z1, x2, z2) then
					refs[#refs + 1] = start
				end
			end
		end
	end

	return refs
end

function mcl_levelgen.prepare_structures (level, terrain, x, z)
	local cx, cz = floor (x / 16), floor (z / 16)
	local starts = level.structure_starts
	structure_start_x = cx - 8
	structure_start_z = cz - 8

	-- Build a map of structure starts in each chunk within 8
	-- MapBlocks of the MapChunk at X, Z.
	chunksize = floor (terrain.chunksize / 16)
	for x = cx - 8, cx + chunksize + 7 do
		for z = cz - 8, cz + chunksize + 7 do
			local hash = struct_hash (x, z)
			local local_starts = starts[hash]
			if not local_starts then
				local_starts = {}
				starts[hash] = local_starts
			end
			for i = 1, #local_starts do
				local_starts[i] = nil
			end
			get_structure_starts (level, terrain, x, z,
					      insert_structure_start,
					      local_starts)
		end
	end

	-- And references for each chunk in the MapChunk.
	local refs = level.structure_refs
	for dx = 0, chunksize - 1 do
		for dz = 0, chunksize - 1 do
			local ihash = internal_chunk_hash (dx, dz)
			local cx = cx + dx
			local cz = cz + dz
			refs[ihash] = collect_structure_references (starts, cx, cz)
		end
	end
end

local function execute_structure_start_in_chunk (level, terrain, start, rng,
						 x1, z1, x2, z2)
	for _, piece in ipairs (start.pieces) do
		if intersect_2d_p (piece.bbox, x1, z1, x2, z2) then
			piece:place (level, terrain, rng, x1, z1, x2, z2)
		end
	end
end

local set_population_seed = mcl_levelgen.set_population_seed
local set_decorator_seed = mcl_levelgen.set_decorator_seed
local prepare_structure_placement0
local prepare_structure_placement1
local gen_notifies = {}

local function place_structures_in_chunk (level, terrain, starts, i,
					  structures, cx, cz)
	local x1, z1 = cx * 16, cz * 16
	local x2, z2 = x1 + 15, z1 + 15
	local rng = structure_rng
	local pop = set_population_seed (rng, level.level_seed, x1, z1)

	prepare_structure_placement1 (level, terrain, x1, z1)

	for j, sid in ipairs (structures) do
		set_decorator_seed (rng, pop, j - 1, i - 1)

		for _, start in ipairs (starts) do
			if start.structure == sid then
				execute_structure_start_in_chunk (level, terrain, start,
								  rng, x1, z1, x2, z2)
			end
		end
	end
end

function mcl_levelgen.finish_structures (level, terrain, biomes, x, y, z,
					 index, nodes)
	chunksize = floor (terrain.chunksize / 16)
	local refs = level.structure_refs
	local cx, cz = floor (x / 16), floor (z / 16)

	prepare_structure_placement0 (level, terrain, biomes, index,
				      x, y, z, nodes)

	for i = 1, NUM_GENERATION_STEPS do
		local structures = registered_structures_by_step[i]
		if #structures > 0 then
			for dx = 0, chunksize - 1 do
				for dz = 0, chunksize - 1 do
					local hash = internal_chunk_hash (dx, dz)
					local starts = refs[hash]
					place_structures_in_chunk (level, terrain, starts, i,
								   structures, cx + dx, cz + dz)
				end
			end
		end
	end
end

function mcl_levelgen.structure_biome_test (level, structure_def, x, y, z)
	local biome = level.preset:index_biomes_block (x, y, z)
	return indexof (structure_def.biomes, biome) ~= -1
end

------------------------------------------------------------------------
-- Structure utilities.
------------------------------------------------------------------------

local function bbox_height (bbox)
	return bbox[5] - bbox[2] + 1
end

local function bbox_width_x (bbox)
	return bbox[4] - bbox[1] + 1
end

local function bbox_width_z (bbox)
	return bbox[6] - bbox[3] + 1
end
mcl_levelgen.bbox_height = bbox_height
mcl_levelgen.bbox_width_x = bbox_width_x
mcl_levelgen.bbox_width_z = bbox_width_z

local function AABB_from_pieces (pieces)
	local bbox = {
		huge, huge, huge,
		-huge, -huge, -huge,
	}
	for _, piece in ipairs (pieces) do
		local box_1 = piece.bbox
		bbox[1] = mathmin (bbox[1], box_1[1])
		bbox[2] = mathmin (bbox[2], box_1[2])
		bbox[3] = mathmin (bbox[3], box_1[3])
		bbox[4] = mathmax (bbox[4], box_1[4])
		bbox[5] = mathmax (bbox[5], box_1[5])
		bbox[6] = mathmax (bbox[6], box_1[6])
	end
	return bbox
end
mcl_levelgen.AABB_from_pieces = AABB_from_pieces

function mcl_levelgen.create_structure_start (structure_def, pieces)
	if #pieces == 0 then
		return nil
	end

	local bbox = AABB_from_pieces (pieces)
	return {
		structure = structure_def.name,
		bbox = bbox,
		pieces = pieces,
	}
end

function mcl_levelgen.translate_vertically (pieces, dy)
	for _, piece in ipairs (pieces) do
		local bbox = piece.bbox
		bbox[2] = bbox[2] + dy
		bbox[5] = bbox[5] + dy
	end
end

local translate_vertically = mcl_levelgen.translate_vertically

-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1
-- /net/minecraft/structure/StructurePiecesCollector.html
-- #shiftInto(int,int,net.minecraft.util.math.random.Random,int)

function mcl_levelgen.shift_into (pieces, top_y, bottom_y, rng,
				  top_penalty)
	-- print ("TopY: " .. top_y .. " BottomY: " .. bottom_y)
	local advisory_top_y = top_y - top_penalty
	local bbox = AABB_from_pieces (pieces)
	local max_y = bbox_height (bbox) + bottom_y + 1
	-- print ("MaxY: " .. max_y .. " AdvisoryTopY: " .. advisory_top_y)
	if max_y < advisory_top_y then
		local value = rng:next_within (advisory_top_y - max_y)
		-- print ("Value: " .. value .. " (" .. (advisory_top_y - max_y) .. ")")
		max_y = max_y + value
	end
	local dy = max_y - bbox[5]
	translate_vertically (pieces, dy)
	return dy
end

function mcl_levelgen.bbox_center (bbox)
	local width = bbox[4] - bbox[1] + 1
	local height = bbox[5] - bbox[2] + 1
	local length = bbox[6] - bbox[3] + 1
	local cw = floor (width / 2)
	local ch = floor (height / 2)
	local cl = floor (length / 2)
	return cw + bbox[1], ch + bbox[2], cl + bbox[3]
end

------------------------------------------------------------------------
-- Structure generation environment.
------------------------------------------------------------------------

local biome_seed
local biomes
local heightmap
local heightmap_wg
local index
local level_chunksize
local level_height
local level_max_y
local level_min
local nodes
local nodes_origin_x
local nodes_origin_y
local nodes_origin_z

function prepare_structure_placement0 (level, terrain, p_biomes,
				       p_index, x, y, z, p_nodes)
	biome_seed = terrain.biome_seed
	biomes = p_biomes
	heightmap = terrain.heightmap
	heightmap_wg = terrain.heightmap_wg
	index = p_index
	level_chunksize = terrain.chunksize
	level_height = level.preset.height
	level_min = level.preset.min_y
	level_max_y = level_min + level_height - 1
	nodes = p_nodes
	nodes_origin_x = x
	nodes_origin_y = y
	nodes_origin_z = z
	gen_notifies = {}

	mcl_levelgen.placement_level_min = level_min
	mcl_levelgen.placement_level_height = level_height
end

local origin_x
local origin_z

function prepare_structure_placement1 (level, terrain, x1, z1)
	assert (x1 >= nodes_origin_x
		and x1 < nodes_origin_x + level_chunksize)
	assert (z1 >= nodes_origin_z
		and z1 < nodes_origin_z + level_chunksize)
	origin_x = x1
	origin_z = z1
end

if not mcl_levelgen.load_feature_environment then

local cid_air
local cids_walkable = {}

if core and core.get_content_id then
	local function initialize_cids ()
		for name, def in pairs (core.registered_nodes) do
			if def.walkable then
				local cid = core.get_content_id (name)
				cids_walkable[cid] = true
			end
		end
	end

	if core.register_on_mods_loaded then
		core.register_on_mods_loaded (initialize_cids)
	else
		initialize_cids ()
	end
	cid_air = core.CONTENT_AIR
else
	cid_air = 0
	for i = 2, 2048 do
		cids_walkable[i] = true
	end
end

local decode_node = mcl_levelgen.decode_node
local encode_node = mcl_levelgen.encode_node

local function block_index (x, y, z)
	return index (x - nodes_origin_x, y - level_min,
		      z - nodes_origin_z, level_chunksize,
		      level_height)
end

local function heightmap_index (x, z)
	return ((x - nodes_origin_x) * level_chunksize)
		+ (z - nodes_origin_z) + 1
end

local function get_block_1 (x, y, z)
	local idx = block_index (x, y, z)
	local nodedata = nodes[idx]
	return decode_node (nodedata)
end

function mcl_levelgen.get_block (x, y, z)
	if x < origin_x or x >= origin_x + 16
		or z < origin_z or z >= origin_z + 16
		or y < level_min or y > level_max_y then
		return nil
	end

	return get_block_1 (x, y, z)
end

local function is_not_air (cid, param2)
	return cid ~= cid_air
end

local function is_walkable (cid, param2)
	return cids_walkable[cid]
end

mcl_levelgen.is_walkable = is_walkable

local unpack_height_map = mcl_levelgen.unpack_height_map
local pack_height_map = mcl_levelgen.pack_height_map

local function find_solid_surface (x, y, z, is_solid)
	for y = y, level_min, -1 do
		if is_solid (get_block_1 (x, y, z)) then
			return y + 1
		end
	end

	return level_min
end

local function correct_heightmaps (x, y, z, cid, param2)
	-- Correct heightmaps to agree with the new state of the
	-- level.
	local idx = heightmap_index (x, z)
	local value = heightmap[idx]
	local surface, motion_blocking = unpack_height_map (value)
	surface = surface + level_min
	motion_blocking = motion_blocking + level_min

	-- if x == 561 and z == 8043 then
	-- 	print ("IN", surface - level_min, motion_blocking - level_min)
	-- end

	if not is_not_air (cid, param2) then
		if (surface - 1) == y then
			-- Search downwards.
			surface = find_solid_surface (x, y, z, is_not_air)
		end
	elseif surface < y + 1 then
		surface = y + 1
	end

	if not is_walkable (cid, param2) then
		if (motion_blocking - 1) == y then
			-- Search downwards.
			motion_blocking = find_solid_surface (x, y, z, is_walkable)
		end
	elseif motion_blocking < y + 1 then
		motion_blocking = y + 1
	end

	-- if x == 561 and z == 8043 then
	-- 	print ("OUT", surface - level_min, motion_blocking - level_min)
	-- end
	heightmap[idx] = pack_height_map (surface - level_min,
					  motion_blocking - level_min)
end

function mcl_levelgen.set_block (x, y, z, cid, param2)
	if x < origin_x or x >= origin_x + 16
		or z < origin_z or z >= origin_z + 16
		or y < level_min or y > level_max_y then
		return nil
	end

	local node = encode_node (cid, param2)
	local idx = block_index (x, y, z)
	nodes[idx] = node
	correct_heightmaps (x, y, z, cid, param2)
end

function mcl_levelgen.set_block_checked (x, y, z, cid, param2, writable_p)
	if x < origin_x or x >= origin_x + 16
		or z < origin_z or z >= origin_z + 16
		or y < level_min or y > level_max_y then
		return nil
	end

	local node = encode_node (cid, param2)
	local idx = block_index (x, y, z)
	do
		local cid, param2 = decode_node (nodes[idx])
		if writable_p (cid, param2) then
			nodes[idx] = node
		end
	end
	correct_heightmaps (x, y, z, cid, param2)
end

function mcl_levelgen.reorientate_coords (piece, x, y, z)
	local dir, bbox = piece.dir, piece.bbox
	if dir == "north" then
		return bbox[1] + x, bbox[2] + y, bbox[6] - z
	elseif dir == "south" then
		return bbox[1] + x, bbox[2] + y, bbox[3] + z
	elseif dir == "west" then
		return bbox[4] - z, bbox[2] + y, bbox[3] + x
	elseif dir == "east" then
		return bbox[1] + z, bbox[2] + y, bbox[3] + x
	else
		assert (false)
	end
end

local munge_biome_coords = mcl_levelgen.munge_biome_coords
local bindex = mcl_levelgen.biome_table_index
local toquart = mcl_levelgen.toquart

local function munge_biome_index (x, y, z, level_min, bx, bz)
	local qx, qy, qz = munge_biome_coords (biome_seed, x, y, z)
	qy = qy - toquart (level_min)
	return qx - toquart (bx), qy, qz - toquart (bz)
end

function mcl_levelgen.index_biome (x, y, z)
	if x < origin_x or x >= origin_x + 16
		or z < origin_z or z >= origin_z + 16
		or y < level_min or y > level_max_y then
		error ("Heightmap index out of bounds")
	end
	local ix, iy, iz = munge_biome_index (x, y, z, level_min,
					      nodes_origin_x,
					      nodes_origin_z)
	local cs = toquart (level_chunksize)
	local idx = bindex (ix, iy, iz, cs, toquart (level_height), cs)
	return biomes[idx]
end

function mcl_levelgen.index_heightmap (x, z, wg)
	if x < origin_x or x >= origin_x + 16
		or z < origin_z or z >= origin_z + 16 then
		return level_min, level_min
	end

	local heightmap = wg and heightmap_wg or heightmap
	local idx = heightmap_index (x, z)
	local surface, motion_blocking
		= decode_node (heightmap[idx])
	return surface + level_min, motion_blocking + level_min
end

function mcl_levelgen.notify_generated (name, x, y, z, data, append)
	assert (type (name) == "string")
	if y >= nodes_origin_y and y < nodes_origin_y + level_height then
		if append then
			local last_generated = gen_notifies[#gen_notifies]
			if last_generated and last_generated.name == name then
				assert (last_generated.append)
				insert (last_generated.data, data)
				return
			end
			data = { data, }
		end

		insert (gen_notifies, {
			name = name,
			data = data,
			append = append,
		})
	end
end

function mcl_levelgen.flush_structure_generation_notifications ()
	local n = gen_notifies
	gen_notifies = {}
	return n
end

end
