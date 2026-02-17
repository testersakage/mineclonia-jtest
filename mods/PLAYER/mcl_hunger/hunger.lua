local SPEED_WHILE_EAT = tonumber(core.settings:get("movement_speed_crouch")) / tonumber(core.settings:get("movement_speed_walk"))

function mcl_hunger.can_eat_when_full (player, itemstack)
	return (mcl_hunger.active == false)
		or (core.get_item_group (itemstack:get_name (), "can_eat_when_full") == 1)
		or core.is_creative_enabled(player:get_player_name())
end

-- wrapper for core.item_eat (this way we make sure other mods can't break this one)
function core.do_item_eat(hunger_points, replace_with_item, itemstack, user, pointed_thing)
	if not user or not user.is_player or not user:is_player() or user.is_fake_player then return itemstack end

	local rc = mcl_util.call_on_rightclick (itemstack, user, pointed_thing)
	if rc then
		return rc
	end

	local itemname = itemstack:get_name()
	local playername = user:get_player_name()
	local creative = core.is_creative_enabled(playername)
	local def = core.registered_items[itemname]

	local old_itemstack = itemstack

	if mcl_hunger.active and hunger_points then
		mcl_hunger.saturate(playername, core.registered_items[itemname]._mcl_saturation or 0, false)

		local h = mcl_hunger.get_hunger(user)
		mcl_hunger.set_hunger(user, h + hunger_points, true)

	elseif not mcl_hunger.active and hunger_points then
		mcl_damage.heal_player (user, hunger_points)
	end

	if not creative then
		itemstack:take_item()
		local nstack = ItemStack(replace_with_item)
		local inv = user:get_inventory()
		if itemstack:is_empty () then
			itemstack:add_item(replace_with_item)
		elseif inv:room_for_item("main",nstack) then
			inv:add_item("main", nstack)
		else
			core.add_item(user:get_pos(), nstack)
		end
	end

	for _, callback in pairs(core.registered_on_item_eats) do
		local result = callback(hunger_points, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
		if result then
			return result
		end
	end

	return itemstack
end

function mcl_hunger.eat(hunger_points, replace_with_item, itemstack, user, _)
	local item = itemstack:get_name()
	local def = mcl_hunger.registered_foods[item]
	if not def then
		def = {}
		if type(hunger_points) ~= "number" then
			hunger_points = 1
			core.log("error", "Wrong on_use() definition for item '" .. item .. "'")
		end
		def.saturation = hunger_points
		def.replace = replace_with_item
	end
	local func = mcl_hunger.item_eat(def.saturation, def.replace, def.poisontime, def.poison, def.exhaust, def.poisonchance)
	return func(itemstack, user)
end

-- Reset HUD bars after food poisoning

function mcl_hunger.reset_bars_poison_hunger(player)
	hb.change_hudbar(player, "hunger", nil, nil, "hbhunger_icon.png", nil, "hbhunger_bar.png")
	if mcl_hunger.debug then
		hb.change_hudbar(player, "exhaustion", nil, nil, nil, nil, "mcl_hunger_bar_exhaustion.png")
	end
end

local poisonrandomizer = PcgRandom(os.time())

function mcl_hunger.item_eat(hunger_points, replace_with_item, poisontime, poison, exhaust, poisonchance)
	return function(itemstack, user)
		if not user or not user.is_player or not user:is_player() or user.is_fake_player then return itemstack end
		local itemname = itemstack:get_name()
		local creative = core.is_creative_enabled(user:get_player_name())
		if itemstack:peek_item() and user then
			if not creative then
				itemstack:take_item()
			end
			local name = user:get_player_name()
			local def = core.registered_items[itemname]

			if mcl_hunger.active and hunger_points then
				-- Add saturation (must be defined in item table)
				local _mcl_saturation = core.registered_items[itemname]._mcl_saturation
				local saturation
				if not _mcl_saturation then
					saturation = 0
				else
					saturation = core.registered_items[itemname]._mcl_saturation
				end
				mcl_hunger.saturate(name, saturation, false)

				-- Add food points
				local h = mcl_hunger.get_hunger(user)
				if h < 20 and hunger_points then
					h = h + hunger_points
					if h > 20 then h = 20 end
					mcl_hunger.set_hunger(user, h, false)
				end

				hb.change_hudbar(user, "hunger", h)
				mcl_hunger.update_saturation_hud(user, mcl_hunger.get_saturation(user), h)
			elseif not mcl_hunger.active and hunger_points then
			   -- Is this code still reachable?
			   mcl_damage.heal_player (user, hunger_points)
			end
			-- Poison
			if mcl_hunger.active and poisontime then
				local do_poison = false
				if poisonchance then
					if poisonrandomizer:next(0,100) < poisonchance then
						do_poison = true
					end
				else
					do_poison = true
				end
				if do_poison then
					mcl_potions.give_effect_by_level("hunger", user, exhaust, poisontime)
				end
			end

			if not creative then
				local nstack = ItemStack(replace_with_item)
				local inv = user:get_inventory()
				if itemstack:is_empty () then
					itemstack:add_item(replace_with_item)
				elseif inv:room_for_item("main",nstack) then
					inv:add_item("main", nstack)
				else
					core.add_item(user:get_pos(), nstack)
				end
			end
		end
		return itemstack
	end
end

function mcl_hunger.is_player_full (player)
	return mcl_hunger.get_hunger (player) >= 20
end
