if not core.global_exists ("mcl_trees") then
	mcl_trees = {}
end

local mathmax = math.max
local mathmin = math.min
local mathabs = math.abs
local floor = math.floor

local tree_placement_flags = {
	place_center_x = true,
	place_center_z = true,
}

local cid_air = core.CONTENT_AIR
local is_position_hospitable = mcl_levelgen.is_position_hospitable

local function build_hospitability_check (cid)
	return function (x, y, z, rng)
		if is_position_hospitable (cid, x, y, z) then
			return { x, y, z, }
		else
			return nil
		end
	end
end

local get_block = mcl_levelgen.get_block

local function build_node_check (cid1, cid2, xoff, yoff, zoff)
	return function (x, y, z, rng)
		local cid, _ = get_block (x, y + yoff, z)
		if cid == cid1 or (cid2 and cid == cid2) then
			return { x, y, z, }
		else
			return { }
		end
	end
end

local set_block = mcl_levelgen.set_block
local run_minp = mcl_levelgen.placement_run_minp
local run_maxp = mcl_levelgen.placement_run_maxp

local function test_clearance (x, y, z, min, max, rng)
	local trunk_height = min + rng:next_within (max - min + 1)
	for y = y, y + trunk_height - 1 do
		if y > run_maxp.y + 32 then
			return false
		end
		if (get_block (x, y, z)) ~= cid_air then
			return false
		end
	end
	return true
end

local biomecolor_nodes = {}
local registered_biomes = mcl_levelgen.registered_biomes
local index_biome = mcl_levelgen.index_biome

local function apply_biome_coloration (aabb)
	local x1, y1, z1 = aabb[1], aabb[2], aabb[3]
	local x2, y2, z2 = aabb[4], aabb[5], aabb[6]

	x1 = mathmax (run_minp.x - 16, x1)
	x2 = mathmin (run_maxp.x + 16, x2)
	z1 = mathmax (run_minp.z - 16, z1)
	z2 = mathmin (run_maxp.z + 16, z2)
	y1 = mathmax (run_minp.y - 32, y1)
	y2 = mathmin (run_maxp.y + 32, y2)

	for x = x1, x2 do
		for y = y1, y2 do
			for z = z1, z2 do
				local cid, _ = get_block (x, y, z)
				if biomecolor_nodes[cid] then
					local biome = index_biome (x, y, z)
					local def = registered_biomes[biome]
					local idx = 32 + def.grass_palette_index
					set_block (x, y, z, cid, idx)
				end
			end
		end
	end
end

mcl_trees.apply_biome_coloration = apply_biome_coloration

local function register_tree_feature (name, schematic_set, after_place, details,
				      sapling_type, trunk_offset,
				      min_trunk_clearance, max_trunk_clearance)
	if not trunk_offset then
		trunk_offset = 0
	end
	local schematics = {}
	for i, schematic in ipairs (schematic_set) do
		local name = "mcl_trees:" .. name .. "_" .. i
		table.insert (schematics, name)

		if not mcl_levelgen.is_levelgen_environment then
			mcl_levelgen.register_portable_schematic (name, schematic, true)
		end
	end
	local min_trunk_clearance = min_trunk_clearance or 8
	local max_trunk_clearance = max_trunk_clearance or 8

	if mcl_levelgen.is_levelgen_environment then
		local n = #schematics
		mcl_levelgen.register_feature ("mcl_trees:" .. name, table.merge ({
			place = function (self, x, y, z, cfg, rng)
				if y < run_minp.y or y > run_maxp.y then
					rng:consume (1)
					rng:next_within (n)
					rng:consume (after_place and 2 or 1)
					return
				end

				if not test_clearance (x, y, z, min_trunk_clearance,
						       max_trunk_clearance, rng) then
					rng:next_within (n)
					rng:consume (after_place and 2 or 1)
					return
				end

				local i = 1 + rng:next_within (n)
				local schematic = schematics[i]
				local aabb
					= mcl_levelgen.place_schematic (x, y + trunk_offset,
									z, schematic,
									"random", false,
									tree_placement_flags,
									rng)
				if after_place then
					after_place (x, y, z, cfg, rng)
				end
				apply_biome_coloration (aabb)
			end,
			tree_type = name,
		}))
		mcl_levelgen.register_configured_feature ("mcl_trees:" .. name, table.merge ({
			feature = "mcl_trees:" .. name,
		}, details))

		local sapling_type = core.get_content_id (sapling_type)
		mcl_levelgen.register_placed_feature ("mcl_trees:" .. name, {
			configured_feature = "mcl_trees:" .. name,
			placement_modifiers = {
				build_hospitability_check (sapling_type),
			},
		})
	end
end

------------------------------------------------------------------------
-- Level generator feature registration.
------------------------------------------------------------------------

local W = mcl_levelgen.build_weighted_list
local E = mcl_levelgen.build_environment_scan
local modpath = core.get_modpath ("mcl_core")

local spruce = {
	modpath .. "/schematics/mcl_core_spruce_1.mts",
	modpath .. "/schematics/mcl_core_spruce_2.mts",
	modpath .. "/schematics/mcl_core_spruce_3.mts",
	modpath .. "/schematics/mcl_core_spruce_4.mts",
	modpath .. "/schematics/mcl_core_spruce_5.mts",
	modpath .. "/schematics/mcl_core_spruce_tall.mts",
	modpath .. "/schematics/mcl_core_spruce_lollipop.mts",
}

local pine = {
	modpath .. "/schematics/mcl_core_spruce_matchstick.mts",
}

local mega_spruce = {
	modpath .. "/schematics/mcl_core_spruce_huge_1.mts",
	modpath .. "/schematics/mcl_core_spruce_huge_2.mts",
	modpath .. "/schematics/mcl_core_spruce_huge_3.mts",
	modpath .. "/schematics/mcl_core_spruce_huge_4.mts",
}

local mega_pine = {
	modpath .. "/schematics/mcl_core_spruce_huge_up_1.mts",
	modpath .. "/schematics/mcl_core_spruce_huge_up_2.mts",
	modpath .. "/schematics/mcl_core_spruce_huge_up_3.mts",
}

register_tree_feature ("spruce", spruce, nil, nil, "mcl_trees:sapling_spruce",
		       0, 6, 10)
register_tree_feature ("pine", pine, nil, nil, "mcl_trees:sapling_spruce",
		       0, 10, 10)

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

local ull = mcl_levelgen.ull
local podzol_rng = mcl_levelgen.jvm_random (ull (0, 0), ull (0, 0))
local is_cid_dirt = mcl_levelgen.is_cid_dirt
local cid_podzol = get_content_id ("mcl_core:podzol")

local function podzolize (x, y, z)
	local y = y - 1
	for dx = -2, 2 do
		for dz = -2, 2 do
			if mathabs (dx) ~= 2 or mathabs (dz) ~= 2 then
				local cid, _ = get_block (x + dx, y, z + dz)
				if is_cid_dirt[cid] then
					set_block (x + dx, y, z + dz, cid_podzol, 0)
				end
			end
		end
	end
end

local function place_podzol (x, y, z, cfg, rng)
	podzol_rng:reseed (rng:next_long ())

	podzolize (x + 2, y, z + 2)
	podzolize (x - 2, y, z - 2)
	podzolize (x + 2, y, z - 2)
	podzolize (x - 2, y, z + 2)

	for i = 0, 5 do
		local n = podzol_rng:next_within (64)
		local k = n % 8
		local g = floor (n / 8)
		if x == 0 or k == 7 or g == 0 or g == 7 then
			podzolize (x + -3 + k, y, z + -3 + g)
		end
	end
end

register_tree_feature ("mega_spruce", mega_spruce, place_podzol, nil,
		       "mcl_trees:sapling_spruce",
		       -1, 20, 20)
register_tree_feature ("mega_pine", mega_pine, place_podzol, nil,
		       "mcl_trees:sapling_spruce", -1, 20, 20)

local classic_oak = {
	modpath .. "/schematics/mcl_core_oak_v6.mts",
	modpath .. "/schematics/mcl_core_oak_classic.mts",
}

local fancy_oak = {
	modpath .. "/schematics/mcl_core_oak_balloon.mts",
	modpath .. "/schematics/mcl_core_oak_large_1.mts",
	modpath .. "/schematics/mcl_core_oak_large_2.mts",
	modpath .. "/schematics/mcl_core_oak_large_3.mts",
	modpath .. "/schematics/mcl_core_oak_large_4.mts",
}

local swamp_oak = {
	modpath .. "/schematics/mcl_core_oak_swamp.mts",
}

register_tree_feature ("oak", classic_oak, nil, nil, "mcl_trees:sapling_oak")
register_tree_feature ("fancy_oak", fancy_oak, nil, nil, "mcl_trees:sapling_oak")
register_tree_feature ("swamp_oak", swamp_oak, nil, nil, "mcl_trees:sapling_oak")

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
		local cid, _ = get_block (x, y + i, z)
		if cid == leaf_cid then
			set_block (x, y + i - 1, z, cid_bee_nest, 0)
			fix_lighting (x, y + i, z, x, y + i, z)
			break
		end
	end
end

register_tree_feature ("oak_with_beehive_005", classic_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.05,
}, "mcl_trees:sapling_oak")

register_tree_feature ("fancy_oak_with_beehive_005", fancy_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.05,
}, "mcl_trees:sapling_oak")

register_tree_feature ("oak_with_beehive_002", classic_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.02,
}, "mcl_trees:sapling_oak")

register_tree_feature ("fancy_oak_with_beehive_002", fancy_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.02,
}, "mcl_trees:sapling_oak")

register_tree_feature ("oak_with_beehive_0002", classic_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.002,
}, "mcl_trees:sapling_oak")

register_tree_feature ("fancy_oak_with_beehive_0002", fancy_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 0.002,
}, "mcl_trees:sapling_oak")

register_tree_feature ("fancy_oak_with_beehive", fancy_oak, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_oak"),
	beehive_probability = 1.0,
}, "mcl_trees:sapling_oak")

local birch = {
	modpath .. "/schematics/mcl_core_birch.mts",
}

local super_birch = {
	modpath .. "/schematics/mcl_core_birch_tall.mts",
}

register_tree_feature ("birch", birch, nil, nil, "mcl_trees:sapling_birch")
register_tree_feature ("super_birch", super_birch, nil, nil, "mcl_trees:sapling_birch")

register_tree_feature ("birch_with_beehive_005", birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.05,
}, "mcl_trees:sapling_birch")

register_tree_feature ("birch_with_beehive_002", birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.02,
}, "mcl_trees:sapling_birch")

register_tree_feature ("birch_with_beehive_0002", birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.002,
}, "mcl_trees:sapling_birch")

register_tree_feature ("super_birch_with_beehive_005", super_birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.05,
}, "mcl_trees:sapling_birch")

register_tree_feature ("super_birch_with_beehive_002", super_birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.02,
}, "mcl_trees:sapling_birch")

register_tree_feature ("super_birch_with_beehive_0002", super_birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 0.002,
}, "mcl_trees:sapling_birch")

register_tree_feature ("super_birch_with_beehive", super_birch, place_beehive, {
	leaf_cid = get_content_id ("mcl_trees:leaves_birch"),
	beehive_probability = 1.0,
}, "mcl_trees:sapling_birch")

local jungle = {
	modpath .. "/schematics/mcl_core_jungle_tree.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_2.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_3.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_4.mts",
}

register_tree_feature ("jungle", jungle, nil, nil, "mcl_trees:sapling_jungle",
		       0, 12, 12)

local mega_jungle = {
	modpath .. "/schematics/mcl_core_jungle_tree_huge_1.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_huge_2.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_huge_3.mts",
	modpath .. "/schematics/mcl_core_jungle_tree_huge_4.mts",
}

register_tree_feature ("mega_jungle", mega_jungle, nil, nil,
		       "mcl_trees:sapling_jungle", -1, 31, 31)

local jungle_bush = {
	modpath .. "/schematics/mcl_core_jungle_bush_oak_leaves.mts",
	modpath .. "/schematics/mcl_core_jungle_bush_oak_leaves_2.mts",
}

register_tree_feature ("jungle_bush", jungle_bush, nil, nil, "mcl_trees:sapling_oak",
		       0, 2, 2)

local acacia = {
	modpath .. "/schematics/mcl_core_acacia_1.mts",
	modpath .. "/schematics/mcl_core_acacia_2.mts",
	modpath .. "/schematics/mcl_core_acacia_3.mts",
	modpath .. "/schematics/mcl_core_acacia_4.mts",
	modpath .. "/schematics/mcl_core_acacia_5.mts",
	modpath .. "/schematics/mcl_core_acacia_6.mts",
	modpath .. "/schematics/mcl_core_acacia_7.mts",
}

register_tree_feature ("acacia", acacia, nil, nil, "mcl_trees:sapling_acacia",
		       0, 8, 8)

local cherry_blossom = core.get_modpath ("mcl_cherry_blossom")

local cherry = {
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_1.mts",
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_2.mts",
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_3.mts",
}

local cherry_with_beehive = {
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_beehive_1.mts",
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_beehive_2.mts",
	cherry_blossom .. "/schematics/mcl_cherry_blossom_tree_beehive_3.mts",
}

register_tree_feature ("cherry", cherry, nil, nil,
		       "mcl_trees:sapling_cherry_blossom", 0, 7, 9)
register_tree_feature ("cherry_with_beehive", cherry_with_beehive, nil, nil,
		       "mcl_trees:sapling_cherry_blossom", 0, 7, 9)

if mcl_levelgen.is_levelgen_environment then

for name, def in pairs (core.registered_nodes) do
	if def.groups.leaves and def.groups.biomecolor
		and def.groups.leaves > 0
		and def.groups.biomecolor > 0 then
		local cid = core.get_content_id (name)
		biomecolor_nodes[cid] = true
	end
end

local cid_spruce_sapling
	= core.get_content_id ("mcl_trees:sapling_spruce")
local cid_oak_sapling
	= core.get_content_id ("mcl_trees:sapling_oak")
local cid_birch_sapling
	= core.get_content_id ("mcl_trees:sapling_birch")

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
		build_hospitability_check (cid_spruce_sapling),
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
		build_hospitability_check (cid_oak_sapling),
	}
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_birch_and_oak", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:oak_with_beehive_0002",
	features = {
		{
			chance = 0.2,
			feature = "mcl_trees:birch_with_beehive_0002",
		},
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak_with_beehive_0002",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_birch_and_oak", {
	configured_feature = "mcl_trees:trees_birch_and_oak",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_jungle", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:jungle",
	features = {
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak",
		},
		{
			chance = 0.5,
			feature = "mcl_trees:jungle_bush",
		},
		{
			chance = 1/3,
			feature = "mcl_trees:mega_jungle",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_jungle", {
	configured_feature = "mcl_trees:trees_jungle",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			-- The correct figures would be 50 and 51,
			-- but our schematics are too tall and produce
			-- excessively dense canopies.
			{
				weight = 9,
				data = 50,
			},
			{
				weight = 1,
				data = 51,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_birch", {
	configured_feature = "mcl_trees:birch_with_beehive_0002",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
		build_hospitability_check (cid_birch_sapling),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_savanna", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:oak",
	features = {
		{
			chance = 0.8,
			feature = "mcl_trees:acacia",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_savanna", {
	configured_feature = "mcl_trees:trees_savanna",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 1,
			},
			{
				weight = 1,
				data = 2,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_flower_forest", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:oak_with_beehive_002",
	features = {
		{
			chance = 0.2,
			feature = "mcl_trees:birch_with_beehive_002",
		},
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak_with_beehive_002",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_flower_forest", {
	configured_feature = "mcl_trees:trees_flower_forest",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 6,
			},
			{
				weight = 1,
				data = 7,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_mesa", {
	configured_feature = "mcl_trees:oak",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 5,
			},
			{
				weight = 1,
				data = 6,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
		build_hospitability_check (cid_oak_sapling),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_taiga", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:spruce",
	features = {
		{
			chance = 1/3,
			feature = "mcl_trees:pine",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_taiga", {
	configured_feature = "mcl_trees:trees_taiga",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_old_growth_pine_taiga", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:spruce",
	features = {
		{
			chance = 1/39,
			feature = "mcl_trees:mega_spruce",
		},
		{
			chance = 4/13,
			feature = "mcl_trees:mega_pine",
		},
		{
			chance = 1/3,
			feature = "mcl_trees:pine",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_old_growth_pine_taiga", {
	configured_feature = "mcl_trees:trees_old_growth_pine_taiga",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_old_growth_spruce_taiga", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:spruce",
	features = {
		{
			chance = 1/3,
			feature = "mcl_trees:mega_spruce",
		},
		{
			chance = 1/3,
			feature = "mcl_trees:pine",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_old_growth_spruce_taiga", {
	configured_feature = "mcl_trees:trees_old_growth_spruce_taiga",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:birch_tall", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:birch_with_beehive_0002",
	features = {
		{
			chance = 0.5,
			feature = "mcl_trees:super_birch_with_beehive_0002",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:birch_tall", {
	configured_feature = "mcl_trees:birch_tall",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_sparse_jungle", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:jungle",
	features = {
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak",
		},
		{
			chance = 0.5,
			feature = "mcl_trees:jungle_bush",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_sparse_jungle", {
	configured_feature = "mcl_trees:trees_sparse_jungle",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 2,
			},
			{
				weight = 1,
				data = 3,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

local cid_snow = get_content_id ("mcl_core:snowblock")
local cid_powder_snow = get_content_id ("mcl_powder_snow:powder_snow")

mcl_levelgen.register_placed_feature ("mcl_trees:spruce_on_snow", {
	configured_feature = "mcl_trees:spruce",
	placement_modifiers = {
		E ({
			direction = 1,
			max_steps = 8,
			target_condition = function (x, y, z)
				return (get_block (x, y, z)) ~= cid_powder_snow
			end,
		}),
		build_node_check (cid_snow, cid_powder_snow,
				  0, -1, 0),
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:pine_on_snow", {
	configured_feature = "mcl_trees:pine",
	placement_modifiers = {
		E ({
			direction = 1,
			max_steps = 8,
			target_condition = function (x, y, z)
				return (get_block (x, y, z)) ~= cid_powder_snow
			end,
		}),
		build_node_check (cid_snow, cid_powder_snow,
				  0, -1, 0),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_grove", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:spruce_on_snow",
	features = {
		{
			chance = 1/3,
			feature = "mcl_trees:pine_on_snow",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_grove", {
	configured_feature = "mcl_trees:trees_grove",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_swamp", {
	configured_feature = "mcl_trees:swamp_oak",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 2,
			},
			{
				weight = 1,
				data = 3,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
		build_hospitability_check (cid_oak_sapling),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_windswept_hills", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:oak",
	features = {
		{
			chance = 2/3,
			feature = "mcl_trees:spruce",
		},
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_windswept_hills", {
	configured_feature = "mcl_trees:trees_windswept_hills",
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
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_windswept_forest", {
	configured_feature = "mcl_trees:trees_windswept_hills",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 3,
			},
			{
				weight = 1,
				data = 4,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_windswept_savanna", {
	configured_feature = "mcl_trees:trees_savanna",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 2,
			},
			{
				weight = 1,
				data = 3,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_water", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:oak",
	features = {
		{
			chance = 0.1,
			feature = "mcl_trees:fancy_oak",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_water", {
	configured_feature = "mcl_trees:trees_water",
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
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:trees_meadow", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:super_birch_with_beehive",
	features = {
		{
			chance = 0.5,
			feature = "mcl_trees:fancy_oak_with_beehive",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_meadow", {
	configured_feature = "mcl_trees:trees_meadow",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (100),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_configured_feature ("mcl_trees:cherry_with_beehive_005", {
	feature = "mcl_levelgen:random_selector",
	default = "mcl_trees:cherry",
	features = {
		{
			chance = 0.05,
			feature = "mcl_trees:cherry_with_beehive",
		},
	},
})

mcl_levelgen.register_placed_feature ("mcl_trees:trees_cherry", {
	configured_feature = "mcl_trees:cherry_with_beehive_005",
	placement_modifiers = {
		mcl_levelgen.build_count (W ({
			{
				weight = 9,
				data = 10,
			},
			{
				weight = 1,
				data = 11,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_water_depth_filter (0),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

end
