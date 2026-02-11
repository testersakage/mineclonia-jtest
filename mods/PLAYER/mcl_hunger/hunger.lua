local SPEED_WHILE_EAT = tonumber(core.settings:get("movement_speed_crouch")) / tonumber(core.settings:get("movement_speed_walk"))

local quick_eat_mode = core.settings:get_bool("mcl_hunger_instant_eat", true)

local function should_quick_eat(itemstack)
	return quick_eat_mode
		or not mcl_hunger.active
		or core.get_item_group(itemstack:get_name(), "no_eat_delay") > 0
end

local function can_eat_when_full (player, itemstack)
	return (mcl_hunger.active == false)
		or (core.get_item_group (itemstack:get_name (), "can_eat_when_full") == 1)
		or core.is_creative_enabled(player:get_player_name())
end

local function is_player_trying_to_eat(player, keypress)
	if mcl_serverplayer.is_csm_at_least (player, 1) then
		return false
	end

	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name ()
	if core.get_item_group(itemname, "food") == 0 then
		return false
	end

	local pointed_thing = mcl_util.get_pointed_thing (player, true)
	local pname = player:get_player_name ()
	local pinfo = core.get_player_window_information (pname)

	if pinfo and pinfo.touch_controls and keypress == "LMB" then
		-- Trigger rightclick/formspec on touch controls
		if pointed_thing and pointed_thing.type == "node" then
			local node = core.get_node (pointed_thing.under)
			local meta = core.get_meta (pointed_thing.under)
			local fs = meta:get_string ("formspec")
			if fs ~= "" then
				local pname = player:get_player_name ()
				core.show_formspec(pname, node.name, fs)
			end
		end
		mcl_util.call_on_rightclick (itemstack, player, pointed_thing)
		return false
	end

	if keypress ~= "RMB" then
		return false
	end

	if mcl_hunger.eat_anim_block[player] then
		return false
	end

	local rc = mcl_util.call_on_rightclick (itemstack, player, pointed_thing)
	if rc then
		player:set_wielded_item(rc)
		return false
	end

	return true
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
	local playerpos = user:get_pos()
	local creative = core.is_creative_enabled(playername)
	local def = core.registered_items[itemname]

	if def and def._mcl_eat_effect then
		def._mcl_eat_effect(itemstack, user)
	end

	local old_itemstack = itemstack

	mcl_hunger.eat_effects(user, itemname, playerpos, hunger_points, def)

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
			local pos = user:get_pos()
			local def = core.registered_items[itemname]

			mcl_hunger.eat_effects(user, itemname, pos, hunger_points, def)

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

function mcl_hunger.eat_effects(user, itemname, pos, hunger_points, item_def, pitch)
	if not (user and itemname and pos and hunger_points and item_def) then
		return false
	end
	-- player height
	pos.y = pos.y + 1.5
	local foodtype = core.get_item_group(itemname, "food")
	if foodtype == 3 then
		-- Item is a drink, only play drinking sound (no particle)
		core.sound_play("survival_thirst_drink", {
			max_hear_distance = 12,
			gain = 1.0,
			pitch = mcl_util.float_random(0.95, 1.05),
			object = user,
		}, true)
		return
	end

	local texture = item_def.inventory_image
	if not texture then
		texture = item_def.wield_image
	end

	if item_def._mcl_spawn_food_particles ~= false and texture and texture ~= "" then
		local player_velocity = user:get_velocity()
		local count = math.min(math.max(8, hunger_points * 2), 25)
		local texture_index = math.random(0, count)
		core.add_particlespawner({
			amount = count,
			time = 0.01,
			pos = pos,
			vel = {
				min = vector.offset(player_velocity, -1, 1, -1),
				max = vector.offset(player_velocity, 1, 2, 1)
			},
			acc = {
				min = vector.new(0, -9, 0),
				max = vector.new(0, -5, 0)
			},
			exptime = { min = 0.5, max = 0.8 },
			size    = { min = 1, max   = 2 },
			collisiondetection = true,
			vertical = false,
			texture = "[combine:3x3:" .. -texture_index .. "," .. -texture_index .. "=" .. texture,
		})
	end

	core.sound_play("mcl_hunger_bite", {
		max_hear_distance = 12,
		gain = 0.1,
		pitch = mcl_util.float_random(0.95, 1.05),
		object = user,
	}, true)
end

local function begin_eating_state(player)
	mcl_hunger.eat_duration[player] = 0
	player:hud_set_flags({wielditem = false})
	playerphysics.add_physics_factor(player, "speed", "mcl_hunger:eat_anim", SPEED_WHILE_EAT)
end

local function terminate_eating_state(player)
	mcl_hunger.eat_duration[player] = nil
	mcl_hunger.eat_anim_effect[player] = nil
	player:hud_set_flags({wielditem = true})
	playerphysics.remove_physics_factor(player, "speed", "mcl_hunger:eat_anim")
end

function mcl_hunger.is_player_full (player)
	return mcl_hunger.get_hunger (player) >= 20
end

function mcl_hunger.prevent_eating (player)
	mcl_hunger.eat_anim_block[player] = true
	terminate_eating_state(player)
end

local function perform_quick_eat(player)
	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name()
	local def = core.registered_items[itemname]
	local hunger_points = core.get_item_group(itemname, "eatable")
	local pointed_thing = mcl_util.get_pointed_thing (player, true)
	itemstack = core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
	if itemstack then
		player:set_wielded_item (itemstack)
	end

	mcl_hunger.eat_cooldown[player] = def._mcl_eat_delay or mcl_hunger.EAT_DELAY
end

controls.register_on_press (function (player, key)
	local itemstack = player:get_wielded_item ()
	if is_player_trying_to_eat(player, key)
			and should_quick_eat(itemstack)
			and (not mcl_hunger.is_player_full(player) or can_eat_when_full(player, itemstack))
			and (mcl_hunger.eat_cooldown[player] or 0) <= 0 then
		perform_quick_eat(player)
		return false
	end
end)

controls.register_on_hold (function (player, key)
	if not is_player_trying_to_eat (player, key) then
		-- special case. can happen when the player switches the wielded item while eating
		if key == "RMB" and mcl_hunger.eat_duration[player] then
			terminate_eating_state(player)
		end
		return
	end

	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name ()
	local pointed_thing = mcl_util.get_pointed_thing (player, true)
	local is_full = mcl_hunger.is_player_full (player)

	if is_full and not can_eat_when_full(player, itemstack) then
		return
	end

	if should_quick_eat(itemstack) then
		if (mcl_hunger.eat_cooldown[player] or 0) <= 0 then
			perform_quick_eat(player)
		end
		return
	end

	-- Prioritize eat over shield block
	mcl_shields.players[player].blocking = 0

	if not mcl_hunger.eat_duration[player] then
		begin_eating_state(player)
	end

	local def = core.registered_items[itemname]
	local hunger_points = core.get_item_group(itemname, "eatable")

	-- Eat animation sound & particle
	local step = math.floor(mcl_hunger.eat_duration[player] / 0.2)
	local last_step = mcl_hunger.eat_anim_effect[player] or 0
	if step > last_step then
		mcl_hunger.eat_anim_effect[player] = step
		mcl_hunger.eat_effects(player, itemname, player:get_pos(), hunger_points, def)
	end

	local eat_delay = def._mcl_eat_delay or mcl_hunger.EAT_DELAY
	if mcl_hunger.eat_duration[player] >= eat_delay then
		itemstack = core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
		if itemstack then
			player:set_wielded_item(itemstack)
		end
		terminate_eating_state(player)
	end
end)

core.register_globalstep (function (dtime)
	for player, time in pairs (mcl_hunger.eat_cooldown) do
		mcl_hunger.eat_cooldown[player] = time - dtime
	end
	for player, time in pairs (mcl_hunger.eat_duration) do
		mcl_hunger.eat_duration[player] = time + dtime
	end
end)

controls.register_on_release (function (player, key)
	if mcl_serverplayer.is_csm_at_least (player, 1) then
		return
	end
	if key ~= "RMB" then
		return
	end

	mcl_hunger.prevent_eating (player)
	-- reset eat animation blocking after a while
	core.after(0.2, function ()
		mcl_hunger.eat_anim_block[player] = nil
	end)
end)

-- player-action based hunger changes
core.register_on_dignode(function(_, _, player)
	-- is_fake_player comes from the pipeworks, we are not interested in those
	if not player or not player:is_player() or player.is_fake_player == true then
		return
	end
	local name = player:get_player_name()
	-- dig event
	mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_DIG)
end)

core.register_on_leaveplayer (function (player, _)
	terminate_eating_state(player)
	mcl_hunger.eat_cooldown[player] = nil
end)

core.register_on_dieplayer(function (player)
	mcl_hunger.prevent_eating(player)
end)
