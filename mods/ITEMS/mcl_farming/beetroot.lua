local S = core.get_translator(core.get_current_modname())
-- Beetroot crops
mcl_farming.register_simple_crop("beetroot", {
	bone_meal_chance = 0.75,
	bone_meal_stages = 1,
	chance = 3,
	fortune_drop = {
		cap = 5,
		discrete_uniform_distribution = true,
		drop_without_fortune = {"mcl_farming:beetroot_item"},
		items = {"mcl_farming:beetroot_seeds"},
		max_count = 3,
		min_count = 1
	},
	initial_stage_zero = true,
	interval = 68,
	mature_desc = S("Mature Beetroot Plant"),
	mature_drop = {
		items = {
			{items = {"mcl_farming:beetroot_item"}},
			{items = {"mcl_farming:beetroot_seeds"}, rarity = 12},
			{items = {"mcl_farming:beetroot_seeds 2"}, rarity = 3},
			{items = {"mcl_farming:beetroot_seeds 3"}, rarity = 2},
			{items = {"mcl_farming:beetroot_seeds 4"}, rarity = 5}
		},
		max_items = 2
	},
	mature_longdesc = S("A mature beetroot plant is a farming plant which is ready to be harvested for a beetroot and some beetroot seeds. It won't grow any further."),
	premature_desc = S("Premature Beetroot Plant"),
	premature_longdesc = S("Beetroot plants are plants which grow on farmland under sunlight in 4 stages. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature."),
	seed = "mcl_farming:beetroot_seeds",
	sel_heights = {-0.375, -0.1875, -0.125, 0},
	sel_widths = {0.3125, 0.375, 0.4375, 0.5},
	stages = 4,
	textures = {
		"mcl_farming_beetroot_0.png", "mcl_farming_beetroot_1.png",
		"mcl_farming_beetroot_2.png", "mcl_farming_beetroot_3.png"
	}
})
-- Craftitems
core.register_craftitem("mcl_farming:beetroot_seeds", {
	_doc_items_longdesc = S("Grows into a beetroot plant. Chickens like beetroot seeds."),
	_doc_items_usagehelp = S("Place the beetroot seeds on farmland (which can be created with a hoe) to plant a beetroot plant. They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it beetroot seeds."),
	_mcl_places_plant = "mcl_farming:beetroot_0",
	_tt_help = S("Grows on farmland"),
	description = S("Beetroot Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_beetroot_seeds.png",
	on_place = mcl_farming.place_crop,
	wield_image = "mcl_farming_beetroot_seeds.png"
})

core.register_craftitem("mcl_farming:beetroot_item", {
	_doc_items_longdesc = S("Beetroots are both used as food item and a dye ingredient. Pigs like beetroots, too."),
	_doc_items_usagehelp = S("Hold it in your hand and right-click to eat it. Rightclick an animal to feed it."),
	_mcl_crafting_output = {single = {output = "mcl_dyes:red"}},
	_mcl_saturation = 1.2,
	description = S("Beetroot"),
	groups = {compostability = 65, eatable = 1, food = 2},
	inventory_image = "mcl_farming_beetroot.png",
	on_place = core.item_eat(1),
	on_secondary_use = core.item_eat(1),
	wield_image = "mcl_farming_beetroot.png"
})

core.register_craftitem("mcl_farming:beetroot_soup", {
	_doc_items_longdesc = S("Beetroot soup is a food item."),
	_mcl_saturation = 7.2,
	description = S("Beetroot Soup"),
	groups = {eatable = 6, food = 3},
	inventory_image = "mcl_farming_beetroot_soup.png",
	on_place = core.item_eat(6, "mcl_core:bowl"),
	on_secondary_use = core.item_eat(6, "mcl_core:bowl"),
	stack_max = 1,
	wield_image = "mcl_farming_beetroot_soup.png"
})
-- Recipes
core.register_craft({
	output = "mcl_farming:beetroot_soup",
	recipe = {
		{"mcl_farming:beetroot_item", "mcl_farming:beetroot_item", "mcl_farming:beetroot_item"},
		{"mcl_farming:beetroot_item", "mcl_farming:beetroot_item", "mcl_farming:beetroot_item"},
		{"", "mcl_core:bowl", ""}
	}
})

core.register_alias("beetroot_seeds", "mcl_farming:beetroot_seeds")
core.register_alias("beetroot", "mcl_farming:beetroot_item")
