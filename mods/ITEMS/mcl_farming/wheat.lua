local S = core.get_translator(core.get_current_modname())
local mod_screwdriver = core.get_modpath("screwdriver")
-- Wheat crops
mcl_farming.register_simple_crop("wheat", {
	fortune_drop = {
		cap = 7,
		discrete_uniform_distribution = true,
		drop_without_fortune = {"mcl_farming:wheat_item"},
		items = {"mcl_farming:wheat_seeds"},
		max_count = 6,
		min_count = 1
	},
	mature_desc = S("Mature Wheat Plant"),
	mature_drop = {
		items = {
			{items = {"mcl_farming:wheat_item"}},
			{items = {"mcl_farming:wheat_seeds"}, rarity = 12},
			{items = {"mcl_farming:wheat_seeds 2"}, rarity = 3},
			{items = {"mcl_farming:wheat_seeds 3"}, rarity = 2},
			{items = {"mcl_farming:wheat_seeds 4"}, rarity = 5}
		},
		max_items = 2
	},
	mature_longdesc = S("Mature wheat plants are ready to be harvested for wheat and wheat seeds. They won't grow any further."),
	premature_desc = S("Premature Wheat Plant"),
	premature_longdesc = S("Premature wheat plants grow on farmland under sunlight in 8 stages. On hydrated farmland, they grow faster. They can be harvested at any time but will only yield a profit when mature."),
	seed = "mcl_farming:wheat_seeds",
	sel_heights = {-0.1875, 0, 0.125, 0.25, 0.3125, 0.375, 0.4375, 0.5},
	sel_widths = {["1, 2, 3, 4, 5, 6, 7"] = 0.4375, ["8"] = 0.5},
	stages = 8,
	textures = {
		"mcl_farming_wheat_stage_0.png", "mcl_farming_wheat_stage_1.png",
		"mcl_farming_wheat_stage_2.png", "mcl_farming_wheat_stage_3.png",
		"mcl_farming_wheat_stage_4.png", "mcl_farming_wheat_stage_5.png",
		"mcl_farming_wheat_stage_6.png", "mcl_farming_wheat_stage_7.png"
	}
}, {
	_on_bone_meal = function(_, _, _, pos, node)
		return mcl_farming.on_bone_meal(_,_,_, pos, node, "plant_wheat")
	end
})
-- Craftitems
core.register_craftitem("mcl_farming:bread", {
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	_mcl_saturation = 6.0,
	description = S("Bread"),
	groups = {compostability = 85, eatable = 5, food = 2},
	inventory_image = "farming_bread.png",
	on_place = core.item_eat(5),
	on_secondary_use = core.item_eat(5),
	wield_image = "farming_bread.png"
})

core.register_craftitem("mcl_farming:cookie", {
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	_mcl_saturation = 0.4,
	description = S("Cookie"),
	groups = {compostability = 85, eatable = 2, food = 2},
	inventory_image = "farming_cookie.png",
	on_place = core.item_eat(2),
	on_secondary_use = core.item_eat(2),
	wield_image = "farming_cookie.png"
})

core.register_craftitem("mcl_farming:wheat_item", {
	_doc_items_longdesc = S("Wheat is used in crafting. Some animals like wheat."),
	_doc_items_usagehelp = S("Use the “Place” key on an animal to try to feed it wheat."),
	_mcl_crafting_output = {
		line_wide3 = {output = "mcl_farming:bread 3"},
		square3 = {output = "mcl_farming:hay_block"}
	},
	description = S("Wheat"),
	groups = {compostability = 65, craftitem = 1},
	inventory_image = "farming_wheat_harvested.png",
	wield_image = "farming_wheat_harvested.png"
})

core.register_craftitem("mcl_farming:wheat_seeds", {
	_doc_items_longdesc = S("Grows into a wheat plant. Chickens like wheat seeds."),
	_doc_items_usagehelp = S("Place the wheat seeds on farmland (which can be created with a hoe) to plant a wheat plant. They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it wheat seeds."),
	_mcl_places_plant = "mcl_farming:wheat_1",
	_tt_help = S("Grows on farmland"),
	description = S("Wheat Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_wheat_seeds.png",
	on_place = mcl_farming.place_plant,
	wield_image = "mcl_farming_wheat_seeds.png"
})
-- Recipes
core.register_craft({
	output = "mcl_farming:cookie 8",
	recipe = {{"mcl_farming:wheat_item", "mcl_cocoas:cocoa_beans", "mcl_farming:wheat_item"}}
})
-- Hay Bale
core.register_node("mcl_farming:hay_block", {
	_doc_items_longdesc = S("Hay bales are decorative blocks made from wheat."),
	_mcl_blast_resistance = 0.5,
	_mcl_crafting_output = {single = {output = "mcl_farming:wheat_item 9"}},
	_mcl_hardness = 0.5,
	description = S("Hay Bale"),
	groups = {
		building_block = 1, compostability = 85, fall_damage_add_percent = -80,
		fire_encouragement = 60, fire_flammability = 20, flammable = 2, handy = 1, hoey = 1
	},
	is_ground_content = false,
	on_place = mcl_util.rotate_axis,
	on_rotate = mod_screwdriver and screwdriver.rotate_3way,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	tiles = {
		"mcl_farming_hayblock_top.png",
		"mcl_farming_hayblock_top.png",
		"mcl_farming_hayblock_side.png"
	}
})

mcl_farming:add_plant("plant_wheat", "mcl_farming:wheat", {"mcl_farming:wheat_1", "mcl_farming:wheat_2", "mcl_farming:wheat_3", "mcl_farming:wheat_4", "mcl_farming:wheat_5", "mcl_farming:wheat_6", "mcl_farming:wheat_7"}, 25, 20)
