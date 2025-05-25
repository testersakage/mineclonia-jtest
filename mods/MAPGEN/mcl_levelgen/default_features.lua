local mcl_levelgen = mcl_levelgen
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
			local feature_desc = registered_placed_features[id]
			if not feature_desc and not warned[id] then
				core.log ("warning", table.concat ({
					"Random selector attempted to place a ",
					"nonexistent placed feature, ", id,
				}))
				warned[id] = true
			elseif feature_desc then
				place_one_feature (feature, x, y, z)
				return
			end
		end
	end

	local default_desc = registered_placed_features[cfg.default]
	if not default_desc then
		if not warned[cfg.default] then
			core.log ("warning", table.concat ({
				"Random selector attempted to place a ",
				"nonexistent default placed feature, ", id,
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
local cid_snow = core.get_content_id ("mcl_core:snow")
local cid_water_source = core.get_content_id ("mcl_core:water_source")
local cid_ice = core.get_content_id ("mcl_core:ice")
local cid_dirt = core.get_content_id ("mcl_core:dirt")
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

local function place_freeze_top_layer (_, x, y, z, cfg, rng)
	local start_y = mcl_levelgen.placement_run_minp.y
	local end_y = mcl_levelgen.placement_run_maxp.y
	for dx = 0, 15 do
		for dz = 0, 15 do
			local x1, z1 = x + dx, z + dz
			local surface, _ = index_heightmap (x1, z1)

			if surface >= start_y and surface <= end_y then
				local biome = index_biome (x1, surface, z1)
				local frigid
					= mcl_levelgen.is_temp_snowy (biome, x1, surface, z1)

				if frigid then
					-- Freeze the node below if it is
					-- water and not brighter than 10.
					-- TODO: test light levels.
					local cid, _ = get_block (x1, surface - 1, z1)
					if cid == cid_water_source then
						set_block (x1, surface - 1, z1, cid_ice, 0)
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

local insert = table.insert

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
		if biome == last_biome then
			return last_result
		end
		local step_features = def.features[current_step]
		last_result = step_features
			and indexof (step_features,
				     current_feature) ~= -1
		last_biome = biome
		return last_result
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
