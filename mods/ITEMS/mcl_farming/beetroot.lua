local S = core.get_translator(core.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	if math.random(1, 100) <= 75 then
		return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_beetroot",1)
	end
end

for i = 0, 3 do
	local premature, mature = i == 0, i == 3
	local longdesc, add_entry_alias
	local desc = S("Premature Beetroot Plant (Stage @1)", i + 1)
	local subname = not mature and "_" .. i or ""
	local groups = {
		attached_node = 1, beetroot = i + 1, destroy_by_lava_flow = 1, dig_by_piston = 1,
		dig_by_water = 1, dig_immediate = 3, not_in_creative_inventory = 1, plant = 1, unsticky = 1
	}
	local texture = "mcl_farming_beetroot_" .. i .. ".png"

	if premature then
		longdesc = S("Beetroot plants are plants which grow on farmland under sunlight in 4 stages. On hydrated farmland, they grow a bit faster. They can be harvested at any time but will only yield a profit when mature.")
	elseif mature then
		desc = S("Mature Beetroot Plant")
		longdesc = S("A mature beetroot plant is a farming plant which is ready to be harvested for a beetroot and some beetroot seeds. It won't grow any further.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:beetroot" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Beetroot Plant") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:beetroot_seeds",
		_mcl_fortune_drop = mature and {
			cap = 5,
			discrete_uniform_distribution = true,
			drop_without_fortune = {"mcl_farming:beetroot_item"},
			items = {"mcl_farming:beetroot_seeds"},
			max_count = 3,
			min_count = 1
		} or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = mature and {
			items = {
				{items = {"mcl_farming:beetroot_item"}},
				{items = {"mcl_farming:beetroot_seeds"}, rarity = 1},
				{items = {"mcl_farming:beetroot_seeds 2"}, rarity = 3},
				{items = {"mcl_farming:beetroot_seeds 3"}, rarity = 4},
				{items = {"mcl_farming:beetroot_seeds 4"}, rarity = 6}
			},
			max_items = 2
		} or "mcl_farming:beetroot_seeds",
		groups = groups,
		inventory_image = texture,
		selection_box = {
			fixed = {-0.3125, -0.5, -0.3125, 0.3125, -0.5 + (1 + i) * 0.125, 0.3125},
			type = "fixed"
		},
		tiles = {texture},
		wield_image = texture
	}))

	if add_entry_alias then
		doc.add_entry_alias("nodes", "mcl_farming:beetroot_0", "nodes", "mcl_farming:beetroot_" .. i)
	end
end

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

core.register_craftitem("mcl_farming:beetroot_seeds", {
	_doc_items_longdesc = S("Grows into a beetroot plant. Chickens like beetroot seeds."),
	_doc_items_usagehelp = S("Place the beetroot seeds on farmland (which can be created with a hoe) to plant a beetroot plant. They grow in sunlight and grow faster on hydrated farmland. Rightclick an animal to feed it beetroot seeds."),
	_mcl_places_plant = "mcl_farming:beetroot_1",
	_tt_help = S("Grows on farmland"),
	description = S("Beetroot Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_beetroot_seeds.png",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:beetroot_0")
	end,
	wield_image = "mcl_farming_beetroot_seeds.png"
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

core.register_craft({
	output = "mcl_farming:beetroot_soup",
	recipe = {
		{"mcl_farming:beetroot_item","mcl_farming:beetroot_item","mcl_farming:beetroot_item"},
		{"mcl_farming:beetroot_item","mcl_farming:beetroot_item","mcl_farming:beetroot_item"},
		{"", "mcl_core:bowl", ""}
	}
})

mcl_farming:add_plant("plant_beetroot", "mcl_farming:beetroot", {"mcl_farming:beetroot_0", "mcl_farming:beetroot_1", "mcl_farming:beetroot_2"}, 68, 3)

core.register_alias("beetroot_seeds", "mcl_farming:beetroot_seeds")
core.register_alias("beetroot", "mcl_farming:beetroot_item")
