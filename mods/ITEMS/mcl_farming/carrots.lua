local S = core.get_translator(core.get_current_modname())
-- Carrot crops
mcl_farming.register_simple_crop("carrot", {
	fortune_drop = {
		cap = 5,
		discrete_uniform_distribution = true,
		items = {"mcl_farming:carrot_item"},
		max_count = 4,
		min_count = 2
	},
	mature_desc = S("Mature Carrot Plant"),
	mature_drop = {
		items = {
			{items = {"mcl_farming:carrot_item 2"}, rarity = 12},
			{items = {"mcl_farming:carrot_item 3"}, rarity = 3},
			{items = {"mcl_farming:carrot_item 4"}, rarity = 2},
			{items = {"mcl_farming:carrot_item 5"}, rarity = 5}
		},
		max_items = 1
	},
	mature_longdesc = S("Mature carrot plants are ready to be harvested for carrots. They won't grow any further."),
	premature_desc = S("Premature Carrot Plant"),
	premature_longdesc = S("Carrot plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature."),
	seed = "mcl_farming:carrot_item",
	sel_heights = {["1, 2"] = -0.375, ["3, 4"] = -0.25, ["5, 6, 7"] = -0.125, ["8"] = 0},
	single_sel_width = 0.4375,
	stages = 8,
	textures = {
		["1, 2"] = "farming_carrot_1.png", ["3, 4"] = "farming_carrot_2.png",
		["5, 6, 7"] = "farming_carrot_3.png", ["8"] = "farming_carrot_4.png"
	}
})
-- Craftitems
core.register_craftitem("mcl_farming:carrot_item", {
	_doc_items_longdesc = S("Carrots can be eaten and planted. Pigs and rabbits like carrots."),
	_doc_items_usagehelp = S("Hold it in your hand and rightclick to eat it. Place it on top of farmland to plant the carrot. It grows in sunlight and grows faster on hydrated farmland. Rightclick an animal to feed it."),
	_mcl_places_plant = "mcl_farming:carrot_1",
	_mcl_saturation = 3.6,
	_tt_help = S("Grows on farmland"),
	description = S("Carrot"),
	groups = {compostability = 65, eatable = 3, food = 2},
	inventory_image = "farming_carrot.png",
	on_place = mcl_farming.place_plant,
	on_secondary_use = core.item_eat(3),
	wield_image = "farming_carrot.png"
})

core.register_craftitem("mcl_farming:carrot_item_gold", {
	_doc_items_longdesc = S("A golden carrot is a precious food item which can be eaten. It is really, really filling!"),
	_mcl_saturation = 14.4,
	description = S("Golden Carrot"),
	groups = {brewitem = 1, eatable = 6, food = 2},
	inventory_image = "farming_carrot_gold.png",
	on_place = core.item_eat(6),
	on_secondary_use = core.item_eat(6),
	wield_image = "farming_carrot_gold.png"
})
-- Recipes
core.register_craft({
	output = "mcl_farming:carrot_item_gold",
	recipe = {
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_farming:carrot_item", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"}
	}
})

mcl_farming:add_plant("plant_carrot", "mcl_farming:carrot", {"mcl_farming:carrot_1", "mcl_farming:carrot_2", "mcl_farming:carrot_3", "mcl_farming:carrot_4", "mcl_farming:carrot_5", "mcl_farming:carrot_6", "mcl_farming:carrot_7"}, 25, 20)
