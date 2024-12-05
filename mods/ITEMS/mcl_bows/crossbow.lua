local S = minetest.get_translator(minetest.get_current_modname())

local GRAVITY = 9.81
local BOW_DURABILITY = 385

-- Charging time in microseconds

local BOW_CHARGE_TIME_HALF = 350000 -- bow level 1
local BOW_CHARGE_TIME_FULL = 900000 -- bow level 2 (full charge)
mcl_bows.CROSSBOW_CHARGE_TIME_HALF = BOW_CHARGE_TIME_HALF / 1e+6
mcl_bows.CROSSBOW_CHARGE_TIME_FULL = BOW_CHARGE_TIME_FULL / 1e+6

local BOW_MAX_SPEED = 68

function mcl_bows.shoot_arrow_crossbow(arrow_item, pos, dir, yaw, shooter, power, damage, is_critical, crossbow_stack, collectable)
	local speed = BOW_MAX_SPEED
	local obj = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z}, arrow_item.."_entity")
	if not obj or not obj:get_pos() then return end
	if damage == nil then
		damage = 2
	end
	if crossbow_stack then
		local enchantments = mcl_enchanting.get_enchantments(crossbow_stack)
		if enchantments.piercing then
			obj:get_luaentity()._piercing = 1 * enchantments.piercing
		else
			obj:get_luaentity()._piercing = 0
		end
	end
	obj:set_velocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
	obj:set_acceleration({x=0, y=-GRAVITY, z=0})
	obj:set_yaw(yaw-math.pi/2)
	local le = obj:get_luaentity()
	le._shooter = shooter
	le._source_object = shooter
	le._damage = damage
	le._is_critical = is_critical
	le._startpos = pos
	le._collectable = collectable
	le._itemstring = arrow_item
	minetest.sound_play("mcl_bows_crossbow_shoot", {pos=pos, max_hear_distance=16}, true)
	if shooter and shooter:is_player() then
		if obj:get_luaentity().player == "" then
			obj:get_luaentity().player = shooter
		end
		obj:get_luaentity().node = shooter:get_inventory():get_stack("main", 1):get_name()
	end
	return obj
end

local function player_shoot_arrow(wielditem, player, power, damage, is_critical)
	local arrow_itemstring = wielditem:get_meta():get("arrow") or "mcl_bows:arrow"

	if minetest.get_item_group(arrow_itemstring, "ammo_crossbow") == 0 then
		return false
	end

	local playerpos = player:get_pos()
	local dir = player:get_look_dir()
	local yaw = player:get_look_horizontal()

	mcl_bows.shoot_arrow_crossbow (arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, dir, yaw, player, BOW_MAX_SPEED, nil, is_critical, player:get_wielded_item(), true)
	return true
end

local function reset_crossbow(player, stack)
	local m = stack:get_meta()
	m:set_int("bow_level", 0)
	m:set_string("inventory_image", "")
	m:set_string("wield_image", "")
	m:set_string("arrow", "")
	stack:set_name("mcl_bows:crossbow")
	player:set_wielded_item(stack)
end

local function crossbow_on_use(wielditem, player, _)
	local is_critical = false
	local speed = BOW_MAX_SPEED
	local damage
	local r = math.random(1,5)
	if r > 4 then
		-- 20% chance for critical hit (by default)
		damage = 10 + math.floor((r-5)/5) -- mega crit (over crit) with high luck
		is_critical = true
	else
		damage = 9
	end

	local has_shot = player_shoot_arrow(wielditem, player, speed, damage, is_critical)


	if has_shot and not minetest.is_creative_enabled(player:get_player_name()) then
		local durability = BOW_DURABILITY
		local unbreaking = mcl_enchanting.get_enchantment(wielditem, "unbreaking")
		local multishot = mcl_enchanting.get_enchantment(wielditem, "multishot")
		if unbreaking > 0 then
			durability = durability * (unbreaking + 1)
		end
		if multishot then
			durability = durability / 3
		end
		wielditem:add_wear(65535/durability)
	end
	reset_crossbow(player, wielditem)
end

mcl_bows.register_bow("mcl_bows:crossbow", {
	description = S("Crossbow"),
	_tt_help = S("Launches arrows"),
	_doc_items_longdesc = S("Crossbows are ranged weapons to shoot arrows at your foes.").."\n"..
S("The speed and damage of the arrow increases the longer you charge. The regular damage of the arrow is between 1 and 9. At full charge, there's also a 20% of a critical hit, dealing 10 damage instead."),
	_doc_items_usagehelp = S("To use the crossbow, you first need to have at least one arrow anywhere in your inventory (unless in Creative Mode). Hold down the right mouse button (or zoom key) to charge, release to load an arrow into the chamber, then to shoot press left mouse."),
	_doc_items_durability = BOW_DURABILITY,
	inventory_image = "mcl_bows_crossbow.png",
	groups = { crossbow = 1, bow_power = BOW_MAX_SPEED },
	_mcl_bows_loaded_item = "mcl_bows:crossbow_loaded",
	_mcl_bows_img_fmt = "mcl_bows_crossbow_%d.png",
	_mcl_bows_shoot_arrow = player_shoot_arrow,
	_mcl_bows_ammo_group = "ammo_crossbow",
	_mcl_uses = 326,
})

minetest.register_tool("mcl_bows:crossbow_loaded", {
	description = S("Crossbow"),
	_tt_help = S("Launches arrows"),
	_doc_items_longdesc = S("Crossbows are ranged weapons to shoot arrows at your foes.").."\n"..
S("The speed and damage of the arrow increases the longer you charge. The regular damage of the arrow is between 1 and 9. At full charge, there's also a 20% of a critical hit, dealing 10 damage instead."),
	_doc_items_usagehelp = S("To use the crossbow, you first need to have at least one arrow anywhere in your inventory (unless in Creative Mode). Hold down the right mouse button to charge, release to load an arrow into the chamber, then to shoot press left mouse."),
	_doc_items_durability = BOW_DURABILITY,
	inventory_image = "mcl_bows_crossbow_3.png",
	wield_scale = mcl_vars.tool_wield_scale,
	stack_max = 1,
	range = 4,
	on_use = crossbow_on_use,
	on_place = function() end,
	on_secondary_use = function () end,
	touch_interaction = "short_dig_long_place",
	groups = {weapon = 1, weapon_ranged = 1, crossbow = 5, enchantability = 1, not_in_creative_inventory = 1, offhand_item = 1},
	_mcl_uses = 326,
	_mcl_burntime = 15
})

minetest.register_craft({
	output = "mcl_bows:crossbow",
	recipe = {
		{"mcl_core:stick", "mcl_core:iron_ingot", "mcl_core:stick"},
		{"mcl_mobitems:string", "mcl_bows:arrow", "mcl_mobitems:string"},
		{"", "mcl_core:stick", ""},
	}
})

