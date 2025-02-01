local S = core.get_translator(core.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_wheat")
end

local sel_heights = {
	-0.1875, 0, 0.125, 0.25, 0.3125, 0.375, 0.4375, 0.5
}

for i = 1, 8 do
	local premature, mature = i == 1, i == 8
	local longdesc, add_entry_alias
	local desc = S("Premature Wheat Plant (Stage @1)", i)
	local subname = not mature and "_" .. i or ""
	local groups = {
		attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
		dig_immediate = 3, not_in_creative_inventory = 1, plant = 1, unsticky = 1, wheat = i,
	}
	local texture = "mcl_farming_wheat_stage_" .. i - 1 .. ".png"

	if premature then
		longdesc = S([[
			Premature wheat plants grow on farmland under sunlight in 8 stages.
			On hydrated farmland, they grow faster. They can be harvested at any time but will only yield a profit when mature.
		]])
	elseif mature then
		desc = S("Mature Wheat Plant")
		longdesc = S([[
			Mature wheat plants are ready to be harvested for wheat and wheat seeds.
			They won't grow any further.
		]])
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:wheat" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Wheat Plant") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:wheat_seeds",
		_mcl_fortune_drop = mature and {
			cap = 7,
			discrete_uniform_distribution = true,
			drop_without_fortune = {"mcl_farming:wheat_item"},
			items = {"mcl_farming:wheat_seeds"},
			max_count = 6,
			min_count = 1
		} or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = mature and {
			items = {
				{items = {"mcl_farming:wheat_seeds"}},
				{items = {"mcl_farming:wheat_seeds"}, rarity = 2},
				{items = {"mcl_farming:wheat_seeds"}, rarity = 5},
				{items = {"mcl_farming:wheat_item"}}
			},
			max_items = 4,
		} or "mcl_farming:wheat_seeds",
		groups = groups,
		inventory_image = texture,
		selection_box = {
			fixed = {
				-0.4375, -0.5, -0.4375, 0.4375, sel_heights[i], 0.4375
			},
			type = "fixed"
		},
		tiles = {texture},
		wield_image = texture
	}))

	if add_entry_alias then
		doc.add_entry_alias("nodes", "mcl_farming:wheat_1", "nodes", "mcl_farming:wheat_"..i)
	end
end

core.register_craftitem("mcl_farming:bread", {
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	_mcl_saturation = 6.0,
	description = S("Bread"),
	groups = {compostability = 85, eatable = 5, food = 2},
	inventory_image = "farming_bread.png",
	on_place = core.item_eat(5),
	on_secondary_use = core.item_eat(5),
})

core.register_craftitem("mcl_farming:cookie", {
	_doc_items_longdesc = S("This is a food item which can be eaten."),
	_mcl_saturation = 0.4,
	description = S("Cookie"),
	groups = {compostability = 85, eatable = 2, food = 2},
	inventory_image = "farming_cookie.png",
	on_place = core.item_eat(2),
	on_secondary_use = core.item_eat(2)
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
	inventory_image = "farming_wheat_harvested.png"
})

core.register_craftitem("mcl_farming:wheat_seeds", {
	_doc_items_longdesc = S("Grows into a wheat plant. Chickens like wheat seeds."),
	_doc_items_usagehelp = S([[
		Place the wheat seeds on farmland (which can be created with a hoe) to plant a wheat plant.
		They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it wheat seeds.
	]]),
	_mcl_places_plant = "mcl_farming:wheat_1",
	_tt_help = S("Grows on farmland"),
	description = S("Wheat Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_wheat_seeds.png",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:wheat_1")
	end
})

core.register_craft({
	output = "mcl_farming:cookie 8",
	recipe = {
		{"mcl_farming:wheat_item", "mcl_cocoas:cocoa_beans", "mcl_farming:wheat_item"},
	}
})

core.register_node("mcl_farming:hay_block", {
	_doc_items_longdesc = S("Hay bales are decorative blocks made from wheat."),
	_mcl_blast_resistance = 0.5,
	_mcl_crafting_output = {single = {output = "mcl_farming:wheat_item 9"}},
	_mcl_hardness = 0.5,
	description = S("Hay Bale"),
	groups = {
		building_block = 1, compostability = 85, fall_damage_add_percent = -80,
		fire_encouragement = 60, fire_flammability = 20, flammable = 2, handy = 1, hoey = 1,
	},
	is_ground_content = false,
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	tiles = {
		"mcl_farming_hayblock_top.png", "mcl_farming_hayblock_top.png", "mcl_farming_hayblock_side.png"
	}
})

mcl_farming:add_plant("plant_wheat", "mcl_farming:wheat", {"mcl_farming:wheat_1", "mcl_farming:wheat_2", "mcl_farming:wheat_3", "mcl_farming:wheat_4", "mcl_farming:wheat_5", "mcl_farming:wheat_6", "mcl_farming:wheat_7"}, 25, 20)
