local ipairs = ipairs
local mathmax = math.max
local mathmin = math.min
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local lshift = bit.lshift
local rshift = bit.rshift
local arshift = bit.arshift

--------------------------------------------------------------------------
-- Level feature placement.
--------------------------------------------------------------------------

local NUM_GENERATION_STEPS = 11

--------------------------------------------------------------------------
-- Biome feature assignment and dependency resolution.
--------------------------------------------------------------------------

-- Features are registered individually in biomes, but as the sequence
-- in which they are defined is significant, there are several
-- invariants required of feature registrations, to wit: no feature
-- may be defined in such a position that it succeeds a feature in one
-- biome but precedes the latter, or any of its dependents, in
-- another.  A directed dependency tree is built and searched for
-- cycles, a tree of dependents is inserted in reverse order,
-- maintaining the relative position of each feature in its feature
-- list.

local registered_features = {}
mcl_levelgen.registered_features = {}

local function indexof (list, val)
	for i, v in ipairs (list) do
		if v == val then
			return i
		end
	end
	return -1
end

local function feature_w_step (step, feature)
	return string.format ("%d:%s", step, feature)
end

-- Attribution: Minetest

local string_find = string.find
local string_sub = string.sub

local function split (str, delim, include_empty, max_splits, sep_is_pattern)
	delim = delim or ","
	if delim == "" then
		error ("string.split separator is empty", 2)
	end
	max_splits = max_splits or -2
	local items = {}
	local pos, len = 1, #str
	local plain = not sep_is_pattern
	max_splits = max_splits + 1
	repeat
		local np, npe = string_find (str, delim, pos, plain)
		np, npe = (np or (len+1)), (npe or (len+1))
		if (not np) or (max_splits == 1) then
			np = len + 1
			npe = np
		end
		local s = string_sub (str, pos, np - 1)
		if include_empty or (s ~= "") then
			max_splits = max_splits - 1
			items[#items + 1] = s
		end
		pos = npe + 1
	until (max_splits == 0) or (pos > (len + 1))
	return items
end

local insert = table.insert

local function dfs (start, graph, g_next, visited, depth)
	local visited = visited or { [start] = true, }

	-- print (string.rep (' ', depth or 0) .. start)
	for _, item in ipairs (g_next[start]) do
		if visited[item] then
			print ("Cycle detected in feature dependency list: ")
			print (string.format ("  %-40s -> %s", start, item))
			return false
		end
		visited[item] = true
		if not dfs (item, graph, g_next, visited, (depth or 0) + 1) then
			print (string.format ("  %-40s -> %s", start, item))
			return false
		end
		visited[item] = false
	end
	return true
end

if false then

local function bfs (start, consider_item, g_next)
	consider_item (start)
	local pdl = { start, }

	while #pdl > 0 do
		start, pdl[#pdl] = pdl[#pdl], nil
		local elems = g_next[start]
		for i = #elems, 1, -1 do
			local item = elems[i]
			consider_item (item)
			insert (pdl, item)
		end
	end
end

end

local function dfs1 (start, consider_item, g_next)
	local elems = g_next[start]
	for _, item in ipairs (elems) do
		dfs1 (item, consider_item, g_next)
	end
	consider_item (start)
end

local function merge_feature_precedences (preset)
	local feature_deps = {}
	local all_features = {}
	local ordered = {}
	local features_by_step = {}
	local indices = {}
	local feature_dependents = {}

	-- Build the feature dependence graph.
	for _, name in ipairs (preset:generated_biomes ()) do
		local biome = mcl_levelgen.registered_biomes[name]
		for step, features in ipairs (biome.features) do
			local prev_feature = nil
			for i, feature_id in ipairs (features) do
				local feature = feature_w_step (step, feature_id)
				if not feature_deps[feature] then
					feature_deps[feature] = {}
				end
				if prev_feature and indexof (feature_deps[feature],
							     prev_feature) == -1 then
					insert (feature_deps[feature], prev_feature)
				end
				prev_feature = feature
				if indexof (all_features, feature) == -1 then
					indices[feature] = #all_features + 1
					insert (all_features, feature)
				end

				local next_feature = features[i + 1]

				if next_feature then
					next_feature
						= feature_w_step (step, next_feature)
				end

				local dependents = feature_dependents[feature]
				if not dependents then
					dependents = {}
					feature_dependents[feature] = dependents
				end

				if next_feature
					and indexof (dependents, next_feature) == -1 then
					insert (dependents, next_feature)
				end
			end
		end
	end

	table.sort (all_features, function (a, b)
		local step_a, _
			= unpack (split (a, ':', true, 1))
		local step_b, _
			= unpack (split (b, ':', true, 1))
		step_a = tonumber (step_a)
		step_b = tonumber (step_b)
		if step_a < step_b then
			return true
		elseif step_a > step_b then
			return false
		else
			return indices[a] < indices[b]
		end
	end)

	-- Resolve cycles in this directed graph and insert its
	-- elements in reverse order of iteration.
	local seen = {}
	for _, feature in ipairs (all_features) do
		local items = {}

		-- First, detect cycles.
		local success = dfs (feature, feature_deps[feature], feature_deps, nil)

		if not success then
			print (string.format ("  %-40s -> %s", "[level generator]", feature))
			error ("Could not enumerate features in order of precedence")
		end

		-- Insert a tree of dependents depth-first.
		dfs1 (feature, function (item)
			if not seen[item] then
				insert (ordered, item)
				seen[item] = true
			end
		end,  feature_dependents)
	end

	-- Build the sequence list.
	for i = 1, NUM_GENERATION_STEPS do
		features_by_step[i] = {}
	end
	local seen = {}
	for i = #ordered, 1, -1 do
		if not seen[ordered[i]] then
			local step, feature_id
				= unpack (split (ordered[i], ':', true, 1))
			local list = features_by_step[tonumber (step)]
			insert (list, feature_id)
			seen[ordered[i]] = true
		end
	end
	return features_by_step
end

mcl_levelgen.merge_feature_precedences = merge_feature_precedences

------------------------------------------------------------------------
-- Feature registration.
------------------------------------------------------------------------

local registered_features = {}
mcl_levelgen.registered_features = registered_features

local registered_configured_features = {}
mcl_levelgen.registered_configured_features = registered_configured_features

local registered_placed_features = {}
mcl_levelgen.registered_placed_features = registered_placed_features

function mcl_levelgen.register_feature (id, feature)
	local existing = registered_features[id]
	if existing then
		error ("Feature " .. id .. " is already defined")
	end
	assert (feature.place)
	registered_features[id] = feature
end

function mcl_levelgen.register_configured_feature (id, configured_feature)
	local feature = registered_configured_features[id]
	if feature then
		error ("Configured feature " .. id .. " is already defined")
	end
	assert (configured_feature.feature)
	if not registered_features[configured_feature.feature] then
		error ("Configured feature " .. id .. " refers to a feature "
		       .. placed_feature.configured_feature
		       .. " that does not exist")
	end
	registered_configured_features[id] = configured_feature
end

function mcl_levelgen.register_placed_feature (id, placed_feature)
	local existing = registered_placed_features[id]
	if existing then
		error ("Placed feature " .. id .. " is already defined")
	end
	assert (placed_feature.configured_feature)
	if not registered_configured_features[placed_feature.configured_feature] then
		error ("Placed feature " .. id .. " refers to a configured feature "
		       .. placed_feature.configured_feature .. " that does not exist")
	end
	registered_placed_features[id] = placed_feature
end

local features_generated = {}

function mcl_levelgen.generate_feature (id, before, biomes, stage)
	if not registered_placed_features[id] then
		error ("Placed feature " .. id .. " is not defined")
	end
	if features_generated[stage .. ":" .. id] then
		error ("Feature has already been registered for generation: " .. id)
	end
	features_generated[stage .. ":" .. id] = true

	for _, biome in ipairs (biomes) do
		if not biome.features[stage] then
			biome.features[stage] = { id, }
			return
		end

		local biome = mcl_levelgen.registered_biomes[biome]
		local index = table.indexof (biome.features[stage], before)
		if index == -1 then
			table.insert (biome.features[stage], id)
		else
			table.insert (biome.features[stage], index, id)
		end
	end
end

local overworld_features = mcl_levelgen.overworld_features
local overworld_feature_indices = {}

function mcl_levelgen.initialize_biome_features ()
	local overworld = mcl_levelgen.overworld_preset
	overworld_features = merge_feature_precedences (overworld)

	-- Construct a table mapping each registered biome's feature
	-- list to the index of the same feature in the feature
	-- precedence list.

	for step, features in ipairs (overworld_features) do
		local tbl = {}
		overworld_feature_indices[step] = tbl
		for i, feature in ipairs (features) do
			tbl[feature] = i
		end
	end
end

if core and mcl_levelgen.load_feature_environment then

------------------------------------------------------------------------
-- Feature generation environment.
------------------------------------------------------------------------

local cid_air = core.CONTENT_AIR
local cids_walkable = {}

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

local run_minp, run_maxp = vector.new (), vector.new ()
local vm, run, heightmap, biomes, y_offset, level_min, level_height
local run_min_y, run_max_y, run_min_x, run_max_x, run_min_z, run_max_z

local HEIGHTMAP_SIZE = mcl_levelgen.HEIGHTMAP_SIZE
local HEIGHTMAP_SIZE_NODES = mcl_levelgen.HEIGHTMAP_SIZE_NODES
local unpack_augmented_height_map = mcl_levelgen.unpack_augmented_height_map
local pack_height_map = mcl_levelgen.pack_height_map
local SURFACE_UNCERTAIN = mcl_levelgen.SURFACE_UNCERTAIN
local MOTION_BLOCKING_UNCERTAIN = mcl_levelgen.MOTION_BLOCKING_UNCERTAIN
local REQUIRED_CONTEXT_Y = mcl_levelgen.REQUIRED_CONTEXT_Y
local REQUIRED_CONTEXT_XZ = mcl_levelgen.REQUIRED_CONTEXT_XZ
local cids, param2s = {}, {}
local area = nil
local vm_modified = false

mcl_levelgen.placement_run_minp = run_minp
mcl_levelgen.placement_run_maxp = run_maxp
mcl_levelgen.placement_level_min = 0
mcl_levelgen.placement_level_height = 0

function mcl_levelgen.process_features (p_vm, p_run, p_heightmap, p_biomes, p_y_offset,
					p_level_min, p_level_height)
	run = p_run
	run_minp.x = run.x * 16
	run_minp.z = -(run.z * 16 + 16)
	run_minp.y = run.y1 * 16 + p_y_offset
	run_maxp.x = run_minp.x + 15
	run_maxp.z = run_minp.z + 15
	run_maxp.y = run.y2 * 16 + p_y_offset + 15
	vm = p_vm
	heightmap = p_heightmap
	biomes = p_biomes
	y_offset = p_y_offset
	level_min = p_level_min
	mcl_levelgen.placement_level_min = p_level_min
	level_height = p_level_height
	mcl_levelgen.placement_level_height = p_level_height

	run_min_y = mathmax ((run.y1 - REQUIRED_CONTEXT_Y) * 16,
			     p_level_min)
	run_max_y = mathmin ((run.y2 + REQUIRED_CONTEXT_Y) * 16 + 15,
			     p_level_min + p_level_height - 1)
	run_min_x = (run.x - REQUIRED_CONTEXT_XZ) * 16
	run_max_x = (run.x + REQUIRED_CONTEXT_XZ) * 16 + 15
	run_min_z = run_minp.z - REQUIRED_CONTEXT_XZ * 16
	run_max_z = run_min_z + HEIGHTMAP_SIZE_NODES - 1
	vm:get_data (cids)
	vm:get_param2_data (param2s)
	area = VoxelArea (vm:get_emerged_area ())
	vm_modified = false
	mcl_levelgen.process_features_1 ()

	if vm_modified then
		vm:set_data (cids)
		vm:set_param2_data (param2s)
	end
end

local function is_not_air (cid, param2)
	return cid ~= cid_air
end

local function is_walkable (cid, param2)
	return cids_walkable[cid]
end

local function index (x, y, z)
	local x = x
	local y = y - y_offset
	local dz = z - run_min_z
	local run_origin = (run.z - REQUIRED_CONTEXT_XZ) * 16
	local z = run_origin + (HEIGHTMAP_SIZE_NODES - dz - 1)
	return area:index (x, y, z)
end

local function get_block_1 (x, y, z)
	local idx = index (x, y, z)
	return cids[idx], param2s[idx]
end

local function complete_partial_heightmap (x, z, current_min, idx,
					   blocks_motion, flag)
	-- This run does not possess enough context to finalize this
	-- height map.
	if current_min <= run_min_y then
		return current_min
	end

	local value = heightmap[idx]
	local flags = rshift (value, 30)

	for y = current_min, run_min_y do
		local cid, param2 = get_block_1 (x, y, z)
		if blocks_motion (cid, param2) then
			local mask = 0x3ff
			local bias = -512
			local k = y + 1 - level_min
			local bits = (flag == SURFACE_UNCERTAIN
				      and 10 or 0)
			mask = bnot (lshift (mask, bits))
			value = bor (band (mask, value,
					   bnot (lshift (flag, 30))),
				     lshift (k + bias, bits))
			heightmap[idx] = value

			print ("Corrected partial heightmap", x, z, "=", y)
			return y + 1
		end
	end

	-- The true height of the level is still below the context
	-- available to this placement run.
	local mask = 0x3ff
	local bias = -512
	local k = run_min_y - level_min
	mask = bnot (lshift (mask, bits))
	value = bor (band (mask, value), lshift (k + bias, bits))
	heightmap[idx] = value
	return run_min_y
end

local function heightmap_index (x, z)
	local dx = x - run_min_x
	local dz = z - run_min_z
	return (dx * HEIGHTMAP_SIZE_NODES) + dz + 1
end

function mcl_levelgen.index_heightmap (x, z)
	local run_x = run_min_x
	local run_z = run_min_z
	if z - run_z >= HEIGHTMAP_SIZE_NODES
		or x - run_x >= HEIGHTMAP_SIZE_NODES
		or z - run_z <= 0 or x - run_x <= 0 then
		error ("Heightmap index out of bounds")
	end
	local idx = heightmap_index (x, z)
	local surface, motion_blocking, flags
		= unpack_augmented_height_map (heightmap[idx])
	surface = surface + level_min
	motion_blocking = motion_blocking + level_min
	if band (flags, SURFACE_UNCERTAIN) ~= 0 then
		surface = complete_partial_heightmap (x, z, surface, idx, is_not_air,
						      SURFACE_UNCERTAIN)
	end
	if band (flags, MOTION_BLOCKING_UNCERTAIN) ~= 0 then
		motion_blocking
			= complete_partial_heightmap (x, z, motion_blocking, idx,
						      is_walkable,
						      MOTION_BLOCKING_UNCERTAIN)
	end
	return surface, motion_blocking
end

local biome_seed = mcl_levelgen.biome_seed
local munge_biome_coords = mcl_levelgen.munge_biome_coords
local toquart = mcl_levelgen.toquart
local hashmapblock = mcl_levelgen.hashmapblock
local index_biome_list = mcl_levelgen.index_biome_list

local HORIZONTAL_QUARTS_PER_RUN = toquart (HEIGHTMAP_SIZE_NODES)

function mcl_levelgen.index_biome (x, y, z)
	local run_x = run_min_x
	local run_z = run_min_z
	if z - run_z >= HEIGHTMAP_SIZE_NODES
		or x - run_x >= HEIGHTMAP_SIZE_NODES
		or z - run_z <= 0 or x - run_x <= 0 then
		error ("Heightmap index out of bounds")
	end

	local qx, qy, qz = munge_biome_coords (biome_seed, x, y, z)

	-- Convert thiws QuartPos into the Minetest coordinate system.
	local dz = qz - toquart (run_min_z)
	local run_origin = (run.z - REQUIRED_CONTEXT_XZ) * 16
	qz = toquart (run_origin) + HORIZONTAL_QUARTS_PER_RUN - dz - 1
	qy = qy - toquart (y_offset)

	local bx, by, bz = arshift (qx, 2), arshift (qy, 2), arshift (qz, 2)
	local hash = hashmapblock (bx, by, bz)
	local list = biomes[hash]
	return index_biome_list (list, band (qx, 3), band (qy, 3),
				 band (qz, 3))
end

function mcl_levelgen.get_block (x, y, z)
	local run_x = run_min_x
	local run_z = run_min_z
	if z - run_z >= HEIGHTMAP_SIZE_NODES
		or x - run_x >= HEIGHTMAP_SIZE_NODES
		or z - run_z <= 0 or x - run_x <= 0 then
		return nil, nil
	end
	return get_block_1 (x, y, z)
end

function mcl_levelgen.set_block (x, y, z, cid, param2)
	local run_x = run_min_x
	local run_z = run_min_z
	if z - run_z >= HEIGHTMAP_SIZE_NODES
		or x - run_x >= HEIGHTMAP_SIZE_NODES
		or z - run_z <= 0 or x - run_x <= 0 then
		core.log ("warning", "A feature placement function is writing "
			  .. " outside the placement run")
		core.log ("warning", debug.traceback ())
		return
	end
	local idx = index (x, y, z)
	cids[idx] = cid
	param2s[idx] = param2
	vm_modified = true

	-- Correct heightmaps to agree with the new state of the
	-- level.
	local idx = heightmap_index (x, z)
	local value = heightmap[idx]
	local surface, motion_blocking = unpack_augmented_height_map (value)

	surface = surface + level_min
	motion_blocking = motion_blocking + level_min

	local flags = rshift (value, 30)

	if not is_not_air (cid, param2) then
		if (surface - 1) == y then
			-- Search downwards.
			surface
				= find_solid_surface (x, y, z, is_not_air)
			if surface == run_min_y then
				flags = bor (flags, SURFACE_UNCERTAIN)
			end
		end
	elseif surface < y + 1 then
		surface = y + 1
		flags = band (flags, bnot (SURFACE_UNCERTAIN))
	end

	if not is_walkable (cid, param2) then
		if (motion_blocking - 1) == y then
			-- Search downwards.
			motion_blocking
				= find_solid_surface (x, y, z, is_walkable)
			if motion_blocking == run_min_y then
				flags = bor (flags, MOTION_BLOCKING_UNCERTAIN)
			end
		end
	elseif motion_blocking < y + 1 then
		motion_blocking = y + 1
		flags = band (flags, bnot (MOTION_BLOCKING_UNCERTAIN))
	end

	heightmap[value] = bor (lshift (flags, 30),
				pack_height_map (surface - level_min,
						 motion_blocking - level_min))
end

function mcl_levelgen.fix_lighting (x1, y1, z1, x2, y2, z2)
	-- TODO
end

------------------------------------------------------------------------
-- Feature generation.
------------------------------------------------------------------------

local ull = mcl_levelgen.ull
local rng = mcl_levelgen.xoroshiro (ull (0, 0), ull (0, 0))
local expand_biome_list = mcl_levelgen.expand_biome_list

local function place_one_feature (feature) -- A placed feature.
	local id = feature.configured_feature
	local cfg = registered_configured_features[id]
	local positions = {
		run_minp.x, level_min, run_minp.z,
	}
	local positions_next = {}

	for _, modifier in ipairs (feature.placement_modifiers) do
		for i = 1, #positions, 3 do
			local x = positions[i]
			local y = positions[i + 1]
			local z = positions[i + 2]
			local values = modifier (x, y, z, rng)
			assert (#values % 3 == 0)
			for _, value in ipairs (values) do
				insert (positions_next, value)
			end
		end

		positions = positions_next
		positions_next = {}
	end

	local plain_feature = registered_features[cfg.feature]
	local placed = false
	for i = 1, #positions, 3 do
		placed = plain_feature:place (positions[i],
					      positions[i + 1],
					      positions[i + 2],
					      cfg, rng)
			or placed
	end
	return placed
end

local registered_biomes = mcl_levelgen.registered_biomes
local sort = table.sort
local warned = {}

function mcl_levelgen.process_features_1 ()
	local seed = mcl_levelgen.seed
	local pop = mcl_levelgen.set_population_seed (rng, seed,
						      run_minp.x,
						      run_minp.z)

	-- Enumerate the biomes in this region.
	local gen_biomes, seen = {}, {}
	for _, index in pairs (biomes) do
		expand_biome_list (index, gen_biomes, seen)
	end

	for step = 1, NUM_GENERATION_STEPS do
		-- Collect the indices of the features that generate
		-- in each biome intersecting the run.

		local indices = overworld_feature_indices[step]
		local features, seen = {}, {}
		for _, biome in ipairs (gen_biomes) do
			local def = registered_biomes[biome]
			local biomefeatures = def.features[step]

			if biomefeatures then
				for _, feature in ipairs (biomefeatures) do
					if not seen[feature] then
						seen[feature] = true
						assert (indices[feature])
						insert (features, indices[feature])
					end
				end
			end
		end
		sort (features)

		local step_features = overworld_features[step]
		for _, idx in ipairs (features) do
			local name = step_features[idx]
			local feature = registered_placed_features[name]

			if feature then
				mcl_levelgen.set_decorator_seed (rng, pop, idx - 1, step - 1)
				place_one_feature (feature)
			elseif not warned[name] then
				core.log ("warning", "Placing undefined feature: " .. name)
				warned[name] = true
			end
		end
	end
end

end
