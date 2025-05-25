local tree_placement_flags = {
	place_center_x = true,
	place_center_z = true,
}

local function register_tree_structure (name, schematic_set)
	local schematics = {}
	for i, schematic in ipairs (schematic_set) do
		local name = "mcl_trees:" .. name .. "_" .. i
		table.insert (schematics, name)

		if not mcl_levelgen.is_levelgen_environment then
			mcl_levelgen.register_portable_schematic (name, schematic)
		end
	end

	if mcl_levelgen.is_levelgen_environment then
		local n = #schematics
		mcl_levelgen.register_feature ("mcl_trees:" .. name, {
			place = function (_, x, y, z, cfg, rng)
				local schematic = schematics[1 + rng:next_within (n)]
				mcl_levelgen.place_schematic (x, y, z, schematic, "random",
							      true, tree_placement_flags,
							      rng)
			end,
		})
		mcl_levelgen.register_configured_feature ("mcl_trees:" .. name, {
			feature = "mcl_trees:" .. name,
		})
	end
end

------------------------------------------------------------------------
-- Level generator feature registration.
------------------------------------------------------------------------

local W = mcl_levelgen.build_weighted_list
local modpath = core.get_modpath ("mcl_core")

register_tree_structure ("spruce", {
	modpath .. "/schematics/mcl_core_spruce_1.mts",
	modpath .. "/schematics/mcl_core_spruce_2.mts",
	modpath .. "/schematics/mcl_core_spruce_3.mts",
	modpath .. "/schematics/mcl_core_spruce_4.mts",
	modpath .. "/schematics/mcl_core_spruce_5.mts",
	modpath .. "/schematics/mcl_core_spruce_lollipop.mts",
})

if mcl_levelgen.is_levelgen_environment then

local cid_spruce_sapling
	= core.get_content_id ("mcl_trees:sapling_spruce")
local is_position_hospitable
	= mcl_levelgen.is_position_hospitable

mcl_levelgen.register_placed_feature ("mcl_trees:trees_snowy", {
	configured_feature = "mcl_trees:spruce",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 0,
			},
			{
				weight = 1,
				data = 1,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
		function (x, y, z, rng)
			if is_position_hospitable (cid_spruce_sapling, x, y, z) then
				return { x, y, z, }
			else
				return nil
			end
		end,
	},
})

end
