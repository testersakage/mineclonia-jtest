local S = minetest.get_translator(minetest.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_wheat")
end

mcl_farming.register_crop("wheat", {
	stages = 8,
	descriptions = {
		"Premature Wheat Plant (Stage @1)",
		"Mature Wheat Plant"
	},
	premature_longdesc = S("Premature wheat plants grow on farmland under sunlight in 8 stages. On hydrated farmland, they grow faster. They can be harvested at any time but will only yield a profit when mature."),
	entry_name = S("Premature Wheat Plant"),
	mature_longdesc = S("Mature wheat plants are ready to be harvested for wheat and wheat seeds. They won't grow any further."),
	on_bone_meal = on_bone_meal,
	seed = "mcl_farming:wheat_seeds",
	full_grow_drop = {
		max_items = 4,
		items = {
			{ items = {"mcl_farming:wheat_seeds"} },
			{ items = {"mcl_farming:wheat_seeds"}, rarity = 2},
			{ items = {"mcl_farming:wheat_seeds"}, rarity = 5},
			{ items = {"mcl_farming:wheat_item"} }
		}
	},
	fortune_drop = {
		discrete_uniform_distribution = true,
		items = {"mcl_farming:wheat_seeds"},
		drop_without_fortune = {"mcl_farming:wheat_item"},
		min_count = 1,
		max_count = 6,
		cap = 7
	},
	boxes = {
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.4375, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.4375, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.375, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.3125, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.25, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.1875, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.125, 0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, 0, 0.4375},
	},
	tiles = {
		"mcl_farming_wheat_stage_0.png",
		"mcl_farming_wheat_stage_1.png",
		"mcl_farming_wheat_stage_2.png",
		"mcl_farming_wheat_stage_3.png",
		"mcl_farming_wheat_stage_4.png",
		"mcl_farming_wheat_stage_5.png",
		"mcl_farming_wheat_stage_6.png",
		"mcl_farming_wheat_stage_7.png",
	}
})

minetest.register_craftitem("mcl_farming:wheat_seeds", {
	description = S("Wheat Seeds"),
	_tt_help = S("Grows on farmland"),
	_doc_items_longdesc = S("Grows into a wheat plant. Chickens like wheat seeds."),
	_doc_items_usagehelp = S([[
		Place the wheat seeds on farmland (which can be created with a hoe) to plant a wheat plant.
		They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it wheat seeds.
	]]),
	groups = {craftitem = 1, compostability = 30},
	inventory_image = "mcl_farming_wheat_seeds.png",
	_mcl_places_plant = "mcl_farming:wheat_1",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:wheat_1")
	end
})

minetest.register_craftitem("mcl_farming:wheat_item", {
	description = S("Wheat"),
	_doc_items_longdesc = S("Wheat is used in crafting. Some animals like wheat."),
	_doc_items_usagehelp = S("Use the “Place” key on an animal to try to feed it wheat."),
	inventory_image = "farming_wheat_harvested.png",
	groups = {craftitem = 1, compostability = 65},
})

minetest.register_craftitem("mcl_farming:bread", {
	description = S("Bread"),
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	inventory_image = "farming_bread.png",
	groups = {food = 2, eatable = 5, compostability = 85},
	_mcl_saturation = 6.0,
	on_place = minetest.item_eat(5),
	on_secondary_use = minetest.item_eat(5),
})

minetest.register_craft({
	output = "mcl_farming:bread",
	recipe = {
		{"mcl_farming:wheat_item", "mcl_farming:wheat_item", "mcl_farming:wheat_item"},
	}
})

minetest.register_craftitem("mcl_farming:cookie", {
	description = S("Cookie"),
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	inventory_image = "farming_cookie.png",
	groups = {food = 2, eatable = 2, compostability = 85},
	_mcl_saturation = 0.4,
	on_place = minetest.item_eat(2),
	on_secondary_use = minetest.item_eat(2),
})

minetest.register_craft({
	output = "mcl_farming:cookie 8",
	recipe = {
		{"mcl_farming:wheat_item", "mcl_cocoas:cocoa_beans", "mcl_farming:wheat_item"},
	}
})

local mod_screwdriver = minetest.get_modpath("screwdriver")
local on_rotate
if mod_screwdriver then
	on_rotate = screwdriver.rotate_3way
end

minetest.register_node("mcl_farming:hay_block", {
	description = S("Hay Bale"),
	_doc_items_longdesc = S("Hay bales are decorative blocks made from wheat."),
	tiles = {"mcl_farming_hayblock_top.png", "mcl_farming_hayblock_top.png", "mcl_farming_hayblock_side.png"},
	is_ground_content = false,
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	groups = {
		handy = 1, hoey = 1, building_block = 1, fall_damage_add_percent = -80,
		flammable = 2, fire_encouragement = 60, fire_flammability = 20,
		compostability = 85
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	on_rotate = on_rotate,
	_mcl_blast_resistance = 0.5,
	_mcl_hardness = 0.5,
})

minetest.register_craft({
	output = "mcl_farming:hay_block",
	recipe = {
		{"mcl_farming:wheat_item", "mcl_farming:wheat_item", "mcl_farming:wheat_item"},
		{"mcl_farming:wheat_item", "mcl_farming:wheat_item", "mcl_farming:wheat_item"},
		{"mcl_farming:wheat_item", "mcl_farming:wheat_item", "mcl_farming:wheat_item"},
	}
})

minetest.register_craft({
	output = "mcl_farming:wheat_item 9",
	recipe = {
		{"mcl_farming:hay_block"},
	}
})

mcl_farming:add_plant("plant_wheat", "mcl_farming:wheat", {"mcl_farming:wheat_0", "mcl_farming:wheat_1", "mcl_farming:wheat_2", "mcl_farming:wheat_3", "mcl_farming:wheat_4", "mcl_farming:wheat_5", "mcl_farming:wheat_6"}, 25, 20)
