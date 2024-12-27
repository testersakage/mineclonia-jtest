local S = minetest.get_translator(minetest.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_carrot")
end

mcl_farming.register_crop("carrot", {
	stages = 8,
	descriptions = {
		"Premature Carrot Plant (Stage @1)",
		"Mature Carrot Plant"
	},
	premature_longdesc = S("Carrot plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature."),
	entry_name = S("Premature Carrot Plant"),
	mature_longdesc = S("Mature carrot plants are ready to be harvested for carrots. They won't grow any further."),
	on_bone_meal = on_bone_meal,
	seed = "mcl_farming:carrot_item",
	full_grow_drop = {
		max_items = 1,
		items = {
			{ items = {"mcl_farming:carrot_item 4"}, rarity = 5 },
			{ items = {"mcl_farming:carrot_item 3"}, rarity = 2 },
			{ items = {"mcl_farming:carrot_item 2"}, rarity = 2 },
			{ items = {"mcl_farming:carrot_item 1"} },
		}
	},
	fortune_drop = {
		discrete_uniform_distribution = true,
		items = {"mcl_farming:carrot_item"},
		min_count = 2,
		max_count = 4,
		cap = 5,
	},
	boxes = {
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.375 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.375 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.25 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.25 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.25 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.125 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, -0.125 ,0.4375},
		{-0.4375, -0.5 ,-0.4375, 0.4375, 0 ,0.4375},
	},
	tiles = {
		"farming_carrot_1.png",
		"farming_carrot_1.png",
		"farming_carrot_2.png",
		"farming_carrot_2.png",
		"farming_carrot_2.png",
		"farming_carrot_3.png",
		"farming_carrot_3.png",
		"farming_carrot_4.png",
	}
})

minetest.register_craftitem("mcl_farming:carrot_item", {
	description = S("Carrot"),
	_tt_help = S("Grows on farmland"),
	_doc_items_longdesc = S("Carrots can be eaten and planted. Pigs and rabbits like carrots."),
	_doc_items_usagehelp = S("Hold it in your hand and rightclick to eat it. Place it on top of farmland to plant the carrot. It grows in sunlight and grows faster on hydrated farmland. Rightclick an animal to feed it."),
	inventory_image = "farming_carrot.png",
	groups = {food = 2, eatable = 3, compostability = 65},
	_mcl_saturation = 3.6,
	_mcl_places_plant = "mcl_farming:carrot_1",
	on_secondary_use = minetest.item_eat(3),
	on_place = function(itemstack, placer, pointed_thing)
		local new = mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:carrot_0")
		if new then
			return new
		else
			return minetest.do_item_eat(3, nil, itemstack, placer, pointed_thing)
		end
	end,
})

minetest.register_craftitem("mcl_farming:carrot_item_gold", {
	description = S("Golden Carrot"),
	_doc_items_longdesc = S("A golden carrot is a precious food item which can be eaten. It is really, really filling!"),
	inventory_image = "farming_carrot_gold.png",
	on_place = minetest.item_eat(6),
	on_secondary_use = minetest.item_eat(6),
	groups = { brewitem = 1, food = 2, eatable = 6 },
	_mcl_saturation = 14.4,
})

minetest.register_craft({
	output = "mcl_farming:carrot_item_gold",
	recipe = {
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_farming:carrot_item", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"},
	}
})

mcl_farming:add_plant("plant_carrot", "mcl_farming:carrot", {"mcl_farming:carrot_0", "mcl_farming:carrot_1", "mcl_farming:carrot_2", "mcl_farming:carrot_3", "mcl_farming:carrot_4", "mcl_farming:carrot_5", "mcl_farming:carrot_6"}, 25, 20)

for i = 1, 7 do
	minetest.register_alias("mcl_farming:carrot_" .. i - 1, "mcl_farming:carrot_" .. i)
end
