local S = minetest.get_translator(minetest.get_current_modname())
-- Melon stems
mcl_farming.register_stems("melontige", {
	connected_stem_texture = "mcl_farming_melon_stem_connected.png",
	gourd = "mcl_farming:melon",
	mature_desc = S("Mature Melon Stem"),
	mature_longdesc = S("A mature melon stem attempts to grow a melon at one of its four adjacent blocks. A melon can only grow on top of farmland, dirt, or a grass block. When a melon is next to a melon stem, the melon stem immediately bends and connects to the melon. While connected, a melon stem can't grow another melon. As soon all melons around the stem have been removed, it loses the connection and is ready to grow another melon."),
	premature_desc = S("Premature Melon Stem"),
	premature_longdesc = S("Melon stems grow on farmland in 8 stages. On hydrated farmland, the growth is a bit quicker. Mature melon stems are able to grow melons."),
	seed = "mcl_farming:melon_seeds",
	texture = "mcl_farming_melon_stem_disconnected.png"
})
-- Melon
core.register_node("mcl_farming:melon", {
	_doc_items_longdesc = S("A melon is a block which can be grown from melon stems, which in turn are grown from melon seeds. It can be harvested for melon slices."),
	_mcl_blast_resistance = 1,
	_mcl_fortune_drop = {
		cap = 9,
		discrete_uniform_distribution = true,
		items = {"mcl_farming:melon_item"},
		max_count = 7,
		min_count = 3
	},
	_mcl_hardness = 1,
	_mcl_silk_touch_drop = true,
	description = S("Melon"),
	drop = {
		items = {
			{items = {"mcl_farming:melon_item 3"}},
			{items = {"mcl_farming:melon_item 4"}, rarity = 5},
			{items = {"mcl_farming:melon_item 5"}, rarity = 5},
			{items = {"mcl_farming:melon_item 6"}, rarity = 5},
			{items = {"mcl_farming:melon_item 7"}, rarity = 5}
		},
		max_items = 1
	},
	groups = {
		axey = 1, building_block = 1, compostability = 65, dig_by_piston = 1,
		enderman_takable = 1, handy = 1, plant = 1, unsticky = 1
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	tiles = {"farming_melon_top.png", "farming_melon_top.png", "farming_melon_side.png"}
})
-- Craftitems
core.register_craftitem("mcl_farming:melon_item", {
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	_mcl_crafting_output = {
		single = {output = "mcl_farming:melon_seeds"},
		square3 = {output = "mcl_farming:melon"}
	},
	_mcl_saturation = 1.2,
	description = S("Melon Slice"),
	groups = {compostability = 50, eatable = 2, food = 2},
	inventory_image = "farming_melon.png",
	on_place = core.item_eat(2),
	on_secondary_use = core.item_eat(2),
	wield_image = "farming_melon.png"
})

core.register_craftitem("mcl_farming:melon_seeds", {
	_doc_items_longdesc = S("Grows into a melon stem which in turn grows melons. Chickens like melon seeds."),
	_doc_items_usagehelp = S("Place the melon seeds on farmland (which can be created with a hoe) to plant a melon stem. Melon stems grow in sunlight and grow faster on hydrated farmland. When mature, the stem will attempt to grow a melon at the side. Rightclick an animal to feed it melon seeds."),
	_mcl_places_plant = "mcl_farming:melontige_1",
	_tt_help = S("Grows on farmland"),
	description = S("Melon Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_melon_seeds.png",
	on_place = mcl_farming.place_plant,
	wield_image = "mcl_farming_melon_seeds.png"
})

-- Register stem growth
mcl_farming:add_plant("plant_melon_stem", "mcl_farming:melontige_unconnect", {"mcl_farming:melontige_1", "mcl_farming:melontige_2", "mcl_farming:melontige_3", "mcl_farming:melontige_4", "mcl_farming:melontige_5", "mcl_farming:melontige_6", "mcl_farming:melontige_7"}, 30, 5)
