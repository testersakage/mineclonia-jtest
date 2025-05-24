------------------------------------------------------------------------
-- Fundamental features and placement modifiers.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Freeze Top Layer
-- mcl_levelgen:freeze_top_layer
------------------------------------------------------------------------

local index_biome = mcl_levelgen.index_biome
local index_heightmap = mcl_levelgen.index_heightmap
local set_block = mcl_levelgen.set_block
local cid_snow = core.get_content_id ("mcl_core:snow_2")

local function place_freeze_top_layer (_, x, y, z, rng)
	local start_y = mcl_levelgen.placement_run_minp.y
	local end_y = mcl_levelgen.placement_run_maxp.y
	for dx = 0, 15 do
		for dz = 0, 15 do
			local x1, z1 = x + dx, z + dz
			local surface, _ = index_heightmap (x1, z1)

			if surface >= start_y and surface <= end_y then
				local biome = index_biome (x1, surface, z1)
				if mcl_levelgen.is_temp_snowy (biome, x1, surface, z1) then
					set_block (x1, surface, z1, cid_snow, 0)
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
