local S = minetest.get_translator(minetest.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_potato")
end

mcl_farming.register_crop("potato", {
	stages = 8,
	descriptions = {
		"Premature Potato Plant (Stage @1)",
		"Mature Potato Plant"
	},
	premature_longdesc = S("Potato plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature."),
	entry_name = S("Premature Potato Plant"),
	mature_longdesc = S("Mature potato plants are ready to be harvested for potatoes. They won't grow any further."),
	on_bone_meal = on_bone_meal,
	seed = "mcl_farming:potato_item",
	full_grow_drop = {
		items = {
			{ items = {"mcl_farming:potato_item 1"} },
			{ items = {"mcl_farming:potato_item 1"}, rarity = 2 },
			{ items = {"mcl_farming:potato_item 1"}, rarity = 2 },
			{ items = {"mcl_farming:potato_item 1"}, rarity = 2 },
			{ items = {"mcl_farming:potato_item_poison 1"}, rarity = 50 }
		}
	},
	fortune_drop = {
		discrete_uniform_distribution = true,
		items = {"mcl_farming:potato_item"},
		min_count = 2,
		max_count = 4,
		cap = 5
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
		"mcl_farming_potatoes_stage_0.png",
		"mcl_farming_potatoes_stage_0.png",
		"mcl_farming_potatoes_stage_1.png",
		"mcl_farming_potatoes_stage_1.png",
		"mcl_farming_potatoes_stage_1.png",
		"mcl_farming_potatoes_stage_2.png",
		"mcl_farming_potatoes_stage_2.png",
		"mcl_farming_potatoes_stage_3.png",
	}
})

minetest.register_craftitem("mcl_farming:potato_item", {
	description = S("Potato"),
	_tt_help = S("Grows on farmland"),
	_doc_items_longdesc = S("Potatoes are food items which can be eaten, cooked in the furnace and planted. Pigs like potatoes."),
	_doc_items_usagehelp = S("Hold it in your hand and rightclick to eat it. Place it on top of farmland to plant it. It grows in sunlight and grows faster on hydrated farmland. Rightclick an animal to feed it."),
	inventory_image = "farming_potato.png",
	groups = {food = 2, eatable = 1, compostability = 65, smoker_cookable = 1, campfire_cookable = 1},
	_mcl_saturation = 0.6,
	_mcl_cooking_output = "mcl_farming:potato_item_baked",
	_mcl_places_plant = "mcl_farming:potato_1",
	on_secondary_use = minetest.item_eat(1),
	on_place = function(itemstack, placer, pointed_thing)
		local new = mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:potato_1")
		if new then
			return new
		else
			return minetest.do_item_eat(1, nil, itemstack, placer, pointed_thing)
		end
	end,
})

minetest.register_craftitem("mcl_farming:potato_item_baked", {
	description = S("Baked Potato"),
	_doc_items_longdesc = S("Baked potatoes are food items which are more filling than the unbaked ones."),
	inventory_image = "farming_potato_baked.png",
	on_place = minetest.item_eat(5),
	on_secondary_use = minetest.item_eat(5),
	groups = {food = 2, eatable = 5, compostability = 85},
	_mcl_saturation = 6.0,
})

minetest.register_craftitem("mcl_farming:potato_item_poison", {
	description = S("Poisonous Potato"),
	_tt_help = minetest.colorize(mcl_colors.YELLOW, S("60% chance of poisoning")),
	_doc_items_longdesc = S("This potato doesn't look too healthy. You can eat it to restore hunger points, but there's a 60% chance it will poison you briefly."),
	inventory_image = "farming_potato_poison.png",
	on_place = minetest.item_eat(2),
	on_secondary_use = minetest.item_eat(2),
	groups = { food = 2, eatable = 2 },
	_mcl_saturation = 1.2,
})

mcl_farming:add_plant("plant_potato", "mcl_farming:potato", {"mcl_farming:potato_0", "mcl_farming:potato_1", "mcl_farming:potato_2", "mcl_farming:potato_3", "mcl_farming:potato_4", "mcl_farming:potato_5", "mcl_farming:potato_6"}, 19.75, 20)

minetest.register_on_item_eat(function (_, _, itemstack, user)

	-- 60% chance of poisoning with poisonous potato
	if itemstack:get_name() == "mcl_farming:potato_item_poison" then
		if math.random(1,10) >= 6 then
			mcl_potions.give_effect_by_level("poison", user, 1, 5)
		end
	end

end )
