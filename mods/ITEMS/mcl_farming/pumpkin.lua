local S = core.get_translator(core.get_current_modname())

local pumpkin_hud = {}

local tpl_pumpkin = {
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
	groups = {
		handy = 1, axey = 1, plant = 1, building_block = 1, dig_by_piston = 1,
		pumpkin = 1, enderman_takable = 1, compostability = 65, unsticky = 1
	},
	is_ground_content = false,
	on_rotate = screwdriver.rotate_simple,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_wood_defaults(),
}

local function on_bone_meal(itemstack,placer,pointed_thing,pos,node)
	return mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_pumpkin_stem")
end

local function carve_pumpkin(itemstack, placer, pointed_thing)
	if pointed_thing.above.y ~= pointed_thing.under.y then return end

	if not core.is_creative_enabled(placer:get_player_name()) then
		local toolname = itemstack:get_name()
		local wear = mcl_autogroup.get_wear(toolname, "shearsy")

		itemstack:add_wear(wear)
	end

	core.sound_play({name = "default_grass_footstep"}, {pos = pointed_thing.above}, true)

	local dir = vector.subtract(pointed_thing.under, pointed_thing.above)
	local param2 = core.dir_to_facedir(dir)

	core.set_node(pointed_thing.under, {name = "mcl_farming:pumpkin_face", param2 = param2})
	core.add_item(pointed_thing.above, "mcl_farming:pumpkin_seeds 4")

	return itemstack, true
end

local function add_pumpkin_hud(player)
	pumpkin_hud[player] = {
		pumpkin_blur = player:hud_add({
			type = "image",
			position = {x = 0.5, y = 0.5},
			scale = {x = -101, y = -101},
			text = "mcl_farming_pumpkin_hud.png",
			z_index = -200
		}),
		--this is a fake crosshair, because hotbar and crosshair doesn't support z_index
		--TODO: remove this and add correct z_index values
		fake_crosshair = player:hud_add({
			type = "image",
			position = {x = 0.5, y = 0.5},
			scale = {x = 1, y = 1},
			text = "crosshair.png",
			z_index = -100
		})
	}
end

local function remove_pumpkin_hud(player)
	if pumpkin_hud[player] then
		player:hud_remove(pumpkin_hud[player].pumpkin_blur)
		player:hud_remove(pumpkin_hud[player].fake_crosshair)
		pumpkin_hud[player] = nil
	end
end

local function get_drops(step)
	local rarity = {
		{6, 3, 3, 2, 2, 2, 3},
		{81, 22, 10, 6, 5, 3, 3},
		{3333, 417, 125, 53, 27, 16, 10}
	}
	return {
		{items = {"mcl_farming:pumpkin_seeds"}, rarity = rarity[1][step]},
		{items = {"mcl_farming:pumpkin_seeds 2"}, rarity = rarity[2][step]},
		{items = {"mcl_farming:pumpkin_seeds 3"}, rarity = rarity[3][step]}
	}
end

local startcolor = {r = 0x2E , g = 0x9D, b = 0x2E}
local endcolor = {r = 0xFF , g = 0xA8, b = 0x00}

local function get_texture(step)
	local colorstring = mcl_farming:stem_color(startcolor, endcolor, step, 8)
	return "([combine:16x16:0," .. ((8 - step) * 2) ..
	"=mcl_farming_pumpkin_stem_disconnected.png)^[colorize:" .. colorstring .. ":127"
end

for i = 1, 8 do
	local premature, mature = i == 1, i == 8
	local longdesc, add_entry_alias
	local desc = S("Premature Pumpkin Stem (Stage @1)", i)
	local subname = mature and "unconnect" or i
	local texture = get_texture(i)

	if premature then
		longdesc = S("Pumpkin stems grow on farmland in 8 stages. On hydrated farmland, the growth is a bit quicker. Mature pumpkin stems are able to grow pumpkins.")
	elseif mature then
		desc = S("Mature Pumpkin Stem")
		longdesc = S("A mature melon stem attempts to grow a melon at one of its four adjacent blocks. A melon can only grow on top of farmland, dirt, or a grass block. When a melon is next to a melon stem, the melon stem immediately bends and connects to the melon. While connected, a melon stem can't grow another melon. As soon all melons around the stem have been removed, it loses the connection and is ready to grow another melon.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_farming:pumpkin_" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Pumpkin Stem") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_farming:pumpkin_seeds",
		_mcl_farming_gourd_name = mature and "mcl_farming:pumpkin" or nil,
		_on_bone_meal = on_bone_meal,
		description = desc,
		drop = {
			items = get_drops(i),
			max_items = 1
		},
		groups = {
			attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
			dig_immediate = 3, not_in_creative_inventory = 1, plant = 1,  plant_pumpkin_stem = i
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
		doc.add_entry_alias("nodes", "mcl_farming:pumpkin_1", "nodes", "mcl_farming:pumpkin_" .. i)
	end
end

for i = 1, 4 do
	local subname = {"_r", "_l", "_t", "_b"}
	local name = "mcl_farming:pumpkintige_linked" .. subname[i]

	core.register_node(name, table.merge(mcl_farming.tpl_connected_stem, {
		_mcl_farming_gourd_name = "mcl_farming:pumpkin",
		_mcl_farming_unconnected_stem = "mcl_farming:pumpkintige_unconnect",
		drop = get_drops(8),
		node_box = mcl_farming.get_stem_nodebox(i),
		selection_box = mcl_farming.get_stem_selectionbox(i),
		tiles = mcl_farming.get_stem_tiles("mcl_farming_pumpkin_stem_connected.png", i)
	}))

	doc.add_entry_alias("nodes", "mcl_farming:pumpkintige_unconnect", "nodes", name)
end

core.register_node("mcl_farming:pumpkin", table.merge(tpl_pumpkin, {
	_doc_items_longdesc = S("A pumpkin is a decorative block. It can be carved with shears to obtain pumpkin seeds."),
	_doc_items_usagehelp = S("To carve a face into the pumpkin, use the shears on the side you want to carve."),
	_mcl_crafting_output = {single = {output = "mcl_farming:pumpkin_seeds 4"}},
	_on_shears_place = carve_pumpkin,
	description = S("Pumpkin"),
	tiles = {"farming_pumpkin_top.png", "farming_pumpkin_top.png", "farming_pumpkin_side.png"},

}))

core.register_node("mcl_farming:pumpkin_face", table.merge(tpl_pumpkin, {
	_doc_items_longdesc = S("A carved pumpkin is a decorative that can be worn as a helmet."),
	_mcl_armor_element = "head",
	_mcl_armor_mob_range_factor = 0,
	_mcl_armor_mob_range_mob = "mobs_mc:enderman",
	_mcl_armor_texture = "mcl_farming_pumpkin_face.png",
	_on_equip = add_pumpkin_hud,
	_on_unequip = remove_pumpkin_hud,
	after_place_node = function(pos, placer)
		mobs_mc.check_iron_golem_summon(pos, placer)
		mobs_mc.check_snow_golem_summon(pos, placer)
	end,
	description = S("Carved Pumpkin"),
	groups = table.merge(tpl_pumpkin.groups, {
		armor = 1, armor_head = 1, non_combat_armor = 1, non_combat_armor_head = 1
	}),
	on_secondary_use = mcl_armor.equip_on_use,
	tiles = {
		"farming_pumpkin_top.png", "farming_pumpkin_top.png", "farming_pumpkin_side.png",
		"farming_pumpkin_side.png", "farming_pumpkin_side.png", "farming_pumpkin_face.png"
	}
}))

core.register_node("mcl_farming:pumpkin_face_light", table.merge({
	_doc_items_longdesc = S("A jack o'lantern is a traditional Halloween decoration made from a pumpkin. It glows brightly."),
	after_place_node = function(pos, placer)
		mobs_mc.check_iron_golem_summon(pos, placer)
		mobs_mc.check_snow_golem_summon(pos, placer)
	end,
	description = S("Jack o'Lantern"),
	groups = {
		axey = 1, building_block = 1, dig_by_piston = 1, handy = 1, pumpkin = 1, unsticky = 1
	},
	light_source = core.LIGHT_MAX,
	paramtype = "light",
	tiles = {
		"farming_pumpkin_top.png", "farming_pumpkin_top.png", "farming_pumpkin_side.png",
		"farming_pumpkin_side.png", "farming_pumpkin_side.png", "farming_pumpkin_face_light.png"
	}
}))
-- Items
core.register_craftitem("mcl_farming:pumpkin_seeds", {
	_doc_items_longdesc = S("Grows into a pumpkin stem which in turn grows pumpkins. Chickens like pumpkin seeds."),
	_doc_items_usagehelp = S("Place the pumpkin seeds on farmland (which can be created with a hoe) to plant a pumpkin stem. Pumpkin stems grow in sunlight and grow faster on hydrated farmland. When mature, the stem attempts to grow a pumpkin next to it. Rightclick an animal to feed it pumpkin seeds."),
	_mcl_places_plant = "mcl_farming:pumpkin_1",
	_tt_help = S("Grows on farmland"),
	description = S("Pumpkin Seeds"),
	groups = {compostability = 30, craftitem = 1},
	inventory_image = "mcl_farming_pumpkin_seeds.png",
	on_place = function(itemstack, placer, pointed_thing)
		return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:pumpkin_1")
	end
})

core.register_craftitem("mcl_farming:pumpkin_pie", {
	_doc_items_longdesc = S("A pumpkin pie is a tasty food item which can be eaten."),
	_mcl_saturation = 4.8,
	description = S("Pumpkin Pie"),
	groups = {compostability = 100, eatable = 8, food = 2},
	inventory_image = "mcl_farming_pumpkin_pie.png",
	on_place = core.item_eat(8),
	on_secondary_use = core.item_eat(8),
	wield_image = "mcl_farming_pumpkin_pie.png"
})
-- Crafting
core.register_craft({
	output = "mcl_farming:pumpkin_face_light",
	recipe = {
		{"mcl_farming:pumpkin_face"},
		{"mcl_torches:torch"}
	}
})

core.register_craft({
	output = "mcl_farming:pumpkin_pie",
	recipe = {"mcl_core:sugar", "mcl_farming:pumpkin", "mcl_throwing:egg"},
	type = "shapeless"
})

core.register_on_joinplayer(function(player)
	if player:get_inventory():get_stack("armor", 2):get_name() == "mcl_farming:pumpkin_face" then
		add_pumpkin_hud(player)
	end
end)

core.register_on_dieplayer(function(player)
	if not core.settings:get_bool("mcl_keepInventory") then
		remove_pumpkin_hud(player)
	end
end)

core.register_on_leaveplayer(function(player)
	pumpkin_hud[player] = nil
end)
-- Register stem growth
mcl_farming:add_plant("plant_pumpkin_stem", "mcl_farming:pumpkintige_unconnect", {"mcl_farming:pumpkin_1", "mcl_farming:pumpkin_2", "mcl_farming:pumpkin_3", "mcl_farming:pumpkin_4", "mcl_farming:pumpkin_5", "mcl_farming:pumpkin_6", "mcl_farming:pumpkin_7"}, 30, 5)
-- Register actual pumpkin, connected stems and stem-to-pumpkin growth
mcl_farming.add_gourd("mcl_farming:pumpkintige_unconnect", "mcl_farming:pumpkintige_linked", "mcl_farming:pumpkin",30, 15)
