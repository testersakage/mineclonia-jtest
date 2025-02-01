local S = core.get_translator(core.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_carrot")
end

local sel_heights = {-0.375, -0.25, -0.125, 0}
local textures = {
	"farming_carrot_1.png", "farming_carrot_2.png", "farming_carrot_3.png", "farming_carrot_4.png"
}

local function shared_index(index)
	return index < 3 and 1 or index < 5 and 2 or index < 8 and 3 or 4
end

for i = 1, 8 do
	local premature, mature = i == 1, i == 8
	local longdesc, add_entry_alias
	local desc = S("Premature Carrot Plant (Stage @1)", i)
	local subname = not mature and "_" .. i or ""
	local groups = {
		attached_node = 1, carrot = i, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
		dig_immediate = 3, not_in_creative_inventory = 1, plant = 1,  unsticky = 1
	}
	local texture = textures[shared_index(i)]

	if premature then
		longdesc = S("Carrot plants are plants which grow on farmland under sunlight in 8 stages, but only 4 stages can be visually told apart. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature.")
	elseif mature then
		desc = S("Mature Carrot Plant")
		longdesc = S("Mature carrot plants are ready to be harvested for carrots. They won't grow any further.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:carrot" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Carrot Plant") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:carrot_item",
		_mcl_fortune_drop = mature and {
			cap = 5,
			discrete_uniform_distribution = true,
			items = {"mcl_farming:carrot_item"},
			max_count = 4,
			min_count = 2
		} or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = mature and {
			items = {
				{items = {"mcl_farming:carrot_item 1"}},
				{items = {"mcl_farming:carrot_item 2"}, rarity = 2},
				{items = {"mcl_farming:carrot_item 3"}, rarity = 2},
				{items = {"mcl_farming:carrot_item 4"}, rarity = 5}
			},
			max_items = 1
		} or "mcl_farming:carrot_item",
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
		doc.add_entry_alias("nodes", "mcl_farming:carrot_1", "nodes", "mcl_farming:carrot_"..i)
	end
end

core.register_craftitem("mcl_farming:carrot_item", {
	_doc_items_longdesc = S("Carrots can be eaten and planted. Pigs and rabbits like carrots."),
	_doc_items_usagehelp = S("Hold it in your hand and rightclick to eat it. Place it on top of farmland to plant the carrot. It grows in sunlight and grows faster on hydrated farmland. Rightclick an animal to feed it."),
	_mcl_saturation = 3.6,
	_mcl_places_plant = "mcl_farming:carrot_1",
	_tt_help = S("Grows on farmland"),
	description = S("Carrot"),
	groups = {compostability = 65, eatable = 3, food = 2},
	inventory_image = "farming_carrot.png",
	on_place = function(itemstack, placer, pointed_thing)
		local new = mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:carrot_1")

		if new then
			return new
		else
			return core.do_item_eat(3, nil, itemstack, placer, pointed_thing)
		end
	end,
	on_secondary_use = core.item_eat(3)
})

core.register_craftitem("mcl_farming:carrot_item_gold", {
	_doc_items_longdesc = S("A golden carrot is a precious food item which can be eaten. It is really, really filling!"),
	_mcl_saturation = 14.4,
	description = S("Golden Carrot"),
	groups = {brewitem = 1, eatable = 6, food = 2},
	inventory_image = "farming_carrot_gold.png",
	on_place = core.item_eat(6),
	on_secondary_use = core.item_eat(6)
})

core.register_craft({
	output = "mcl_farming:carrot_item_gold",
	recipe = {
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_farming:carrot_item", "mcl_core:gold_nugget"},
		{"mcl_core:gold_nugget", "mcl_core:gold_nugget", "mcl_core:gold_nugget"}
	}
})

mcl_farming:add_plant("plant_carrot", "mcl_farming:carrot", {"mcl_farming:carrot_1", "mcl_farming:carrot_2", "mcl_farming:carrot_3", "mcl_farming:carrot_4", "mcl_farming:carrot_5", "mcl_farming:carrot_6", "mcl_farming:carrot_7"}, 25, 20)
