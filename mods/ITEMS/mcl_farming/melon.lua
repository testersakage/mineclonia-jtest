local S = core.get_translator(core.get_current_modname())

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_melon_stem")
end

local function get_drops(step)
	local rarity = {
		{6, 3, 3, 2, 2, 2, 3},
		{81, 22, 10, 6, 5, 3, 3},
		{3333, 417, 125, 53, 27, 16, 10}
	}
	return {
		{items = {"mcl_farming:melon_seeds"}, rarity = rarity[1][step]},
		{items = {"mcl_farming:melon_seeds 2"}, rarity = rarity[2][step]},
		{items = {"mcl_farming:melon_seeds 3"}, rarity = rarity[3][step]}
	}
end

local startcolor = {r = 0x2E , g = 0x9D, b = 0x2E}
local endcolor = {r = 0xFF , g = 0xA8, b = 0x00}

local function get_texture(step)
	local colorstring = mcl_farming:stem_color(startcolor, endcolor, step, 8)
	return "([combine:16x16:0," .. ((8 - step) * 2) ..
	"=mcl_farming_melon_stem_disconnected.png)^[colorize:" .. colorstring .. ":127"
end

for i = 1, 8 do
	local premature, mature = i == 1, i == 8
	local longdesc, add_entry_alias
	local desc = S("Premature Melon Sten (Stage @1)", i)
	local subname = mature and "unconnect" or i
	local texture = get_texture(i)

	if premature then
		longdesc = S("Melon stems grow on farmland in 8 stages. On hydrated farmland, the growth is a bit quicker. Mature melon stems are able to grow melons.")
	elseif mature then
		desc = S("Mature Melon Stem")
		longdesc = S("A mature melon stem attempts to grow a melon at one of its four adjacent blocks. A melon can only grow on top of farmland, dirt, or a grass block. When a melon is next to a melon stem, the melon stem immediately bends and connects to the melon. While connected, a melon stem can't grow another melon. As soon all melons around the stem have been removed, it loses the connection and is ready to grow another melon.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:melontige_" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Melon Stem") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:melon_seeds",
		_mcl_farming_gourd_name = mature and "mcl_farming:melon" or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = {
			items = get_drops(i),
			max_items = 1
		},
		groups = {
			attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
			dig_immediate = 3, not_in_creative_inventory = 1, plant = 1,  plant_melon_stem = i
		},
		inventory_image = texture,
		on_construct = mature and mcl_farming.try_connect_stem or nil,
		place_param2 = 0,
		selection_box = {
			fixed = {
				{-0.15, -0.5, -0.15, 0.15, -0.5 + i / 8, 0.15}
			},
			type = "fixed"
		},
		tiles = {texture},
		wield_image = texture
	}))

	if add_entry_alias then
		doc.add_entry_alias("nodes", "mcl_farming:melontige_1", "nodes", "mcl_farming:melontige_" .. i)
	end
end

for i = 1, 4 do
	local subname = {"_r", "_l", "_t", "_b"}
	local name = "mcl_farming:melontige_linked" .. subname[i]

	core.register_node(name, table.merge(mcl_farming.tpl_connected_stem, {
		_mcl_farming_gourd_name = "mcl_farming:melon",
		_mcl_farming_unconnected_stem = "mcl_farming:melontige_unconnect",
		drop = get_drops(8),
		node_box = mcl_farming.get_stem_nodebox(i),
		selection_box = mcl_farming.get_stem_selectionbox(i),
		tiles = mcl_farming.get_stem_tiles("mcl_farming_melon_stem_connected.png", i)
	}))

	doc.add_entry_alias("nodes", "mcl_farming:melontige_unconnect", "nodes", name)
end

core.register_node("mcl_farming:melon", {
	_doc_items_longdesc = S("A melon is a block which can be grown from melon stems, which in turn are grown from melon seeds. It can be harvested for melon slices."),
	_mcl_blast_resistance = 1,
	_mcl_farming_linked_stem = "mcl_farming:melontige_linked",
	_mcl_fortune_drop = {
		cap = 9,
		discrete_uniform_distribution = true,
		items = {"mcl_farming:melon_item"},
		max_count = 7,
		min_count = 3
	},
	_mcl_hardness = 1,
	_mcl_silk_touch_drop = true,
	after_destruct = mcl_farming.unconnect_gourd,
	description = S("Melon"),
	drop = {
		items = {
			{items = {"mcl_farming:melon_item 3"}},
			{items = {"mcl_farming:melon_item 4"}, rarity = 2},
			{items = {"mcl_farming:melon_item 5"}, rarity = 5},
			{items = {"mcl_farming:melon_item 6"}, rarity = 10},
			{items = {"mcl_farming:melon_item 7"}, rarity = 14}
		},
		max_items = 1
	},
	groups = {
		axey = 1, building_block = 1, compostability = 65, dig_by_piston = 1, enderman_takable = 1,
		handy = 1, plant = 1, unsticky = 1
	},
	on_construct = mcl_farming.try_connect_gourd,
	sounds = mcl_sounds.node_sound_wood_defaults(),
	tiles = {"farming_melon_top.png", "farming_melon_top.png", "farming_melon_side.png"}
})
-- Items
core.register_craftitem("mcl_farming:melon_seeds", {
	_doc_items_longdesc = S("Grows into a melon stem which in turn grows melons. Chickens like melon seeds."),
	_doc_items_usagehelp = S("Place the melon seeds on farmland (which can be created with a hoe) to plant a melon stem. Melon stems grow in sunlight and grow faster on hydrated farmland. When mature, the stem will attempt to grow a melon at the side. Rightclick an animal to feed it melon seeds."),
	_mcl_places_plant = "mcl_farming:melontige_1",
	_tt_help = S("Grows on farmland"),
	description = S("Melon Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_melon_seeds.png",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:melontige_1")
	end
})

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
	on_secondary_use = core.item_eat(2)
})
-- Register stem growth
mcl_farming:add_plant("plant_melon_stem", "mcl_farming:melontige_unconnect", {"mcl_farming:melontige_1", "mcl_farming:melontige_2", "mcl_farming:melontige_3", "mcl_farming:melontige_4", "mcl_farming:melontige_5", "mcl_farming:melontige_6", "mcl_farming:melontige_7"}, 30, 5)
-- Register actual melon, connected stems and stem-to-melon growth
mcl_farming.add_gourd("mcl_farming:melontige_unconnect", "mcl_farming:melontige_linked", "mcl_farming:melon", 25, 15)
