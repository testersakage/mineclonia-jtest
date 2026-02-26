mcl_hunger.prevent_eating = function() end

local function use(itemstack, player, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	if rc then
		return rc
	end

	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name ()
	local pointed_thing = mcl_util.get_pointed_thing (player, true)

	if mcl_hunger.is_player_full(player) and not mcl_hunger.can_eat_when_full(player, itemstack) then
		return
	end

	local def = core.registered_items[itemname]
	local hunger_points = core.get_item_group(itemname, "eatable")

	itemstack = core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
	if itemstack then
		player:set_wielded_item(itemstack)
	end
end

core.register_on_mods_loaded(function()
	for name, def in pairs(core.registered_items) do
		if core.get_item_group(name, "food") ~= 0 then
			core.override_item(name, {
				on_place = use,
				on_secondary_use = use,
			})
		end
	end
end)
