local S = core.get_translator(core.get_current_modname())
local mod_screwdriver = core.get_modpath("screwdriver")
-- Pumpkin stems
mcl_farming.register_stems("pumpkintige", {
	connected_stem_texture = "mcl_farming_pumpkin_stem_connected.png",
	gourd = "mcl_farming:pumpkin",
	mature_desc = S("Mature Pumpkin Stem"),
	mature_longdesc = S("A mature pumpkin stem attempts to grow a pumpkin at one of its four adjacent blocks. A pumpkin can only grow on top of farmland, dirt or a grass block. When a pumpkin is next to a pumpkin stem, the pumpkin stem immediately bends and connects to the pumpkin. A connected pumpkin stem can't grow another pumpkin. As soon all pumpkins around the stem have been removed, it loses the connection and is ready to grow another pumpkin."),
	premature_desc = S("Premature Pumpkin Stem"),
	premature_longdesc = S("Pumpkin stems grow on farmland in 8 stages. On hydrated farmland, the growth is a bit quicker. Mature pumpkin stems are able to grow pumpkins."),
	seed = "mcl_farming:pumpkin_seeds",
	texture = "mcl_farming_pumpkin_stem_disconnected.png"
})
-- Pumpkin
core.register_node("mcl_farming:pumpkin", {
	_doc_items_longdesc = S("A pumpkin is a decorative block. It can be carved with shears to obtain pumpkin seeds."),
	_doc_items_usagehelp = S("To carve a face into the pumpkin, use the shears on the side you want to carve."),
	_mcl_blast_resistance = 1,
	_mcl_crafting_output = {single = {output = "mcl_farming:pumpkin_seeds 4"}},
	_mcl_hardness = 1,
	_on_shears_place = mcl_farming.carve_pumpkin,
	description = S("Pumpkin"),
	groups = {
		axey = 1, building_block = 1, compostability = 65, dig_by_piston = 1,
		enderman_takable = 1, handy = 1, plant = 1, pumpkin = 1, unsticky = 1
	},
	on_rotate = mod_screwdriver and screwdriver.rotate_simple,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_wood_defaults(),
	tiles = {"farming_pumpkin_top.png", "farming_pumpkin_top.png", "farming_pumpkin_side.png"}
})

core.register_node("mcl_farming:pumpkin_face", {
	_doc_items_longdesc = S("A carved pumpkin can be worn as a helmet. Pumpkins grow from pumpkin stems, which in turn grow from pumpkin seeds."),
	_mcl_armor_element = "head",
	_mcl_armor_mob_range_factor = 0,
	_mcl_armor_mob_range_mob = "mobs_mc:enderman",
	_mcl_armor_texture = "mcl_farming_pumpkin_face.png",
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
	_on_equip = mcl_farming.add_pumpkin_hud,
	_on_unequip = mcl_farming.remove_pumpkin_hud,
	after_place_node = function(pos, placer)
		mobs_mc.check_iron_golem_summon(pos, placer)
		mobs_mc.check_snow_golem_summon(pos, placer)
	end,
	description = S("Carved Pumpkin"),
	groups = {
		armor = 1, armor_head = 1, axey = 1, building_block = 1, compostability = 65,
		dig_by_piston = 1, enderman_takable = 1, handy = 1, non_combat_armor = 1,
		non_combat_armor_head = 1, plant = 1, pumpkin = 1, unsticky = 1
	},
	on_rotate = mod_screwdriver and screwdriver.rotate_simple,
	on_secondary_use = mcl_armor.equip_on_use,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_wood_defaults(),
	tiles = {
		"farming_pumpkin_top.png", "farming_pumpkin_top.png",
		"farming_pumpkin_side.png", "farming_pumpkin_side.png",
		"farming_pumpkin_side.png", "farming_pumpkin_face.png"
	}
})

core.register_node("mcl_farming:pumpkin_face_light", {
	_doc_items_longdesc = S("A jack o'lantern is a traditional Halloween decoration made from a pumpkin. It glows brightly."),
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
	after_place_node = function(pos, placer)
		mobs_mc.check_iron_golem_summon(pos, placer)
		mobs_mc.check_snow_golem_summon(pos, placer)
	end,
	description = S("Jack o'Lantern"),
	groups = {
		axey = 1, building_block = 1, dig_by_piston = 1, handy = 1, pumpkin = 1, unsticky = 1
	},
	is_ground_content = false,
	light_source = core.LIGHT_MAX,
	on_rotate = mod_screwdriver and screwdriver.rotate_simple,
	paramtype = "light",
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_wood_defaults(),
	tiles = {
		"farming_pumpkin_top.png", "farming_pumpkin_top.png",
		"farming_pumpkin_side.png", "farming_pumpkin_side.png",
		"farming_pumpkin_side.png", "farming_pumpkin_face_light.png"
	}
})
--Craftitems
core.register_craftitem("mcl_farming:pumpkin_pie", {
	_doc_items_longdesc = S("A pumpkin pie is a tasty food item which can be eaten."),
	_mcl_saturation = 4.8,
	description = S("Pumpkin Pie"),
	groups = {compostability = 100, eatable = 8, food = 2},
	inventory_image = "mcl_farming_pumpkin_pie.png",
	on_place = core.item_eat(8),
	on_secondary_use = core.item_eat(8),
	wield_image = "mcl_farming_pumpkin_pie.png"
})

core.register_craftitem("mcl_farming:pumpkin_seeds", {
	_doc_items_longdesc = S("Grows into a pumpkin stem which in turn grows pumpkins. Chickens like pumpkin seeds."),
	_doc_items_usagehelp = S("Place the pumpkin seeds on farmland (which can be created with a hoe) to plant a pumpkin stem. Pumpkin stems grow in sunlight and grow faster on hydrated farmland. When mature, the stem attempts to grow a pumpkin next to it. Rightclick an animal to feed it pumpkin seeds."),
	_mcl_places_plant = "mcl_farming:pumpkintige_1",
	_tt_help = S("Grows on farmland"),
	description = S("Pumpkin Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_pumpkin_seeds.png",
	on_place = mcl_farming.place_plant,
	wield_image = "mcl_farming_pumpkin_seeds.png"
})
-- Crafting
core.register_craft({
	output = "mcl_farming:pumpkin_face_light",
	recipe = {{"mcl_farming:pumpkin_face"}, {"mcl_torches:torch"}}
})

core.register_craft({
	output = "mcl_farming:pumpkin_pie",
	recipe = {"mcl_farming:pumpkin", "mcl_core:sugar", "mcl_throwing:egg"},
	type = "shapeless"
})

core.register_on_joinplayer(function(player)
	if player:get_inventory():get_stack("armor", 2):get_name() == "mcl_farming:pumpkin_face" then
		mcl_farming.add_pumpkin_hud(player)
	end
end)

core.register_on_dieplayer(function(player)
	if not core.settings:get_bool("mcl_keepInventory") then
		mcl_farming.remove_pumpkin_hud(player)
	end
end)

core.register_on_leaveplayer(function(player)
	mcl_farming.pumpkin_hud[player] = nil
end)
-- Register stem growth
mcl_farming:add_plant("plant_pumpkin_stem", "mcl_farming:pumpkintige_unconnect", {"mcl_farming:pumpkin_1", "mcl_farming:pumpkin_2", "mcl_farming:pumpkin_3", "mcl_farming:pumpkin_4", "mcl_farming:pumpkin_5", "mcl_farming:pumpkin_6", "mcl_farming:pumpkin_7"}, 30, 5)
