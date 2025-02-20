local S = minetest.get_translator(minetest.get_current_modname())
-- Beetroot crops
mcl_farming.register_simple_crop("beetroot", {
	fortune_drop = {
		cap = 5,
		discrete_uniform_distribution = true,
		drop_without_fortune = {"mcl_farming:beetroot_item"},
		items = {"mcl_farming:beetroot_seeds"},
		max_count = 3,
		min_count = 1
	},
	initial_stage_zero = true,
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
minetest.register_craftitem("mcl_farming:beetroot_seeds", {
	description = S("Beetroot Seeds"),
	_tt_help = S("Grows on farmland"),
	_doc_items_longdesc = S("Grows into a beetroot plant. Chickens like beetroot seeds."),
	_doc_items_usagehelp = S("Place the beetroot seeds on farmland (which can be created with a hoe) to plant a beetroot plant. They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it beetroot seeds."),
	groups = {craftitem = 1, compostability = 30},
	inventory_image = "mcl_farming_beetroot_seeds.png",
	wield_image = "mcl_farming_beetroot_seeds.png",
	_mcl_places_plant = "mcl_farming:beetroot_1",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:beetroot_0")
	end
})

minetest.register_craftitem("mcl_farming:beetroot_item", {
	description = S("Beetroot"),
	_doc_items_longdesc = S("Beetroots are both used as food item and a dye ingredient. Pigs like beetroots, too."),
	_doc_items_usagehelp = S("Hold it in your hand and right-click to eat it. Rightclick an animal to feed it."),
	inventory_image = "mcl_farming_beetroot.png",
	wield_image = "mcl_farming_beetroot.png",
	on_place = minetest.item_eat(1),
	on_secondary_use = minetest.item_eat(1),
	groups = {food = 2, eatable = 1, compostability = 65},
	_mcl_saturation = 1.2,
	_mcl_crafting_output = {single = {output = "mcl_dyes:red"}}
})

minetest.register_craftitem("mcl_farming:beetroot_soup", {
	description = S("Beetroot Soup"),
	_doc_items_longdesc = S("Beetroot soup is a food item."),
	stack_max = 1,
	inventory_image = "mcl_farming_beetroot_soup.png",
	wield_image = "mcl_farming_beetroot_soup.png",
	on_place = minetest.item_eat(6, "mcl_core:bowl"),
	on_secondary_use = minetest.item_eat(6, "mcl_core:bowl"),
	groups = { food = 3, eatable = 6 },
	_mcl_saturation = 7.2,
})

minetest.register_craft({
	output = "mcl_farming:beetroot_soup",
	recipe = {
		{ "mcl_farming:beetroot_item","mcl_farming:beetroot_item","mcl_farming:beetroot_item", },
		{ "mcl_farming:beetroot_item","mcl_farming:beetroot_item","mcl_farming:beetroot_item", },
		{ "", "mcl_core:bowl", "" },
	},
})

mcl_farming:add_plant("plant_beetroot", "mcl_farming:beetroot", {"mcl_farming:beetroot_0", "mcl_farming:beetroot_1", "mcl_farming:beetroot_2"}, 68, 3)

minetest.register_alias("beetroot_seeds", "mcl_farming:beetroot_seeds")
minetest.register_alias("beetroot", "mcl_farming:beetroot_item")
