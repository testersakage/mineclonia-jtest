mcl_vaults = {
	registered_vaults = {}
}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

dofile(modpath.."/api.lua")

mcl_vaults.register_vault("vault",{
	key = {
		name = "trial_key",
		description = S("Trial Key"),
		inventory_image = "mcl_vaults_trial_key.png",
	},
	node_off = {
		tiles = { "mcl_vaults_vault_top_off.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_off.png", "mcl_vaults_vault_side_off.png",
			"mcl_vaults_vault_side_off.png", "mcl_vaults_vault_front_off.png",
		},
	},
	node_on = {
		tiles = { "mcl_vaults_vault_top_on.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_on.png", "mcl_vaults_vault_side_on.png",
			"mcl_vaults_vault_side_on.png", "mcl_vaults_vault_front_on.png",
		},
	},
	node_ejecting = {
		tiles = { "mcl_vaults_vault_top_ejecting.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_ejecting.png", "mcl_vaults_vault_side_ejecting.png",
			"mcl_vaults_vault_side_ejecting.png", "mcl_vaults_vault_front_ejecting.png",
		},
	},
	loot ={
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_core:emerald", weight = 392, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_bows:arrow", weight = 92, amount_min = 2, amount_max = 8 },
				--{ itemstring = "TODO:arrow_of_poision", weight = 92, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_core:iron_ingot", weight = 69, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_charges:wind_charge", weight = 69, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_honey:honey_bottle", weight = 69, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:ominous_bottle", weight = 69, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_shields:shield", weight = 300, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_bows:bow", weight = 300, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_charges:wind_charge", weight = 23, amount_min = 4, amount_max = 12 },
				{ itemstring = "mcl_core:diamond", weight = 23, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_farming:carrot_item_gold", weight = 200, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_farming:carrot_item_gold", weight = 200, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)	mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)	mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_bows:crossbow", weight = 200, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_tools:axe_iron", weight = 200, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_armor:chestplate_iron", weight = 200, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_tools:axe_diamond", weight = 100, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_armor:chestplate_diamond", weight = 100, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },

			}
		},
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_core:emerald", weight = 4, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_bows:arrow", weight = 4, amount_min = 2, amount_max = 8 },
				--{ itemstring = "TODO:arrow_of_poision", weight = 4, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_core:iron_ingot", weight = 3, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_charges:wind_charge", weight = 3, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_honey:honey_bottle", weight = 3, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:ominous_bottle", weight = 2, amount_min = 1, amount_max = 2 },
				{ itemstring = "mcl_charges:wind_charge", weight = 1, amount_min = 4, amount_max = 12 },
				{ itemstring = "mcl_core:diamond", weight = 1, amount_min = 1, amount_max = 2 },
			},
		},
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_core:apple_gold", weight = 4, amount_min = 1, amount_max = 2 },
				--{ itemstring = "TODO:mcl_armor:bolt", weight = 3, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_jukebox:record_8", weight = 2 },
				--{ itemstring = "TODO:mcl_banners:pattern_guster", weight = 2 },
				--{ itemstring = "TODO:tridentr", weight = 1 },
			}
		}
}
})

mcl_vaults.register_vault("ominous_vault",{
	key = {
		name = "ominous_trial_key",
		description = S("Ominous Trial Key"),
		inventory_image = "mcl_vaults_ominous_trial_key.png",
	},
	node_off = {
		description = S("Ominous Vault"),
		tiles = { "mcl_vaults_vault_ominous_top_off.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_ominous_side_off.png", "mcl_vaults_vault_ominous_side_off.png",
			"mcl_vaults_vault_ominous_side_off.png", "mcl_vaults_vault_ominous_front_off.png",
		},
	},
	node_on = {
		tiles = { "mcl_vaults_vault_ominous_top_on.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_ominous_side_on.png", "mcl_vaults_vault_ominous_side_on.png",
			"mcl_vaults_vault_ominous_side_on.png", "mcl_vaults_vault_ominous_front_on.png",
		},
	},
	node_ejecting = {
		tiles = { "mcl_vaults_vault_ominous_top_ejecting.png", "mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_ominous_side_ejecting.png", "mcl_vaults_vault_ominous_side_ejecting.png",
			"mcl_vaults_vault_ominous_side_ejecting.png", "mcl_vaults_vault_ominous_front_ejecting.png",
		},
	},
	loot ={
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_core:emerald", weight = 145, amount_min = 4, amount_max = 10 },
				{ itemstring = "mcl_charges:wind_charge", weight = 116, amount_min = 8, amount_max = 12 },
				--{ itemstring = "TODO mcl_potions:arrow_of_slowness", weight = 87, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_core:diamond", weight = 58, amount_min = 2, amount_max = 3 },
				--{ itemstring = "TODO:ominous_bottle", weight = 29, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:emeraldblock", weight = 300, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_bows:crossbow", weight = 240, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_core:ironblock", weight = 240, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:apple_gold", weight = 180, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_tools:axe_diamond", weight = 180, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_armor:chestplate_diamond", weight = 180, func = function(stack, pr) mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_books:book", weight = 120, func = function(stack, pr)	mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_books:book", weight = 120, func = function(stack, pr)	mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_books:book", weight = 120, func = function(stack, pr)	mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_core:diamondblock", weight = 60, amount_min = 1, amount_max = 1 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_core:emerald", weight = 145, amount_min = 4, amount_max = 10 },
				{ itemstring = "mcl_charges:wind_charge", weight = 116, amount_min = 8, amount_max = 12 },
				--{ itemstring = "TODO mcl_potions:arrow_of_slowness", weight = 87, amount_min = 2, amount_max = 8 },
				{ itemstring = "mcl_core:diamond", weight = 58, amount_min = 2, amount_max = 3 },
				--{ itemstring = "TODO:ominous_bottle", weight = 29, amount_min = 1, amount_max = 1 },
			},
		},
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_armor:flow", weight = 9, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:apple_gold_enchanted", weight = 9, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_banners:pattern_flow", weight = 6, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_jukebox:record_7", weight = 6 },
				{ itemstring = "mcl_tools:heavy_core", weight = 9, amount_min = 1, amount_max = 1 },
			}
		}
}
})
