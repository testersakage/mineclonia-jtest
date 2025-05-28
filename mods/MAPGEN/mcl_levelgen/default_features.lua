local mcl_levelgen = mcl_levelgen
local ipairs = ipairs
local pairs = pairs

------------------------------------------------------------------------
-- Fundamental features.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Random selector.
-- mcl_levelgen:random_selector
------------------------------------------------------------------------

local registered_placed_features = mcl_levelgen.registered_placed_features
local place_one_feature = mcl_levelgen.place_one_feature
local warned = {}

local function random_selector_place (_, x, y, z, cfg, rng)
	for _, feature in ipairs (cfg.features) do
		local id = feature.feature

		if rng:next_float () < feature.chance then
			local feature_desc = type (id) == "table"
				and id
				or registered_placed_features[id]
			if not feature_desc and not warned[id] then
				core.log ("warning", table.concat ({
					"Random selector attempted to place a ",
					"nonexistent placed feature, ", id,
				}))
				warned[id] = true
			elseif feature_desc then
				place_one_feature (feature_desc, x, y, z)
				return
			end
		end
	end

	local default_desc = type (cfg.default) == "table"
		and cfg.default
		or registered_placed_features[cfg.default]
	if not default_desc then
		if not warned[cfg.default] then
			core.log ("warning", table.concat ({
				"Random selector attempted to place a ",
				"nonexistent default placed feature, ", cfg.default,
			}))
			warned[cfg.default] = true
		end
		return
	end
	place_one_feature (default_desc, x, y, z)
end

mcl_levelgen.register_feature ("mcl_levelgen:random_selector", {
	place = random_selector_place,
})

------------------------------------------------------------------------
-- Simple random selector.
-- mcl_levelgen:simple_random_selector
------------------------------------------------------------------------

local registered_placed_features = mcl_levelgen.registered_placed_features
local place_one_feature = mcl_levelgen.place_one_feature
local warned = {}

local function simple_random_selector_place (_, x, y, z, cfg, rng)
	local values = #cfg.features
	assert (values > 0)
	local idx = 1 + rng:next_within (values)
	local id = cfg.features[idx]
	local feature_desc = type (id) == "table"
		and id
		or registered_placed_features[id]
	if not feature_desc and not warned[id] then
		core.log ("warning", table.concat ({
			"Random selector attempted to place a ",
			"nonexistent placed feature, ", id,
		}))
		warned[id] = true
	elseif feature_desc then
		place_one_feature (feature_desc, x, y, z)
		return
	end
end

mcl_levelgen.register_feature ("mcl_levelgen:simple_random_selector", {
	place = simple_random_selector_place,
})

------------------------------------------------------------------------
-- Freeze Top Layer
-- mcl_levelgen:freeze_top_layer
------------------------------------------------------------------------

local index_biome = mcl_levelgen.index_biome
local index_heightmap = mcl_levelgen.index_heightmap
local get_block = mcl_levelgen.get_block
local set_block = mcl_levelgen.set_block
local cid_air = core.CONTENT_AIR
local cid_snow = core.get_content_id ("mcl_core:snow")
local cid_water_source = core.get_content_id ("mcl_core:water_source")
local cid_ice = core.get_content_id ("mcl_core:ice")
-- local cid_dirt = core.get_content_id ("mcl_core:dirt")
local cid_grass = core.get_content_id ("mcl_core:dirt_with_grass")
local cid_grass_snowy = core.get_content_id ("mcl_core:dirt_with_grass_snow")
local cid_mycelium = core.get_content_id ("mcl_core:mycelium")
local cid_mycelium_snow = core.get_content_id ("mcl_core:mycelium_snow")
local cid_podzol = core.get_content_id ("mcl_core:podzol")
local cid_podzol_snow = core.get_content_id ("mcl_core:podzol_snow")

local snowy_blocks = {
	[cid_grass] = cid_grass_snowy,
	[cid_mycelium] = cid_mycelium_snow,
	[cid_podzol] = cid_podzol_snow,
}

local exposed_blocks = {
	[cid_grass_snowy] = cid_grass,
	[cid_mycelium_snow] = cid_mycelium,
	[cid_podzol_snow] = cid_podzol,
}

local unpack_heightmap_modification
	= mcl_levelgen.unpack_heightmap_modification

local function freeze_layer_common (x1, z1, surface)
	local biome = index_biome (x1, surface, z1)
	local frigid
		= mcl_levelgen.is_temp_snowy (biome, x1, surface, z1)

	if frigid then
		-- Freeze the node below if it is
		-- water and not brighter than 10.
		-- TODO: test light levels.
		local cid, _ = get_block (x1, surface - 1, z1)
		if cid == cid_water_source then
			set_block (x1, surface - 1, z1, cid_ice, 255)
			-- Place one snow layer if the
			-- temperature is sufficiently frigid.
		elseif mcl_levelgen.can_place_snow (x1, surface, z1) then
			set_block (x1, surface, z1, cid_snow, 0)
			local replacement = snowy_blocks[cid]
			if replacement then
				set_block (x1, surface - 1, z1,
					   replacement, -1)
			end
		end
	end
end

local function place_freeze_top_layer (_, x, y, z, cfg, rng)
	local start_y = mcl_levelgen.placement_run_minp.y
	local end_y = mcl_levelgen.placement_run_maxp.y
	local heightmap_modifications = mcl_levelgen.heightmap_modifications

	for key, value in pairs (heightmap_modifications) do
		local x, z, surface, _
			= unpack_heightmap_modification (key, value)
		local surface = surface - 1

		if surface >= start_y - 32 and surface <= end_y + 32 then
			-- If the surface has moved, remove any snow layers or
			-- ice that may have been placed at the previous location
			local old_cid, _ = get_block (x, surface, z)
			if old_cid == cid_snow then
				set_block (x, surface, z, cid_air, 0)
			end

			if surface > start_y - 32 then
				local old_cid, param2 = get_block (x, surface - 1, z)
				-- A param2 of 255 indicates that this
				-- ice was placed by freeze_top_layer.
				if old_cid == cid_ice and param2 == 255 then
					set_block (x, surface - 1, z, cid_water_source, 0)
				else
					local replacement = exposed_blocks[old_cid]
					if replacement then
						set_block (x, surface - 1, z, replacement,
							   param2)
					end
				end
			end
		end

		local surface_new, _ = index_heightmap (x, z)
		if surface_new >= start_y - 31 and surface <= end_y + 32 then
			freeze_layer_common (x, z, surface_new)
		end
	end

	for dx = 0, 15 do
		for dz = 0, 15 do
			local x1, z1 = x + dx, z + dz
			local surface, _ = index_heightmap (x1, z1)
			if surface >= start_y and surface <= end_y then
				freeze_layer_common (x1, z1, surface)
			end
		end
	end
end

mcl_levelgen.register_feature ("mcl_levelgen:freeze_top_layer", {
	place = place_freeze_top_layer,
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:freeze_top_layer", {
	feature = "mcl_levelgen:freeze_top_layer",
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:freeze_top_layer", {
	configured_feature = "mcl_levelgen:freeze_top_layer",
	placement_modifiers = {},
})

------------------------------------------------------------------------
-- Ore placement.
-- mcl_levelgen:ore
------------------------------------------------------------------------

local mathsin = math.sin
local mathcos = math.cos
local mathmin = math.min
local mathmax = math.max
local floor = math.floor
local ceil = math.ceil

-- local ore_configuration = {
-- 	substitutions = {},
-- 	size = "",
-- 	discard_chance_on_air_exposure = 0.0,
-- }

local run_minp = mcl_levelgen.placement_run_minp
local run_maxp = mcl_levelgen.placement_run_maxp
local pi = math.pi
local BLOCKS_PER_BLOB = 8.0

local lerp1d = mcl_levelgen.lerp1d
local adjoins_air = mcl_levelgen.adjoins_air

local function ore_placement_test (cid, x, y, z, rng, cfg)
	for _, substitution in ipairs (cfg.substitutions) do
		if substitution[1] == cid then
			local chance = cfg.discard_chance_on_air_exposure
			if (chance >= 1.0 or (chance <= 0.0
					      and rng:next_float () < chance))
				and adjoins_air (x, y, z) then
				return nil, nil
			end

			return substitution[2], substitution[3]
		end
	end

	return nil, nil
end

local function ore_place_1 (x1, x2, z1, z2, y1, y2,
			    xmin, ymin, zmin, hsize,
			    ysize, cfg, rng)
	local placed = false
	local cnt_ores = cfg.size

	-- Array of tuples of four elements supplying the position of
	-- each blob and its radius
	local ore_poses = {}

	local r = 1 / (cnt_ores * 4)
	for i = 1, cnt_ores * 4, 4 do
		local progress = i * r
		local x = lerp1d (progress, x1, x2)
		local y = lerp1d (progress, y1, y2)
		local z = lerp1d (progress, z1, z2)
		local blob_radius = rng:next_double ()
			* cnt_ores / 16.0
		local blob_radius_1
			= ((mathsin (pi * progress) + 1.0)
				* blob_radius + 1.0) / 2.0

		ore_poses[i] = x
		ore_poses[i + 1] = y
		ore_poses[i + 2] = z
		ore_poses[i + 3] = blob_radius_1
	end

	-- Delete blobs that intersect too egregiously.
	for i = 0, cnt_ores - 2 do
		local idx = i * 4 + 1

		if ore_poses[idx + 3] >= 0.0 then
			for i = 0, cnt_ores - 1 do
				local idx1 = i * 4 + 1
				local dx = ore_poses[idx] - ore_poses[idx1]
				local dy = ore_poses[idx + 1] - ore_poses[idx1 + 1]
				local dz = ore_poses[idx + 2] - ore_poses[idx1 + 2]
				local dradius
					= ore_poses[idx + 3] - ore_poses[idx1 + 3]
				local d = dx * dx + dy * dy + dz * dz
				if dradius * dradius > d then
					if dradius > 0.0 then
						ore_poses[idx1 + 3] = -1.0
					else
						ore_poses[idx + 3] = -1.0
					end
				end
			end
		end
	end

	-- Place each blob.
	for i = 1, cnt_ores * 4, 4 do
		local r = ore_poses[i + 3]
		if r >= 0.0 then
			local cx = ore_poses[i]
			local cy = ore_poses[i + 1]
			local cz = ore_poses[i + 2]
			local bxmin = mathmax (floor (cx - r), xmin)
			local bymin = mathmax (floor (cy - r), ymin)
			local bzmin = mathmax (floor (cz - r), zmin)
			local sr = 1 / r
			local bxmax = mathmin (mathmax (floor (cx + r), bxmin),
					       xmin + hsize - 1)
			local bzmax = mathmin (mathmax (floor (cz + r), bzmin),
					       zmin + hsize - 1)
			local bymax = mathmin (mathmax (floor (cy + r), bymin),
					       ymin + ysize - 1)

			for x = bxmin, bxmax do
				for y = bymin, bymax do
					for z = bzmin, bzmax do
						local dx = (x + 0.5 - cx) * sr
						local dy = (y + 0.5 - cy) * sr
						local dz = (z + 0.5 - cz) * sr

						if dx * dx + dy * dy + dz * dz < 1.0 then
							local cid, _ = get_block (x, y, z)
							if cid then
								local param2
								cid, param2 = ore_placement_test (cid, x, y, z,
												  rng, cfg)
								if cid then
									-- if mcl_levelgen.current_placed_feature
									-- 	== "mcl_levelgen:ore_emerald" then
									-- 	print (x, y, z)
									-- end
									set_block (x, y, z, cid, param2)
									placed = true
								end
							end
						end
					end
				end
			end
		end
	end
	return placed
end

local function ore_place (_, x, y, z, cfg, rng)
	if y < run_minp.y or y > run_maxp.y then
		return false
	end

	-- Derive the bounds of the ellipsoid in which ores will be
	-- placed in individual blobs.

	local dir = rng:next_float () * pi
	local size_ellipsoid = cfg.size / BLOCKS_PER_BLOB
	local size_half = ceil ((cfg.size / BLOCKS_PER_BLOB + 1.0) / 2.0)

	-- Bounds of ellipsoid within which blobs may generate.
	local x1 = x - mathsin (dir) * size_ellipsoid
	local x2 = x + mathsin (dir) * size_ellipsoid
	local z1 = z - mathcos (dir) * size_ellipsoid
	local z2 = z + mathcos (dir) * size_ellipsoid
	local y1 = y + rng:next_within (3) - 2 -- -2 to 0
	local y2 = y + rng:next_within (3) - 2 -- -2 to 0

	-- Absolute confines of level modification.  The largest
	-- naturally generating ore (tuff) has a size of 64 and
	-- consequently the maximum extent of an ore vein on any axis
	-- is 13*2 blocks from the center, which is comfortably within
	-- the 32 block feature size limit.

	local hradius = ceil (size_ellipsoid) + size_half
	local xmin = x - hradius
	local zmin = z - hradius
	local ymin = y - 2 - size_half -- 2 = blob height.
	local hsize = hradius * 2.0
	local ysize = (2 + size_half) * 2.0

	-- Verify that at least one position within these confines is
	-- beneath the surface of the level.
	for x = xmin, xmin + hsize do
		for z = zmin, zmin + hsize do
			local _, blocking = index_heightmap (x, z)
			if ymin <= blocking then
				return ore_place_1 (x1, x2, z1, z2, y1, y2,
						    xmin, ymin, zmin, hsize,
						    ysize, cfg, rng)
			end
		end
	end
	return false
end

mcl_levelgen.register_feature ("mcl_levelgen:ore", {
	place = ore_place,
})

function mcl_levelgen.construct_ore_substitution_list (items)
	local substitutions = {}

	for _, tbl in ipairs (items) do
		local cids = {}
		local target = tbl.target
		if target:sub (1, 6) == "group:" then
			local group = target:sub (7)
			for name, tbl in pairs (core.registered_nodes) do
				if tbl.groups[group] and tbl.groups[group] > 0 then
					local id = core.get_content_id (name)
					table.insert (cids, id)
				end
			end
		else
			table.insert (cids, core.get_content_id (target))
		end

		for _, cid in ipairs (cids) do
			table.insert (substitutions, {
				cid, core.get_content_id (tbl.replacement),
				tbl.param2 or 0,
			})
		end
	end
	return substitutions
end

------------------------------------------------------------------------
-- Patch.
-- mcl_levelgen:random_patch
------------------------------------------------------------------------

-- local patch_configuration = {
-- 	placed_feature = nil,
-- 	tries = nil,
-- 	xz_spread = nil,
-- 	y_spread = nil,
-- }

local blurb = "Patch attempted to place nonexistent feature: "

local function patch_random_place (_, x, y, z, cfg, rng)
	if y < run_minp.y or y > run_maxp.y then
		return false
	end

	local feature = cfg.placed_feature
	if type (feature) == "string" then
		feature = mcl_levelgen.registered_placed_features[feature]
		if not feature then
			if not warned[feature] then
				core.log ("warning", blurb .. feature)
				warned[feature] = true
			end
			return false
		end
	end

	local yspread = cfg.y_spread + 1
	local xzspread = cfg.xz_spread + 1
	local placed = false
	for i = 1, cfg.tries do
		-- Triangular distribution.
		local dx = rng:next_within (xzspread)
			- rng:next_within (xzspread)
		local dy = rng:next_within (yspread)
			- rng:next_within (yspread)
		local dz = rng:next_within (xzspread)
			- rng:next_within (xzspread)

		if place_one_feature (feature, x + dx, y + dy, z + dz) then
			placed = true
		end
	end
	return placed
end

mcl_levelgen.register_feature ("mcl_levelgen:random_patch", {
	place = patch_random_place,
})

------------------------------------------------------------------------
-- Simple block feature.
-- mcl_levelgen:simple_block
------------------------------------------------------------------------

local double_plant_p = mcl_levelgen.double_plant_p
local is_position_hospitable = mcl_levelgen.is_position_hospitable

local place_double_plant = mcl_levelgen.place_double_plant

local function simple_block_place (_, x, y, z, cfg, rng)
	if y < run_minp.y or y > run_maxp.y then
		return false
	end

	local cid_to_place, param2 = cfg.content (x, y, z, rng)
	if param2 == "grass_palette_index" then
		local biome = index_biome (x, y, z)
		local def = mcl_levelgen.registered_biomes[biome]
		param2 = def and def.grass_palette_index or 0
	end

	if is_position_hospitable (cid_to_place, x, y, z) then
		if double_plant_p (cid_to_place) then
			if (get_block (x, y + 1, z)) ~= cid_air then
				return false
			end
			place_double_plant (cid_to_place, x, y, z, param2,
					    set_block)
		else
			set_block (x, y, z, cid_to_place, param2)
		end
		return true
	end
	return false
end

mcl_levelgen.register_feature ("mcl_levelgen:simple_block", {
	place = simple_block_place,
})

------------------------------------------------------------------------
-- Fundamental placement modifiers.
------------------------------------------------------------------------

-- Weighted lists.

function mcl_levelgen.build_weighted_list (list)
	local total_weight = 0
	for _, entry in ipairs (list) do
		total_weight = total_weight + entry.weight
	end
	return function (rng)
		if total_weight == 0 then
			return nil
		else
			local cnt = rng:next_within (total_weight)
			for _, entry in ipairs (list) do
				cnt = cnt - entry.weight
				if cnt < 0 then
					return entry.data
				end
			end
			return nil
		end
	end
end

function mcl_levelgen.build_weighted_cid_provider (list)
	local total_weight = 0
	for _, entry in ipairs (list) do
		total_weight = total_weight + entry.weight
	end
	return function (x, y, z, rng)
		if total_weight == 0 then
			return nil, nil
		else
			local cnt = rng:next_within (total_weight)
			for _, entry in ipairs (list) do
				cnt = cnt - entry.weight
				if cnt < 0 then
					return entry.cid, entry.param2
				end
			end
			return nil, nil
		end
	end
end

function mcl_levelgen.build_count (n)
	return function (x, y, z, rng)
		local cnt = n (rng)
		local results = {}
		for i = 1, cnt do
			results[#results + 1] = x
			results[#results + 1] = y
			results[#results + 1] = z
		end
		return results
	end
end

local BIOME_SELECTOR_NOISE = mcl_levelgen.BIOME_SELECTOR_NOISE

function mcl_levelgen.build_noise_threshold_count (noise_level, above_noise,
						   below_noise)
	return function (x, y, z, rng)
		local noise = BIOME_SELECTOR_NOISE (x / 200.0, z / 200.0)
		local cnt = above_noise
		if noise < noise_level then
			cnt = below_noise
		end
		local results = {}
		for i = 1, cnt do
			results[#results + 1] = x
			results[#results + 1] = y
			results[#results + 1] = z
		end
		return results
	end
end

local function in_square (x, y, z, rng)
	return {
		x + rng:next_within (16),
		y,
		z + rng:next_within (16),
	}
end

function mcl_levelgen.build_in_square ()
	return in_square
end

local registered_biomes = mcl_levelgen.registered_biomes
local indexof = table.indexof

function mcl_levelgen.build_in_biome ()
	local last_biome, last_result = nil
	return function (x, y, z, rng)
		if y < mcl_levelgen.placement_run_minp.y
			or y > mcl_levelgen.placement_run_maxp.y then
			return nil
		end

		local biome = index_biome (x, y, z)
		local def = registered_biomes[biome]
		local current_feature
			= mcl_levelgen.current_placed_feature
		local current_step
			= mcl_levelgen.current_step
		if biome ~= last_biome then
			local step_features = def.features[current_step]
			last_result = step_features
				and indexof (step_features,
					     current_feature) ~= -1
			last_biome = biome
		end
		return last_result and { x, y, z, } or nil
	end
end

local index_heightmap = mcl_levelgen.index_heightmap

local function heightmap_world_surface (x, y, z, rng)
	local surface, _ = index_heightmap (x, z)

	if surface <= mcl_levelgen.placement_level_min then
		return {}
	else
		return { x, surface, z, }
	end
end

local function heightmap_motion_blocking (x, y, z, rng)
	local _, surface = index_heightmap (x, z)

	if surface <= mcl_levelgen.placement_level_min then
		return {}
	else
		return { x, surface, z, }
	end
end

function mcl_levelgen.build_heightmap (heightmap)
	assert (heightmap == "world_surface"
		or heightmap == "motion_blocking")

	if heightmap == "world_surface" then
		return heightmap_world_surface
	else
		return heightmap_motion_blocking
	end
end

function mcl_levelgen.build_surface_water_depth_filter (n)
	return function (x, y, z, rng)
		local surface, motion_blocking
			= index_heightmap (x, z)
		if surface - motion_blocking <= n then
			return { x, y, z, }
		else
			return {}
		end
	end
end

local function in_range (x, y, z)
	local min_x = mcl_levelgen.placement_run_min_x
	local min_y = mcl_levelgen.placement_run_min_y
	local min_z = mcl_levelgen.placement_run_min_z
	local max_x = mcl_levelgen.placement_run_max_x
	local max_y = mcl_levelgen.placement_run_max_y
	local max_z = mcl_levelgen.placement_run_max_z
	return x >= min_x and y >= min_y and z >= min_z
		and x <= max_x and y <= max_y and z <= max_z
end

local function always ()
	return true
end

local MAX_POS = 512

function mcl_levelgen.build_environment_scan (parms)
	local direction = parms.direction
	local allowed_search_condition = parms.allowed_search_condition	or always
	local target_condition = parms.target_condition
	local max_steps = parms.max_steps

	return function (x, y, z, rng)
		if not allowed_search_condition (x, y, z) then
			return { x, direction * MAX_POS, z, }
		else
			for i = 1, max_steps do
				if target_condition (x, y, z) then
					return { x, y, z, }
				end

				y = y + direction
				if not in_range (x, y, z) then
					return { x, direction * MAX_POS, z, }
				end

				if not allowed_search_condition (x, y, z) then
					break
				end
			end
			return target_condition (x, y, z) and { x, y, z, }
				or { x, direction * MAX_POS, z, }
		end
	end
end

function mcl_levelgen.build_rarity_filter (n)
	local chance = 1.0 / n

	return function (x, y, z, rng)
		if rng:next_float () < chance then
			return { x, y, z, }
		else
			return {}
		end
	end
end

function mcl_levelgen.build_height_range (n)
	return function (x, y, z, rng)
		return { x, n (rng), z, }
	end
end

function mcl_levelgen.build_constant_height_offset (n)
	return function (x, y, z, rng)
		return { x, y + n, z, }
	end
end

function mcl_levelgen.build_random_offset (xz_scale, y_scale)
	return function (x, y, z, rng)
		return {
			x + xz_scale (rng),
			y + y_scale (rng),
			z + xz_scale (rng),
		}
	end
end

------------------------------------------------------------------------
-- Default placed features.
------------------------------------------------------------------------

-- TODO: export these functions and remove duplicates.

local function rtz (n)
	if n < 0 then
		return ceil (n)
	end
	return floor (n)
end

local function trapezoidal_height (min, max, bound)
	local diff = max - min
	local bound_diff = rtz ((diff - bound) / 2)
	local base_diff = diff - bound_diff
	return function (rng)
		if bound >= diff then
			return rng:next_within (diff + 1) + min
		else
			return min + rng:next_within (base_diff + 1)
				+ rng:next_within (bound_diff + 1)
		end
	end
end

local function uniform_height (min_inclusive, max_inclusive)
	local diff = max_inclusive - min_inclusive + 1
	return function (rng)
		return rng:next_within (diff) + min_inclusive
	end
end

local O = mcl_levelgen.construct_ore_substitution_list

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_coal", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 17,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_coal",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_coal",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_coal_buried", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.5,
	size = 17,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_coal",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_coal",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_andesite", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 64,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:andesite",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:andesite",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_clay", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 33,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:clay",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:clay",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_copper_large", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 20,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_copper:stone_with_copper",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_copper",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_copper_small", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 10,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_copper:stone_with_copper",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_copper",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_diamond_buried", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 1.0,
	size = 8,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_diamond",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_diamond",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_diamond_large", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.7,
	size = 12,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_diamond",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_diamond",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_diamond_medium", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.5,
	size = 8,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_diamond",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_diamond",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_diamond_small", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.5,
	size = 4,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_diamond",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_diamond",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_diorite", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 64,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:diorite",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:diorite",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_dirt", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 33,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:dirt",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:dirt",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_emerald", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 3,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_emerald",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_emerald",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_gold_buried", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.5,
	size = 9,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_gold",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_gold",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_gold", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 9,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_gold",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_gold",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_granite", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 64,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:granite",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:granite",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_gravel", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 33,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:gravel",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_core:gravel",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_infested", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 9,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_monster_eggs:monster_egg_stone",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_monster_eggs:monster_egg_deepslate",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_iron", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 9,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_iron",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_iron",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_iron_small", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 4,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_iron",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_iron",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_lapis_buried", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 1.0,
	size = 7,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_lapis",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_lapis",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_lapis", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 7,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_lapis",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_lapis",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_redstone", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 8,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_core:stone_with_redstone",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:deepslate_with_redstone",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:ore_tuff", {
	feature = "mcl_levelgen:ore",
	discard_chance_on_air_exposure = 0.0,
	size = 64,
	substitutions = O ({
		{
			target = "group:stone_ore_target",
			replacement = "mcl_deepslate:tuff",
		},
		{
			target = "group:deepslate_ore_target",
			replacement = "mcl_deepslate:tuff",
		},
	}),
})

local overworld = mcl_levelgen.overworld_preset
local OVERWORLD_TOP = overworld.min_y + overworld.height - 1
local OVERWORLD_MIN = overworld.min_y
local THIRTY = function () return 30 end
local TWENTY = function () return 20 end
local TWO = function () return 2 end
local FOURTY_SIX = function () return 46 end
local SIXTEEN = function () return 16 end
local SEVEN = function () return 7 end
local FOUR = function () return 4 end
local ONE_HUNDRED = function () return 100 end
local FIFTY = function () return 50 end
-- local SIX = function () return 6 end
local FOURTEEN = function () return 14 end
local TEN = function () return 10 end
local NINETY = function () return 90 end

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_coal_upper", {
	configured_feature = "mcl_levelgen:ore_coal",
	placement_modifiers = {
		mcl_levelgen.build_count (THIRTY),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (136, OVERWORLD_TOP)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_coal_lower", {
	configured_feature = "mcl_levelgen:ore_coal_buried",
	placement_modifiers = {
		mcl_levelgen.build_count (TWENTY),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (0, 192, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_andesite_lower", {
	configured_feature = "mcl_levelgen:ore_andesite",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 60)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_andesite_upper", {
	configured_feature = "mcl_levelgen:ore_andesite",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (6),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (64, 128)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_clay", {
	configured_feature = "mcl_levelgen:ore_clay",
	placement_modifiers = {
		mcl_levelgen.build_count (FOURTY_SIX),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 256)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_copper", {
	configured_feature = "mcl_levelgen:ore_copper_small",
	placement_modifiers = {
		mcl_levelgen.build_count (SIXTEEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-16, 112, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_copper_large", {
	configured_feature = "mcl_levelgen:ore_copper_large",
	placement_modifiers = {
		mcl_levelgen.build_count (SIXTEEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-16, 112, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

local diamond_range = trapezoidal_height (OVERWORLD_MIN - 80, OVERWORLD_MIN + 80, 0)

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diamond", {
	configured_feature = "mcl_levelgen:ore_diamond_small",
	placement_modifiers = {
		mcl_levelgen.build_count (SEVEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (diamond_range),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diamond_buried", {
	configured_feature = "mcl_levelgen:ore_diamond_buried",
	placement_modifiers = {
		mcl_levelgen.build_count (FOUR),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (diamond_range),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diamond_large", {
	configured_feature = "mcl_levelgen:ore_diamond_large",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (9),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (diamond_range),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diamond_medium", {
	configured_feature = "mcl_levelgen:ore_diamond_medium",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-64, 4, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diorite_lower", {
	configured_feature = "mcl_levelgen:ore_diorite",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 60)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_diorite_upper", {
	configured_feature = "mcl_levelgen:ore_diorite",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (6),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (64, 128)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_dirt", {
	configured_feature = "mcl_levelgen:ore_dirt",
	placement_modifiers = {
		mcl_levelgen.build_count (SEVEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 160)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_emerald", {
	configured_feature = "mcl_levelgen:ore_emerald",
	placement_modifiers = {
		mcl_levelgen.build_count (ONE_HUNDRED),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-16, 480, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_gold_extra", {
	configured_feature = "mcl_levelgen:ore_gold",
	placement_modifiers = {
		mcl_levelgen.build_count (FIFTY),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (32, 256, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_gold", {
	configured_feature = "mcl_levelgen:ore_gold_buried",
	placement_modifiers = {
		mcl_levelgen.build_count (FOUR),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-64, 32, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_gold_lower", {
	configured_feature = "mcl_levelgen:ore_gold_buried",
	placement_modifiers = {
		mcl_levelgen.build_count (uniform_height (0, 1)),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (-64, -48)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_granite_lower", {
	configured_feature = "mcl_levelgen:ore_granite",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 60)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_granite_upper", {
	configured_feature = "mcl_levelgen:ore_granite",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (6),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, 60)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_gravel", {
	configured_feature = "mcl_levelgen:ore_gravel",
	placement_modifiers = {
		mcl_levelgen.build_count (FOURTEEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN,
								 OVERWORLD_TOP)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_infested", {
	configured_feature = "mcl_levelgen:ore_infested",
	placement_modifiers = {
		mcl_levelgen.build_count (FOURTEEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN, 63)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_iron_middle", {
	configured_feature = "mcl_levelgen:ore_iron",
	placement_modifiers = {
		mcl_levelgen.build_count (TEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-24, 56, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_iron_small", {
	configured_feature = "mcl_levelgen:ore_iron_small",
	placement_modifiers = {
		mcl_levelgen.build_count (TEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (OVERWORLD_MIN,
								     72, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_iron_upper", {
	configured_feature = "mcl_levelgen:ore_iron",
	placement_modifiers = {
		mcl_levelgen.build_count (NINETY),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (80, 384, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_lapis_buried", {
	configured_feature = "mcl_levelgen:ore_lapis_buried",
	placement_modifiers = {
		mcl_levelgen.build_count (FOUR),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN, 64)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_lapis", {
	configured_feature = "mcl_levelgen:ore_lapis",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (trapezoidal_height (-32, 32, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_redstone", {
	configured_feature = "mcl_levelgen:ore_redstone",
	placement_modifiers = {
		mcl_levelgen.build_count (FOUR),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN, 15)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:ore_tuff", {
	configured_feature = "mcl_levelgen:ore_tuff",
	placement_modifiers = {
		mcl_levelgen.build_count (TWO),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN, 0)),
		mcl_levelgen.build_in_biome (),
	},
})

-- Soil/ground vegetation.

local FIVE = function () return 5 end
local cid_double_grass = core.get_content_id ("mcl_flowers:double_grass")
local cid_tallgrass = core.get_content_id ("mcl_flowers:tallgrass")

mcl_levelgen.register_configured_feature ("mcl_levelgen:block_tall_grass", {
	feature = "mcl_levelgen:simple_block",
	content = function (_, _, _, rng)
		return cid_double_grass, "grass_palette_index"
	end,
})

local function require_air (x, y, z, rng)
	local cid, _ = get_block (x, y, z)
	if cid == cid_air then
		return { x, y, z, }
	end
	return nil
end

mcl_levelgen.register_configured_feature ("mcl_levelgen:patch_tall_grass", {
	feature = "mcl_levelgen:random_patch",
	placed_feature = {
		configured_feature = "mcl_levelgen:block_tall_grass",
		placement_modifiers = {
			require_air,
		},
	},
	tries = 96,
	xz_spread = 7,
	y_spread = 3,
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_tall_grass", {
	configured_feature = "mcl_levelgen:patch_tall_grass",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (5),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_tall_grass_2", {
	configured_feature = "mcl_levelgen:patch_tall_grass",
	placement_modifiers = {
		mcl_levelgen.build_noise_threshold_count (-0.8, 7, 0),
		mcl_levelgen.build_rarity_filter (32),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:block_short_grass", {
	feature = "mcl_levelgen:simple_block",
	content = function (_, _, _, rng)
		return cid_tallgrass, "grass_palette_index"
	end,
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:patch_grass", {
	feature = "mcl_levelgen:random_patch",
	placed_feature = {
		configured_feature = "mcl_levelgen:block_short_grass",
		placement_modifiers = {
			require_air,
		},
	},
	tries = 32,
	xz_spread = 7,
	y_spread = 3,
})

local E = mcl_levelgen.build_environment_scan
local scan_beneath_leaves = E ({
	allowed_search_condition = mcl_levelgen.is_leaf_or_air,
	target_condition = mcl_levelgen.is_air_with_dirt_below,
	max_steps = 24,
	direction = -1,
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_normal", {
	configured_feature = "mcl_levelgen:patch_grass",
	placement_modifiers = {
		mcl_levelgen.build_count (FIVE),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_badlands", {
	configured_feature = "mcl_levelgen:patch_grass",
	placement_modifiers = {
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_plain", {
	configured_feature = "mcl_levelgen:patch_grass",
	placement_modifiers = {
		mcl_levelgen.build_noise_threshold_count (-0.8, 10, 5),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_savannah", {
	configured_feature = "mcl_levelgen:patch_grass",
	placement_modifiers = {
		mcl_levelgen.build_count (TWENTY),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})

local C = mcl_levelgen.build_weighted_cid_provider

mcl_levelgen.register_configured_feature ("mcl_levelgen:block_taiga_grass", {
	feature = "mcl_levelgen:simple_block",
	content = C ({
		{
			weight = 1,
			cid = cid_tallgrass,
			param2 = "grass_palette_index",
		},
		{
			weight = 4,
			cid = core.get_content_id ("mcl_flowers:fern"),
			param2 = "grass_palette_index",
		},
	}),
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:patch_taiga_grass", {
	feature = "mcl_levelgen:random_patch",
	placed_feature = {
		configured_feature = "mcl_levelgen:block_taiga_grass",
		placement_modifiers = {
			require_air,
		},
	},
	tries = 32,
	xz_spread = 7,
	y_spread = 3,
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_taiga", {
	configured_feature = "mcl_levelgen:patch_taiga_grass",
	placement_modifiers = {
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_grass_taiga_2", {
	configured_feature = "mcl_levelgen:patch_taiga_grass",
	placement_modifiers = {
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("world_surface"),
		scan_beneath_leaves,
		mcl_levelgen.build_in_biome (),
	},
})
