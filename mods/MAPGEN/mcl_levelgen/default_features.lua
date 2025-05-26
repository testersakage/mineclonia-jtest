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

local get_biome = mcl_levelgen.index_biome
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
		and x <= max_x and y <= max_x and z <= max_z
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
