mcl_vaults = {}
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

local function can_open(pos, player)
	return true
end

local function eject_items(pos, name, list)
	if not list or #list == 0 then
		local node = minetest.get_node(pos)
		node.name = "mcl_vaults:"..name
		minetest.swap_node(pos, node)
		return
	end
	minetest.add_item(vector.offset(pos, 0, 0.5, 0), table.remove(list))
	minetest.after(0.5, eject_items, pos, name, list)
end

minetest.register_craftitem("mcl_vaults:trial_key", {
	inventory_image = "mcl_vaults_trial_key.png",
})

local tpl = {
	drawtype = "allfaces_optional",
	paramtype = "light",
	description = S("Vault"),
	_tt_help = S("Ejects loot when opened with the key"),
	_doc_items_longdesc = S("A vault ejects loot when opened with the right key. It can only be opnend once by each player."),
	_doc_items_usagehelp = S("A vault ejects loot when opened with the right key. It can only be opnend once by each player."),
	groups = {pickaxey=1, material_stone=1, deco_block=1},
	is_ground_content = false,
	drop = "",
	_mcl_hardness = 30,
	_mcl_blast_resitance = 50,
}

function mcl_vaults.register_vault(name, def)
	minetest.register_node("mcl_vaults:"..name, table.merge(tpl, {

	}, def.node_off))
	minetest.register_node("mcl_vaults:"..name.."_ejecting", table.merge(tpl, {
	}, def.node_ejecting))

	minetest.register_node("mcl_vaults:"..name.."_on", table.merge(tpl, {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack:get_name() == "mcl_vaults:trial_key" and can_open(pos, clicker) then
				eject_items(pos, name, mcl_loot.get_multi_loot(def.loot, PseudoRandom(os.time())))
				node.name = "mcl_vaults:"..name.."_ejecting"
				minetest.swap_node(pos, node)
				if not minetest.is_creative_enabled(clicker:get_player_name()) then
					itemstack:take_item()
				end
				return itemstack
			end
		end
	}, def.node_on))
end

mcl_vaults.register_vault("vault",{
	node_off = {
		tiles = {
			"mcl_vaults_vault_top_off.png",
			"mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_off.png",
			"mcl_vaults_vault_side_off.png",
			"mcl_vaults_vault_side_off.png",
			"mcl_vaults_vault_front_off.png",
		},
	},
	node_on = {
		tiles = {
			"mcl_vaults_vault_top_on.png",
			"mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_on.png",
			"mcl_vaults_vault_side_on.png",
			"mcl_vaults_vault_side_on.png",
			"mcl_vaults_vault_front_on.png",
		},
	},
	node_ejecting = {
		tiles = {
			"mcl_vaults_vault_top_ejecting.png",
			"mcl_vaults_vault_bottom.png",
			"mcl_vaults_vault_side_ejecting.png",
			"mcl_vaults_vault_side_ejecting.png",
			"mcl_vaults_vault_side_ejecting.png",
			"mcl_vaults_vault_front_ejecting.png",
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
				{ itemstring = "mcl_core:diamond", weight = 23, amount_min = 4, amount_max = 2 },
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
