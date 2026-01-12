local SPEED_WHILE_EAT = tonumber(core.settings:get("movement_speed_crouch")) / tonumber(core.settings:get("movement_speed_walk"))

local eat_anim_enabled = core.settings:get_bool("mcl_eat_anim", true)

local function can_eat_when_full (itemstack)
	return (mcl_hunger.active == false)
		or (core.get_item_group (itemstack:get_name (), "can_eat_when_full") == 1)
end

local function is_eat_anim_possible (player, key)
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
	if pinfo and pinfo.touch_controls then
		-- Trigger rightclick/formspec on touch controls
		if key == "LMB" then
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
		if key ~= "RMB" then
			return false
		end
	else
		if key ~= "RMB" then
			return false
		end
	end

	if mcl_hunger.eat_anim_block[player] then
		return false
	end

	local def = core.registered_items[itemname]
	local creative = core.is_creative_enabled (player:get_player_name ())
	local is_full = mcl_hunger.is_player_full (player)
	local hunger_points = core.get_item_group(itemname, "eatable")
	-- Instant eat when eat_anim disabled
	if not eat_anim_enabled and (creative or not is_full) then
		core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
		player:set_wielded_item (itemstack)
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

	local item = itemstack:get_name()
	local def = core.registered_items[item]
	local eat_delay = def._mcl_eat_delay or mcl_hunger.EAT_DELAY

	local is_still_eating = mcl_hunger.eat_duration[user] < eat_delay

	if not eat_anim_enabled
		or mcl_serverplayer.is_csm_at_least (user, 1) then
		is_still_eating = (mcl_hunger.eat_cooldown[user] or 0) > 0
	end

	if core.get_item_group(itemstack:get_name(), "no_eat_delay") > 0 then
		is_still_eating = false
	end

	if not can_eat_when_full (itemstack) and is_still_eating then
		return
	end

	local def = core.registered_items[itemstack:get_name()]
	if def and def._mcl_eat_effect then
		def._mcl_eat_effect(itemstack, user)
	end

	local foodtype = core.get_item_group(itemstack:get_name(), "food")
	if foodtype == 3 then
		core.sound_play("survival_thirst_drink", {
			max_hear_distance = 12,
			gain = 0.5,
			pitch = 1,
			object = user,
		}, true)
	else
		core.sound_play("mcl_hunger_eat", {
			max_hear_distance = 12,
			gain = 0.5,
			pitch = 1,
			object = user,
		}, true)
	end

	local old_itemstack = itemstack
	itemstack = mcl_hunger.eat(hunger_points, replace_with_item, itemstack, user, pointed_thing)
	for _, callback in pairs(core.registered_on_item_eats) do
		local result = callback(hunger_points, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
		if result then
			return result
		end
	end

	mcl_hunger.eat_cooldown[user] = eat_delay
	mcl_hunger.eat_duration[user] = -math.huge

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
			pitch = pitch or (1 + math.random(-10, 10) * 0.005),
			object = user,
		}, true)
		return
	end
	-- Assume the item is a food
	-- Add eat particle effect and sound
	local texture = item_def.inventory_image
	if not texture or texture == "" then
		texture = item_def.wield_image
	end
	-- Special item definition field: _mcl_spawn_food_particles
	-- If false, force item to not spawn any food partiles when eaten
	if item_def._mcl_spawn_food_particles ~= false and texture and texture ~= "" then
		-- get velocity once
		local v = user.get_velocity and user:get_velocity() or user:get_player_velocity() or {x=0, y=0, z=0}
		local count = math.min(math.max(8, hunger_points * 2), 25)
		local texture_index = math.random(0, count)
		core.add_particlespawner({
			amount = count,
			time = 0.01,
			minpos = pos,
			maxpos = pos,
			minvel = vector.add(v, { x = -1, y = 1, z = -1 }),
			maxvel = vector.add(v, { x =  1, y = 2, z =  1 }),
			minacc = { x = 0, y = -9, z = 0 },
			maxacc = { x = 0, y = -5, z = 0 },
			minexptime = 0.5,
			maxexptime = 0.8,
			minsize = 1,
			maxsize = 2,
			collisiondetection = true,
			vertical = false,
			texture = "[combine:3x3:" .. -texture_index .. "," .. -texture_index .. "=" .. texture,
		})
	end
	core.sound_play("mcl_hunger_bite", {
		max_hear_distance = 12,
		gain = 0.1,
		pitch = pitch or (1 + math.random(-10, 10) * 0.005),
		object = user,
	}, true)
end

function mcl_hunger.hud_eat_add(player)
	mcl_hunger.eat_duration[player] = 0
	player:hud_set_flags({wielditem = false})
end

function mcl_hunger.hud_eat_remove(player)
	mcl_hunger.eat_duration[player] = -math.huge
	mcl_hunger.eat_anim_effect[player] = nil
	player:hud_set_flags({wielditem = true})
	if core.get_modpath("playerphysics") then
		playerphysics.remove_physics_factor(player, "speed", "mcl_hunger:eat_anim")
	end
end

function mcl_hunger.is_player_full (player)
	return mcl_hunger.get_hunger (player) >= 20
end

function mcl_hunger.prevent_eating (player)
	mcl_hunger.eat_anim_block[player] = true
	mcl_hunger.hud_eat_remove(player)
end

if mcl_hunger.active then
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
end

core.register_on_joinplayer (function (player)
	mcl_hunger.eat_duration[player] = -math.huge
	player:hud_set_flags({wielditem = true})
end)

core.register_on_leaveplayer (function (player, _)
	mcl_hunger.eat_duration[player] = nil
	mcl_hunger.hud_eat_remove(player)
end)

core.register_on_dieplayer(function (player)
	mcl_hunger.prevent_eating(player)
end)

controls.register_on_press (function (player, key)
	if not is_eat_anim_possible (player, key) then
		return
	end
end)

controls.register_on_hold (function (player, key)
	if not is_eat_anim_possible (player, key) then
		return
	end

	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name ()
	local pointed_thing = mcl_util.get_pointed_thing (player, true)
	local is_full = mcl_hunger.is_player_full (player)
	local creative = core.is_creative_enabled (player:get_player_name ())

	if core.get_item_group(itemname, "no_eat_delay") > 0
		or (not can_eat_when_full (itemstack)
			and (not creative and is_full)) then
		return
	end

	local def = core.registered_items[itemname]
	local hunger_points = core.get_item_group(itemname, "eatable")

	-- Prioritize eat over shield block
	mcl_shields.players[player].blocking = 0

	-- Start eating animation
	if mcl_hunger.eat_duration[player] == -math.huge then
		mcl_hunger.hud_eat_add(player)
		if core.get_modpath("playerphysics") then
			playerphysics.add_physics_factor(player, "speed", "mcl_hunger:eat_anim", SPEED_WHILE_EAT)
		end
	end
	-- Eat animation sound & particle
	local step = math.floor(mcl_hunger.eat_duration[player] / 0.2)
	local last_step = mcl_hunger.eat_anim_effect[player] or 0
	if step > last_step then
		mcl_hunger.eat_anim_effect[player] = step
		mcl_hunger.eat_effects(player, itemname, player:get_pos(), hunger_points, def)
	end
	-- Actual eat
	local eat_delay = def._mcl_eat_delay or mcl_hunger.EAT_DELAY
	if mcl_hunger.eat_duration[player] >= eat_delay then
		core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
		player:set_wielded_item(itemstack)
		mcl_hunger.hud_eat_remove(player)
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
	mcl_hunger.hud_eat_remove(player)
	mcl_hunger.prevent_eating (player)
	-- reset eat animation blocking after a while
	core.after(0.2, function ()
		mcl_hunger.eat_anim_block[player] = nil
	end)
end)
