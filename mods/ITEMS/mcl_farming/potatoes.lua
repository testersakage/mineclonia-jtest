local S = core.get_translator(core.get_current_modname())
-- Potato crops
mcl_farming.register_simple_crop("potato", {
	fortune_drop = {
		cap = 5,
		discrete_uniform_distribution = true,
		items = {"mcl_farming:potato_item"},
		max_count = 4,
		min_count = 2
	},
	mature_desc = S("Mature Potato Plant"),
	mature_drop = {
		items = {
			{items = {"mcl_farming:potato_item 2"}, rarity = 12},
			{items = {"mcl_farming:potato_item 3"}, rarity = 3},
			{items = {"mcl_farming:potato_item 4"}, rarity = 2},
			{items = {"mcl_farming:potato_item 5"}, rarity = 5},
			{items = {"mcl_farming:potato_item_poison"}, rarity = 50}
		},
		max_items = 1
	},
	mature_longdesc = S("Mature potato plants are ready to be harvested for potatoes. They won't grow any further."),
	premature_desc = S("Premature Potato Plant"),
	premature_longdesc = S("Potato plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature."),
	seed = "mcl_farming:potato_item",
	sel_heights = {["1, 2"] = -0.3125, ["3, 4"] = -0.25, ["5, 6, 7"] = -0.125, ["8"] = 0},
	sel_widths = {["1, 2"] = 0.3125, ["3, 4, 5, 6, 7, 8"] = 0.375},
	stages = 8,
	textures = {
		["1, 2"] = "mcl_farming_potatoes_stage_0.png",
		["3, 4"] = "mcl_farming_potatoes_stage_1.png",
		["5, 6, 7"] = "mcl_farming_potatoes_stage_2.png",
		["8"] = "mcl_farming_potatoes_stage_3.png"
	}
}, {
	_on_bone_meal = function(_, _, _, pos, node)
		return mcl_farming.on_bone_meal(_,_,_, pos, node, "plant_potato")
	end
})
-- Craftitems
core.register_craftitem("mcl_farming:potato_item", {
	_doc_items_longdesc = S("Potatoes are food items which can be eaten, cooked in the furnace and planted. Pigs like potatoes."),
	_doc_items_usagehelp = S("Hold it in your hand and rightclick to eat it. Place it on top of farmland to plant it. It grows in sunlight and grows faster on hydrated farmland. Rightclick an animal to feed it."),
	_mcl_cooking_output = "mcl_farming:potato_item_baked",
	_mcl_places_plant = "mcl_farming:potato_1",
	_mcl_saturation = 0.6,
	_tt_help = S("Grows on farmland"),
	description = S("Potato"),
	groups = {
		campfire_cookable = 1, compostability = 65, eatable = 1, food = 2, smoker_cookable = 1
	},
	inventory_image = "farming_potato.png",
	on_place = mcl_farming.place_plant,
	on_secondary_use = core.item_eat(1),
	wield_image = "farming_potato.png"
})

core.register_craftitem("mcl_farming:potato_item_baked", {
	_doc_items_longdesc = S("Baked potatoes are food items which are more filling than the unbaked ones."),
	_mcl_saturation = 6.0,
	description = S("Baked Potato"),
	groups = {compostability = 85, eatable = 5, food = 2},
	inventory_image = "farming_potato_baked.png",
	on_place = core.item_eat(5),
	on_secondary_use = core.item_eat(5),
	wield_image = "farming_potato_baked.png"
})

core.register_craftitem("mcl_farming:potato_item_poison", {
	_doc_items_longdesc = S("This potato doesn't look too healthy. You can eat it to restore hunger points, but there's a 60% chance it will poison you briefly."),
	_mcl_saturation = 1.2,
	_tt_help = core.colorize(mcl_colors.YELLOW, S("60% chance of poisoning")),
	description = S("Poisonous Potato"),
	groups = {eatable = 2, food = 2},
	inventory_image = "farming_potato_poison.png",
	on_place = core.item_eat(2),
	on_secondary_use = core.item_eat(2),
	wield_image = "farming_potato_poison.png"
})
-- 60% chance of poisoning with poisonous potato
core.register_on_item_eat(function (_, _, itemstack, user)
	if itemstack:get_name() == "mcl_farming:potato_item_poison" then
		if math.random(1,10) >= 6 then
			mcl_potions.give_effect_by_level("poison", user, 1, 5)
		end
	end
end)

mcl_farming:add_plant("plant_potato", "mcl_farming:potato", {"mcl_farming:potato_1", "mcl_farming:potato_2", "mcl_farming:potato_3", "mcl_farming:potato_4", "mcl_farming:potato_5", "mcl_farming:potato_6", "mcl_farming:potato_7"}, 19.75, 20)
