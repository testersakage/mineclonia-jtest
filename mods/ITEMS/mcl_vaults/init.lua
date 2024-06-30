mcl_vaults = {
	registered_vaults = {}
}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
--local S = minetest.get_translator(modname)

dofile(modpath.."/api.lua")

mcl_vaults.register_vault("vault",{
	key = "mcl_vaults:trial_key",
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
