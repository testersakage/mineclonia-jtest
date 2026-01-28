local R = mcl_levelgen.build_random_spread_placement
local jigsaw_create_start = mcl_levelgen.jigsaw_create_start

local MINUS_FORTY = function (_) return -40 end

local function L (template, weight)
	return {
		projection = "rigid",
		template = mcl_levelgen.prefix .. "/templates/" .. template .. ".dat",
		weight = weight,
		ground_level_delta = 0,
		processors = {},
	}
end

------------------------------------------------------------------------
-- Loot tables
------------------------------------------------------------------------

if not mcl_levelgen.is_levelgen_environment then
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_chest_entrance_loot", {
		{
			stacks_min = 2,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_bows:arrow", weight = 10, amount_min = 5, amount_max = 10 },
				{ itemstring = "mcl_honey:honeycomb", weight = 10, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_tools:axe_wood", weight = 10, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:stick", weight = 5, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_vaults:trial_key", weight = 1 },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_chest_intersection_loot", {
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_amethyst:amethyst_shard", weight = 20, amount_min = 8, amount_max = 20 },
				{ itemstring = "mcl_cake:cake", weight = 20, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_core:ironblock", weight = 20, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_core:diamond", weight = 10, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_core:emeraldblock", weight = 5, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_tools:axe_diamond", weight = 5 },
				{ itemstring = "mcl_tools:pick_diamond", weight = 5 },
				{ itemstring = "mcl_core:diamondblock", weight = 1 },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_chest_supply_loot", {
		{
			stacks_min = 3,
			stacks_max = 5,
			items = {
				{ itemstring = "mcl_bows:arrow", weight = 2, amount_min = 4, amount_max = 14 },
				{ itemstring = "mcl_lush_caves:glow_berry", weight = 2, amount_min = 2, amount_max = 10 },
				{ itemstring = "mcl_farming:potato_item_baked", weight = 2, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_tools:pick_stone", weight = 2, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_deepslate:tuff", weight = 1, amount_min = 5, amount_max = 10 },
				{ itemstring = "mcl_potions:poison_arrow", weight = 1, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_potions:slowness_arrow", weight = 1, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_core:acaciawood", weight = 1, amount_min = 3, amount_max = 6 },
				{ itemstring = "mcl_torches:torch", weight = 1, amount_min = 3, amount_max = 6 },
				{ itemstring = "mcl_bone_meal:bone_meal", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_lush_caves:moss", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:regeneration", weight = 1, amount_min = 2 },
				{ itemstring = "mcl_potions:strength", weight = 1, amount_min = 2 },
				{ itemstring = "mcl_mobitems:milk_bucket", weight = 1 },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_barrel_intersection_loot", {
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_trees:wood_bamboo", weight = 10, amount_min = 5, amount_max = 15 },
				{ itemstring = "mcl_farming:potato_item_baked", weight = 10, amount_min = 6, amount_max = 10 },
				{ itemstring = "mcl_tools:axe_gold", weight = 4 },
				{ itemstring = "mcl_tools:pick_gold", weight = 4 },
				{ itemstring = "mcl_core:diamond", weight = 1, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_buckets:bucket", weight = 1, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_compass:compass", weight = 1 },
				{ itemstring = "mcl_tools:pick_diamond", weight = 1 },
				{ itemstring = "mcl_tools:axe_diamond", weight = 1, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_barrel_corridor_loot", {
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_deepslate:tuff", weight = 3, amount_min = 8, amount_max = 20 },
				{ itemstring = "mcl_bamboo:scaffolding", weight = 2, amount_min = 2, amount_max = 10 },
				{ itemstring = "mcl_trees:wood_bamboo", weight = 2, amount_min = 3, amount_max = 6 },
				{ itemstring = "mcl_torches:torch", weight = 2, amount_min = 3, amount_max = 6 },
				{ itemstring = "mcl_signs:hanging_sign_bamboo", weight = 2, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_throwing:ender_pearl", weight = 2, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_tools:axe_stone", weight = 2 },
				{ itemstring = "mcl_tools:pick_stone", weight = 2 },
				{ itemstring = "mcl_honey:honeycomb", weight = 1, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_tools:axe_iron", weight = 1, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_dispenser_chamber_loot", {
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_fire:fire_charge", weight = 6, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_throwing:snowball", weight = 6, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_bows:arrow", weight = 4, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_buckets:bucket_water", weight = 4 },
				{ itemstring = "mcl_throwing:egg", weight = 2, amount_min = 4, amount_max = 8 },
				{ itemstring = "mcl_potions:healing_lingering", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:poison_lingering", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:slowness_lingering", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:weakness_lingering", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:poison_splash", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:slowness_splash", weight = 1, amount_min = 2, amount_max = 5 },
				{ itemstring = "mcl_potions:weakness_splash", weight = 1, amount_min = 2, amount_max = 5 },
			}
		}
	})
	mcl_levelgen.register_loot_table("mcl_levelgen:trial_chambers_dispenser_corridor_loot", {
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_bows:arrow", weight = 1, amount_min = 4, amount_max = 8 }
			}
		}
	})
end

------------------------------------------------------------------------
-- Template pools
------------------------------------------------------------------------

mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_ends", {
	elements = {
		L ("trial_chambers_corridor_end_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_chambers", {
	elements = {
		L ("trial_chambers_corridor_chamber_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_hallway_1_entrances", {
	elements = {
		L ("trial_chambers_hallway_1_entrance_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_hallway_1_slices", {
	elements = {
		L ("trial_chambers_hallway_1_slice_1", 2),
		L ("trial_chambers_hallway_1_slice_2", 2),
		L ("trial_chambers_hallway_1_slice_3", 2),
		L ("trial_chambers_hallway_1_slice_4", 2),
		L ("trial_chambers_hallway_1_exit_1", 3),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_intersections", {
	elements = {
		L ("trial_chambers_corridor_intersection_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_branches", {
	elements = {
		L ("trial_chambers_branch_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_branch_lefts", {
	elements = {
		L ("trial_chambers_branch_left_1", 1),
		L ("trial_chambers_branch_left_2", 1),
		L ("trial_chambers_branch_left_3", 1),
		L ("trial_chambers_branch_left_4", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_branch_rights", {
	elements = {
		L ("trial_chambers_branch_right_1", 1),
		L ("trial_chambers_branch_right_2", 1),
		L ("trial_chambers_branch_right_3", 1),
		L ("trial_chambers_branch_right_4", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_branch_addons", {
	elements = {
		L ("trial_chambers_branch_addon_1", 1), -- with treasure
		L ("trial_chambers_branch_addon_2", 1),
		L ("trial_chambers_branch_addon_2", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_hallway_2_entrances", {
	elements = {
		L ("trial_chambers_hallway_2_entrance_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_hallway_2_slices", {
	elements = {
		L ("trial_chambers_hallway_2_slice_1", 2),
		L ("trial_chambers_hallway_2_slice_2", 2),
		L ("trial_chambers_hallway_2_slice_3", 2),
		L ("trial_chambers_hallway_2_slice_4", 2),
		L ("trial_chambers_hallway_2_exit_1",  3),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_atriums", {
	elements = {
		L ("trial_chambers_corridor_atrium_1", 1)
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_entrances", {
	elements = {
		L ("trial_chambers_corridor_entrance_1", 1)
	}
})
mcl_levelgen.register_template_pool("mcl_levelgen:trial_chambers_decor_bigs", {
	elements = {
		L ("trial_chambers_decor_big_oak_tree", 1),
		L ("trial_chambers_decor_big_fountain", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_decor_pots", {
	elements = {
		L ("trial_chambers_decor_pots_empty", 24),
		L ("trial_chambers_decor_pots_flow",   2),
		L ("trial_chambers_decor_pots_guster", 2),
		L ("trial_chambers_decor_pots_scrape", 2),
		L ("trial_chambers_decor_barrel",      1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_decor_pots_2", {
	elements = {
		L ("trial_chambers_decor_pots_flow",   1),
		L ("trial_chambers_decor_pots_guster", 1),
		L ("trial_chambers_decor_pots_scrape", 1),
	}
})
-- FIXME: Implement breeze mobs
-- mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_breeze_spawners", {
-- 	elements = {
-- 		L ("trial_chambers_spawner_breeze", 1),
-- 	}
-- })
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_melee_spawners", {
	elements = {
		L ("trial_chambers_spawner_zombie", 1),
		L ("trial_chambers_spawner_husk",   1),
		L ("trial_chambers_spawner_spider", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_small_melee_spawners", {
	elements = {
		L ("trial_chambers_spawner_slime",       1),
		L ("trial_chambers_spawner_silverfish",  1),
		L ("trial_chambers_spawner_baby_zombie", 1),
		L ("trial_chambers_spawner_cave_spider", 1),
	}
})
mcl_levelgen.register_template_pool ("mcl_levelgen:trial_chambers_ranged_spawners", {
	elements = {
		L ("trial_chambers_spawner_stray",    1),
		L ("trial_chambers_spawner_skeleton", 1),
		-- FIXME: L ("trial_chambers_spawner_bogged",   1),
	}
})

mcl_levelgen.register_structure ("mcl_levelgen:trial_chambers", {
	step = mcl_levelgen.SURFACE_STRUCTURES,
	create_start = jigsaw_create_start,
	terrain_adaptation = "none",
	biomes = mcl_levelgen.build_biome_list ({"#is_overworld",}),
	max_distance_from_center = 120,
	size = 20,
	start_height = MINUS_FORTY,
	start_pool = "mcl_levelgen:trial_chambers_ends",
})

mcl_levelgen.register_structure_set ("mcl_levelgen:trial_chambers_set", {
	structures = {
		{
			structure = "mcl_levelgen:trial_chambers",
			weight = 1,
		},
	},
	placement = R (1.0, "default", 34, 12, 94251327, "linear", nil, nil),
})
