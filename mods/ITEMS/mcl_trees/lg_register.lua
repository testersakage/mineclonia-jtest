local tree_placement_flags = {
	place_center_x = true,
	place_center_z = true,
}

local function register_tree_structure (name, schematic_set, after_place, details)
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
		mcl_levelgen.register_feature ("mcl_trees:" .. name, table.merge ({
			place = function (self, x, y, z, cfg, rng)
				local i = 1 + rng:next_within (n)
				local schematic = schematics[i]
				mcl_levelgen.place_schematic (x, y, z, schematic, "random",
							      true, tree_placement_flags,
							      rng)
				if after_place then
					after_place (x, y, z, cfg, rng)
				end
			end,
			tree_type = name,
		}))
		mcl_levelgen.register_configured_feature ("mcl_trees:" .. name, table.merge ({
			feature = "mcl_trees:" .. name,
		}, details))
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

register_tree_structure ("oak", {
	modpath .. "/schematics/mcl_core_oak_v6.mts",
	modpath .. "/schematics/mcl_core_oak_classic.mts",
})

register_tree_structure ("fancy_oak", {
	modpath .. "/schematics/mcl_core_oak_balloon.mts",
	modpath .. "/schematics/mcl_core_oak_large_1.mts",
	modpath .. "/schematics/mcl_core_oak_large_2.mts",
	modpath .. "/schematics/mcl_core_oak_large_3.mts",
	modpath .. "/schematics/mcl_core_oak_large_4.mts",
})

local get_block = mcl_levelgen.get_block
local set_block = mcl_levelgen.set_block
local fix_lighting = mcl_levelgen.fix_lighting

local cid_bee_nest = core.get_content_id ("mcl_beehives:bee_nest")

local dirs = {
	{1, 0,},
	{0, 1,},
	{-1, 0,},
	{0, -1,},
}

local function place_beehive (x, y, z, cfg, rng)
	local leaf_cid = cfg.leaf_cid
	if rng:next_float () >= cfg.beehive_probability then
		return
	end
	local dir = 1 + rng:next_within (4)
	local xoff, zoff = dirs[dir][1], dirs[dir][2]
	local x = x + xoff
	local z = z + zoff
	for i = 2, 8 do
		local cid, param2 = get_block (x, y + i, z)
		if cid == leaf_cid then
			set_block (x, y + i - 1, z, cid_bee_nest, 0)
			fix_lighting (x, y + i, z, x, y + i, z)
			break
		end
	end
end

local get_content_id
if mcl_levelgen.is_levelgen_environment then
	get_content_id = core.get_content_id
else
	-- CIDs are unavailable when this mod is loaded, but they're
	-- only referenced from the level generator environment.
	get_content_id = function ()
		return core.CONTENT_IGNORE
	end
end

register_tree_structure ("oak_with_beehive_005", {
	modpath .. "/schematics/mcl_core_oak_v6.mts",
	modpath .. "/schematics/mcl_core_oak_classic.mts",
}, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.05,
})

register_tree_structure ("fancy_oak_with_beehive_005", {
	modpath .. "/schematics/mcl_core_oak_balloon.mts",
	modpath .. "/schematics/mcl_core_oak_large_1.mts",
	modpath .. "/schematics/mcl_core_oak_large_2.mts",
	modpath .. "/schematics/mcl_core_oak_large_3.mts",
	modpath .. "/schematics/mcl_core_oak_large_4.mts",
}, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.05,
})

if mcl_levelgen.is_levelgen_environment then

local cid_spruce_sapling
	= core.get_content_id ("mcl_trees:sapling_spruce")
local cid_oak_sapling
	= core.get_content_id ("mcl_trees:sapling_oak")

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

mcl_levelgen.register_configured_feature ("mcl_trees:trees_plains", {
	feature = "mcl_levelgen:random_selector",
	default = {
		configured_feature = "mcl_trees:oak_with_beehive_005",
		placement_modifiers = {},
	},
	features = {
		{
			feature = {
				configured_feature = "mcl_trees:fancy_oak_with_beehive_005",
				placement_modifiers = {},
			},
			chance = 1/3,
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_plains", {
	configured_feature = "mcl_trees:trees_plains",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 19,
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
			if is_position_hospitable (cid_oak_sapling, x, y, z) then
				return { x, y, z, }
			else
				return nil
			end
		end,
	}
})

end
