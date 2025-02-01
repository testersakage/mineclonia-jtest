local S = core.get_translator(core.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_potato")
end

local sel_heights = {-0.375, -0.25, -0.125, 0}
local textures = {
	"mcl_farming_potatoes_stage_0.png", "mcl_farming_potatoes_stage_1.png",
	"mcl_farming_potatoes_stage_2.png", "mcl_farming_potatoes_stage_3.png"
}

local function shared_index(index)
	return index < 3 and 1 or index < 5 and 2 or index < 8 and 3 or 4
end

for i = 1, 8 do
	local premature, mature = i == 1, i == 8
	local longdesc, add_entry_alias
	local desc = S("Premature Potato Plant (Stage @1)", i)
	local subname = not mature and "_" .. i or ""
	local groups = {
		attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
		dig_immediate = 3, not_in_creative_inventory = 1, plant = 1, potato = i,  unsticky = 1
	}
	local texture = textures[shared_index(i)]

	if premature then
		longdesc = S("Potato plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature.")
	elseif mature then
		desc = S("Mature Potato Plant")
		longdesc = S("Mature potato plants are ready to be harvested for potatoes. They won't grow any further.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:potato" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Potato Plant") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:potato_item",
		_mcl_fortune_drop = mature and {
			cap = 5,
			discrete_uniform_distribution = true,
			items = {"mcl_farming:potato_item"},
			max_count = 4,
			min_count = 2
		} or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = mature and {
			items = {
				{items = {"mcl_farming:potato_item 1"}},
				{items = {"mcl_farming:potato_item 1"}, rarity = 2},
				{items = {"mcl_farming:potato_item 1"}, rarity = 2},
				{items = {"mcl_farming:potato_item 1"}, rarity = 2},
				{items = {"mcl_farming:potato_item_poison 1"}, rarity = 50}
			},
		} or "mcl_farming:potato_item",
		groups = groups,
		inventory_image = texture,
		selection_box = {
			fixed = {
				-0.4375, -0.5, -0.4375, 0.4375, sel_heights[shared_index(i)], 0.4375
			},
			type = "fixed"
		},
		tiles = {texture},
		wield_image = texture
	}))

	if add_entry_alias then
		doc.add_entry_alias("nodes", "mcl_farming:potato_1", "nodes", "mcl_farming:potato_"..i)
	end
end

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
	on_place = function(itemstack, placer, pointed_thing)
		local new = mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:potato_1")
		if new then
			return new
		else
			return core.do_item_eat(1, nil, itemstack, placer, pointed_thing)
		end
	end,
	on_secondary_use = core.item_eat(1)
})

core.register_craftitem("mcl_farming:potato_item_baked", {
	_doc_items_longdesc = S("Baked potatoes are food items which are more filling than the unbaked ones."),
	_mcl_saturation = 6.0,
	description = S("Baked Potato"),
	groups = {compostability = 85, eatable = 5, food = 2},
	inventory_image = "farming_potato_baked.png",
	on_place = core.item_eat(5),
	on_secondary_use = core.item_eat(5)
})

core.register_craftitem("mcl_farming:potato_item_poison", {
	_doc_items_longdesc = S("This potato doesn't look too healthy. You can eat it to restore hunger points, but there's a 60% chance it will poison you briefly."),
	_mcl_saturation = 1.2,
	_tt_help = core.colorize(mcl_colors.YELLOW, S("60% chance of poisoning")),
	description = S("Poisonous Potato"),
	groups = {eatable = 2, food = 2},
	inventory_image = "farming_potato_poison.png",
	on_place = core.item_eat(2),
	on_secondary_use = core.item_eat(2)
})

mcl_farming:add_plant("plant_potato", "mcl_farming:potato", {"mcl_farming:potato_1", "mcl_farming:potato_2", "mcl_farming:potato_3", "mcl_farming:potato_4", "mcl_farming:potato_5", "mcl_farming:potato_6", "mcl_farming:potato_7"}, 19.75, 20)

core.register_on_item_eat(function (_, _, itemstack, user)
	-- 60% chance of poisoning with poisonous potato
	if itemstack:get_name() == "mcl_farming:potato_item_poison" then
		if math.random(1,10) >= 6 then
			mcl_potions.give_effect_by_level("poison", user, 1, 5)
		end
	end

end )
