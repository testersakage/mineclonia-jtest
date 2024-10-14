local mob_class = mcl_mobs.mob_class

local SIGHT_PERSISTENCE = 3.0

function mob_class:do_attack(obj, persistence)
	if self.dead or obj == self.obj or obj == self.attack then
		return
	end

	-- Attack!!!
	local mover = self:mob_controlling_movement ()
	self.attack = obj
	self.attacking = false
	mover:set_animation ("run")

	-- Abandon after obj disappears for longer than three seconds.
	self.target_invisible_time = persistence or SIGHT_PERSISTENCE
	self._sight_persistence = persistence or SIGHT_PERSISTENCE
end

-- blast damage to entities nearby
local function blast_damage(pos, radius, source)
	radius = radius * 2

	for obj in minetest.objects_inside_radius(pos, radius) do

		local obj_pos = obj:get_pos()
		local dist = vector.distance(pos, obj_pos)
		if dist < 1 then dist = 1 end

		local damage = math.floor((4 / dist) * radius)

		-- punches work on entities AND players
		obj:punch(source, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = damage},
		}, vector.direction(pos, obj_pos))
	end
end

function mob_class:entity_physics(pos,radius) return blast_damage(pos,radius, self.object) end

function mob_class:attack_player_allowed (player)
	return mcl_vars.difficulty ~= 0
		and mcl_gamemode.get_gamemode (player) ~= "creative"
end

-- dogshoot attack switch and counter function
function mob_class:dogswitch(dtime)

	-- switch mode not activated
	if not self.dogshoot_switch
	or not dtime then
		return 0
	end

	self.dogshoot_count = self.dogshoot_count + dtime

	if (self.dogshoot_switch == 1
	and self.dogshoot_count > self.dogshoot_count_max)
	or (self.dogshoot_switch == 2
	and self.dogshoot_count > self.dogshoot_count2_max) then

		self.dogshoot_count = 0

		if self.dogshoot_switch == 1 then
			self.dogshoot_switch = 2
		else
			self.dogshoot_switch = 1
		end
	end

	return self.dogshoot_switch
end

function mob_class:standing_on_walkable ()
	local def = minetest.registered_nodes [self.standing_on]
	return def and def.walkable
end

-- Apply projectile knockback.
function mob_class:projectile_knockback (factor, dir)
	local velocity = self.object:get_velocity ()
	local standing = self:standing_on_walkable ()
	local knockback
		= mcl_util.calculate_knockback (velocity, factor * 0.5, standing, dir.x, dir.z)

	if self.animation.run_end then
		self:set_animation ("run")
	elseif self.animation.walk_end then
		self:set_animation ("walk")
	end
	self.frame_speed_multiplier=2.3
	self.object:set_velocity (knockback)
	minetest.after(0.2, function()
			       if self and self.object then
				       self.frame_speed_multiplier=1
			       end
	end)
end

-- Register damage delivered otherwise than as punches and retaliate.
function mob_class:register_damage (cmi_reason)
	local source = cmi_reason.source

	if not source then
		return
	end

	if source:is_player () and source:get_player_name () == self.owner then
		return
	end

	-- Attack puncher if necessary.
	if ( self.passive == false or self.retaliates )
		and (self.child == false or self.type == "monster") then
		self:do_attack (source, 15)
	end

	if source then
		self._recent_attacker = source
		self._recent_attacker_age = 0
	end
end

-- deal damage and effects when mob punched
function mob_class:on_punch(hitter, tflp, tool_capabilities, dir)
	local is_player = hitter and hitter:is_player()
	local hitter_playername = is_player and hitter:get_player_name()
	if hitter_playername and hitter_playername ~= "" then
		doc.mark_entry_as_revealed(hitter_playername, "mobs", self.name)
		mcl_potions.update_haste_and_fatigue(hitter)
	end

	if self.do_punch then
		if self.do_punch(self, hitter, tflp, tool_capabilities, dir) == false then
			return
		end
	end

	-- error checking when mod profiling is enabled
	if not tool_capabilities then
		minetest.log("warning", "[mobs] Mod profiling enabled, damage not enabled")
		return
	end

	if is_player then
		self.last_player_hit_time = minetest.get_gametime()
		self.last_player_hit_name = hitter_playername
		-- is mob protected?
		if self.protected and minetest.is_protected(self.object:get_pos(), hitter_playername) then
			return
		end

		-- set/update 'drop xp' timestamp if hit by player
		self.xp_timestamp = minetest.get_us_time()
	end


	-- punch interval
	local weapon = hitter:get_wielded_item()
	local punch_interval = 1.4

	-- exhaust attacker
	if is_player then
		mcl_hunger.exhaust(hitter_playername, mcl_hunger.EXHAUST_ATTACK)
	end

	-- calculate mob damage
	local damage = 0
	local armor = self.object:get_armor_groups() or {}

	for group,_ in pairs( (tool_capabilities.damage_groups or {}) ) do

		local tmp = tflp / (tool_capabilities.full_punch_interval or 1.4)

		if tmp < 0 then
			tmp = 0.0
		elseif tmp > 1 then
			tmp = 1.0
		end

		damage = damage + (tool_capabilities.damage_groups[group] or 0)
			* tmp * ((armor[group] or 0) / 100.0)
	end

	-- strength and weakness effects
	local strength = mcl_potions.get_effect(hitter, "strength")
	local weakness = mcl_potions.get_effect(hitter, "weakness")
	local str_fac = strength and strength.factor or 1
	local weak_fac = weakness and weakness.factor or 1
	damage = damage * str_fac * weak_fac

	if weapon then
		local fire_aspect_level = mcl_enchanting.get_enchantment(weapon, "fire_aspect")
		if fire_aspect_level > 0 then
			mcl_burning.set_on_fire(self.object, fire_aspect_level * 4)
		end
	end

	-- healing
	if damage <= -1 then
		self.health = self.health - damage
		return
	end

	if tool_capabilities then
		punch_interval = tool_capabilities.full_punch_interval or 1.4
	end

	-- To enable our custom health handling ("health" property) we use the
	-- "immortal" group to disable engine damage and wear handling, so we
	-- need to roll our own.
	if is_player
	and minetest.is_creative_enabled(hitter_playername) ~= true
	and tool_capabilities
	and tool_capabilities.punch_attack_uses
	and tool_capabilities.punch_attack_uses > 0 then
		local weapon = hitter:get_wielded_item()
		local wear = math.floor(65535/tool_capabilities.punch_attack_uses)
		weapon:add_wear(wear)
		hitter:set_wielded_item(weapon)
	end

	local die = false


	if damage >= 0 then
		-- only play hit sound and show blood effects if damage is 1 or over; lower to 0.1 to ensure armor works appropriately.
		if damage >= 0.1 then
			-- weapon sounds
			if weapon:get_definition().sounds ~= nil then

				local s = math.random(0, #weapon:get_definition().sounds)

				minetest.sound_play(weapon:get_definition().sounds[s], {
					object = self.object, --hitter,
					max_hear_distance = 8
				}, true)
			else
				minetest.sound_play("default_punch", {
					object = self.object,
					max_hear_distance = 5
				}, true)
			end

			self:damage_effect(damage)

			-- do damage
			local mcl_reason = {}
			mcl_damage.from_punch(mcl_reason, hitter)
			mcl_damage.finish_reason(mcl_reason)
			mcl_util.deal_damage(self.object, damage, mcl_reason)

			-- skip future functions if dead, except alerting others
			if self:check_for_death( "hit", {type = "punch", puncher = hitter}) then
				die = true
			end
		end
	end -- END if damage

	-- knock back effect (only on full punch)
	if (damage >= 0 or tool_capabilities.damage_groups.snowball_vulnerable
		or tool_capabilities.damage_groups.egg_vulnerable)
		and (self.knock_back and tflp >= punch_interval) then
		-- direction error check
		dir = dir or {x = 0, y = 0, z = 0}

		local v = self.object:get_velocity()
		if not v then return end
		local r = 1.4 - math.min(punch_interval, 1.4)
		local kb = r

		if die==true then
			kb=kb*2
		end

		-- check if tool already has specific knockback value
		if tool_capabilities.damage_groups["knockback"] then
			kb = tool_capabilities.damage_groups["knockback"]
		else
			kb = kb * 1.5
		end


		local luaentity
		if hitter then
			luaentity = hitter:get_luaentity()
		end
		if is_player then
			local wielditem = hitter:get_wielded_item()
			kb = kb + mcl_enchanting.get_enchantment(wielditem, "knockback")
		elseif luaentity and luaentity._knockback then
			kb = kb + luaentity._knockback
		end
		self.frame_speed_multiplier=2.3
		if self.animation.run_end then
			self:set_animation( "run")
		elseif self.animation.walk_end then
			self:set_animation( "walk")
		end
		minetest.after(0.2, function()
				       if self and self.object then
					       self.frame_speed_multiplier=1
				       end
		end)

		local standing = self:standing_on_walkable ()
		v = mcl_util.calculate_knockback (v, kb * 0.5, standing, dir.x, dir.z)
		self.object:set_velocity (v)
	end

	-- if skittish then run away
	if hitter and hitter:get_pos ()
		and not die and self.runaway == true then
		self:do_runaway (hitter)
	end

	-- attack puncher
	if ( self.passive == false or self.retaliates )
	and (self.child == false or self.type == "monster")
	and hitter_playername ~= self.owner
	and not mcl_mobs.invis[ hitter_playername or ""] then
		if not die then
			-- attack whoever punched mob
			self:do_attack (hitter, 15)
		end
	end

	-- alert others to the attack
	if hitter and hitter:get_pos() then
		self:call_group_attack(hitter)
	end
end

function mob_class:do_runaway ()
	self.runaway_timer = 5
end

function mob_class:call_group_attack(hitter)
	local name = hitter:get_player_name()
	for obj in minetest.objects_inside_radius(hitter:get_pos(), self.view_range) do
		local ent = obj:get_luaentity()
		if ent then
			-- only alert members of same mob or friends
			if ent.group_attack
			and ent.state ~= "attack"
			and ent.owner ~= name then
				if ent.name == self.name then
					ent:do_attack(hitter)
				elseif type(ent.group_attack) == "table" then
					if table.indexof(ent.group_attack, self.name) ~= -1 then
						ent:do_attack(hitter)
					end
				end
			end

			-- have owned mobs attack player threat
			if ent.owner == name and ent.owner_loyal then
				ent:do_attack(self.object)
			end
		end
	end
end


function mob_class:should_attack (object)
	local entity = object:get_luaentity ()
	local specific = self.specific_attack or {}
	if object == self.object then
		return false
	elseif entity and entity.is_mob then
		if self.attack_animals and entity.passive then
			return true
		end

		if self.attack_npcs and entity.type == "npc" then
			return true
		end

		if self.attacks_monsters and entity.type == "monster" then
			return true
		end

		if table.indexof (specific, entity.name) ~= -1 then
			return true
		end
	elseif object:is_player () and self:attack_player_allowed (object) then
		return self.type == "monster" or table.indexof (specific, "player") ~= -1
	end

	return false
end

function mob_class:should_continue_to_attack (object)
	if object:is_player () and not self:attack_player_allowed (object) then
		return false
	end
	local entity = object:get_luaentity ()
	if entity and entity.is_mob and entity.dead then
		return false
	end
	return object:get_hp () > 0
end

function mob_class:attack_bowshoot (self_pos, dtime, target_pos, line_of_sight)
	if not self.attacking then
		-- Initialize parameters consulted during the attack.
		self._target_visible_time = 0
		self._strafe_time = -1 -- Don't strafe.
		self._z_strafe = 1
		self._x_strafe = 1
		self._shoot_time = nil
		self._shoot_timer = 0
		self.attacking = true
	end
	local vistime = self._target_visible_time
	local dist = vector.distance (self_pos, target_pos)
	local shoot_pos = {
		x = self_pos.x,
		y = self_pos.y + self.shoot_offset,
		z = self_pos.z,
	}
	local target_bb = self.attack:get_properties ()
	local collisionbox = target_bb.collisionbox
	local target = {
		x = target_pos.x,
		y = target_pos.y + (collisionbox[5] - collisionbox[2]) * 0.33,
		z = target_pos.z,
	}

	if line_of_sight then
		if vistime < 0 then
			vistime = 0
		end
		vistime = vistime + dtime
	else
		if vistime > 0 then
			vistime = 0
		end
		vistime = vistime - dtime
	end

	-- Stop if the target is in range and has been for a second.
	if dist < 15 and vistime >= 1 then
		self:cancel_navigation ()
		self:halt_in_tracks (false, true)
		self._strafe_time = self._strafe_time + dtime
	else
		if self:check_timer ("bowshoot_pathfind", 0.5) then
			self:gopath (target_pos, nil, true)
		end
		self._strafe_time = -1
	end

	-- Potentially switch directions after having strafed
	-- for 1 second.
	if self._strafe_time >= 1 then
		if math.random (10) <= 3 then
			self._z_strafe = -self._z_strafe
		end
		if math.random (10) <= 3 then
			self._x_strafe = -self._x_strafe
		end
		self._strafe_time = 0
	end
	local mover = self:mob_controlling_movement ()
	-- Target in range?
	if self._strafe_time > -1 then
		-- Don't allow target to approach too close or move
		-- too far.
		if dist > 15 * 0.75 then
			self._z_strafe = 1
		elseif dist < 15 * 0.55 then
			self._z_strafe = -1
		end

		mover.movement_goal = "strafe"
		mover.movement_velocity = mover.movement_speed * 0.25
		mover.strafe_direction = {
			x = self._x_strafe * 0.5,
			z = self._z_strafe * 0.5,
		}
		self:look_at (target_pos)
		if not self._shoot_time or self ~= mover then
			mover:set_animation ("run")
		else
			mover:set_animation ("shoot")
		end
	end

	if not self._shoot_time then
		if self._shoot_timer <= 0 and vistime >= -3 then
			if line_of_sight then
				if self == mover then
					mover:set_animation ("shoot")
				end
				self._shoot_time = 0
				self._shoot_timer = 0
			end
		else
			self._shoot_timer = self._shoot_timer - dtime
		end
	else
		-- If no longer visible, clear shooting counter.
		if not line_of_sight and vistime < -3 then
			mover:set_animation ("run")
			self.shoot_time = nil
		elseif line_of_sight and self._shoot_time > 1 then
			-- Fire arrow.
			self._shoot_time = nil
			self._shoot_timer = self.shoot_interval or 1
			mover:set_animation ("run")

			local vec = {
				x = target.x - shoot_pos.x,
				y = target.y - shoot_pos.y,
				z = target.z - shoot_pos.z,
			}

			-- Offset by distance.
			vec.y = vec.y + 0.12 * vector.length (vec)

			if self.shoot_arrow then
				local offset = self.shoot_offset
				local origin = vector.offset (self_pos, 0, offset, 0)
				vec = vector.normalize (vec)
				self:shoot_arrow (origin, vec)
			end
		else
			self._shoot_time = self._shoot_time + dtime
		end
	end

	self._target_visible_time = vistime
end

function mob_class:custom_attack ()
	-- Punch player (or what player is attached to)
	local attached = self.attack:get_attach ()
	local attack = self.attack
	if attached then
		attack = attached
	end
	local damage = {
		full_punch_interval = 1.0,
		damage_groups = {fleshy = self.damage},
	}
	self:set_animation ("punch")
	self:mob_sound ("attack")
	attack:punch (self.object, 1.0, damage, nil)

	if self.dealt_effect then
		local duration = self.dealt_effect.dur
		if mcl_vars.difficulty <= 1 and self.dealt_effect.dur_easy then
			duration = self.dealt_effect.dur_easy
		elseif mcl_vars.difficulty > 2 and self.dealt_effect.dur_hard then
			duration = self.dealt_effect.dur_hard
		end

		if self.dealt_effect.respect_local_difficulty then
			local self_pos = self.object:get_pos ()
			local factor = mcl_worlds.get_regional_difficulty (self_pos)
			duration = duration * factor
		end
		if duration > 0 then
			mcl_potions.give_effect_by_level (self.dealt_effect.name, attack,
							  self.dealt_effect.level, duration)
		end
	end
end

function mob_class:attack_melee (self_pos, dtime, target_pos, line_of_sight)
	if not self.attacking then
		-- Initialize attack parameters.
		self._target_pos = nil
		self._gopath_delay = 0
		self._attack_delay = 0
		self.attacking = true
	end

	local delay = math.max (self._gopath_delay - dtime, 0)
	local distance = vector.distance (self_pos, target_pos)

	-- If the target is detectable...
	if (self.esp or line_of_sight)
		-- ...and the navigation timeout has elapsed...
		and delay == 0
		-- ..and this mob has yet to arrive at its target, or
		-- the path should be recomputed...
		and (not self._target_pos
			or vector.distance (target_pos, self._target_pos) >= 1
			or math.random (100) <= 5) then
		self._target_pos = target_pos

		delay = (4 + math.random (8) - 1) / 20.0

		-- How distant is the target?
		if distance > 32 then
			delay = delay + 0.5
		elseif distance > 16 then
			delay = delay + 0.25
		end

		-- Try to pathfind.
		if not self:gopath (target_pos, nil, true) then
			delay = delay + 0.75
		end
	end
	self._gopath_delay = delay

	-- Can the target be attacked?
	local delay = math.max (self._attack_delay - dtime, 0)
	if distance <= self.reach and delay == 0 and line_of_sight then
		self:look_at (target_pos)
		self:custom_attack ()
		delay = self.melee_interval
	end
	self._attack_delay = delay
end

function mob_class:discharge_ranged (self_pos, target_pos)
	local p = vector.offset (target_pos, 0, -0.5, 0)
	local s = vector.offset (self_pos, 0, 0.5, 0)
	local vec = {
		x = p.x - s.x,
		y = p.y - s.y,
		z = p.z - s.z
	}

	self:mob_sound ("shoot_attack")
	-- Shoot arrow
	if minetest.registered_entities[self.arrow] or self.shoot_arrow then
		s.y = s.y + (self.collisionbox[2] + self.collisionbox[5]) / 2
		local v = 1
		local arrow
		if not self.shoot_arrow then
			self.firing = true
			minetest.after(1, function(self)
					       self.firing = false
			end, self)
			arrow = minetest.add_entity(s, self.arrow)
			local ent = arrow:get_luaentity()
			if ent.velocity then
				v = ent.velocity
			end
			ent.switch = 1
			ent.owner_id = tostring(self.object) -- add unique owner id to arrow

			-- important for mcl_shields
			ent._shooter = self.object
			ent._saved_shooter_pos = self.object:get_pos()
			if ent.homing then
				ent._target = self.attack
			end
		end

		local amount = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
		-- offset makes shoot aim accurate
		vec.y = vec.y + self.shoot_offset
		vec.x = vec.x * (v / amount)
		vec.y = vec.y * (v / amount)
		vec.z = vec.z * (v / amount)

		if self.shoot_arrow then
			vec = vector.normalize (vec)
			arrow = self:shoot_arrow (s, vec)
		end

		if arrow then
			arrow:set_velocity(vec)
		end
	end
end

function mob_class:attack_ranged (self_pos, dtime, target_pos, line_of_sight)
	local vistime, min_distance
	if not self.attacking then
		self._target_visible_time = 0
		self._shoot_timer = self.ranged_interval_min
		self.attacking = true
	end
	vistime = self._target_visible_time

	if line_of_sight then
		vistime = vistime + dtime
	else
		vistime = 0
	end
	self._target_visible_time = vistime
	min_distance = self.ranged_attack_radius

	local distance = vector.distance (self_pos, target_pos)
	if distance < min_distance and vistime > 0.25 then
		self:cancel_navigation ()
		self:halt_in_tracks ()
	else
		if self:check_timer ("ranged_pathfind", 0.5) then
			self:gopath (target_pos)
		end
	end
	local shoot_time = self._shoot_timer
	shoot_time = math.max (0, shoot_time - dtime)
	if line_of_sight and self:navigation_finished () then
		self:look_at (target_pos)
	end
	if shoot_time == 0 then
		if line_of_sight then
			-- Attack target.
			self:discharge_ranged (self_pos, target_pos)

			-- Derive the delay from the distance to the
			-- target.
			local rem = distance / min_distance
			local rem = math.max (0.1, math.min (1.0, rem))
			self._shoot_timer = rem * (self.ranged_interval_max
							- self.ranged_interval_min)
				+ self.ranged_interval_min
			return
		end

		-- Likewise, but don't confine it to a fixed
		-- range.
		local rem = distance / min_distance
		self._shoot_timer = rem * (self.ranged_interval_max
					   - self.ranged_interval_min)
			+ self.ranged_interval_min
	else
		self._shoot_timer = shoot_time
	end
end

function mob_class:check_attack (self_pos, dtime)
	if not self.attack_type then
		return false
	end
	if not self.attack then
		if not self:check_timer ("seek_target", 0.5) then
			return false
		end

		if self.attack_custom then
			self:attack_custom ()
		else
			local target, max_distance
			local objects
				= minetest.get_objects_inside_radius (self_pos, self.view_range)
			for _, object in ipairs (objects) do
				if self:should_attack (object) then
					local pos = object:get_pos ()
					local factor = 1.0
					if object:is_player () then
						local factors = mcl_armor.player_view_range_factors[object]
						if factors then
							factor = factors[self.name] or 1.0
						end
					end
					local distance = vector.distance (self_pos, pos)
					if distance <= self.view_range * factor
						and (not max_distance or distance < max_distance)
						and (self.esp or self:target_visible (self_pos, object)) then
						target = object
						max_distance = distance
					end
				end
			end

			if target then
				self:do_attack (target)
				return "attack"
			end
		end
	else
		local target_pos
		local mover = self:mob_controlling_movement ()
		if not self.attack:is_valid () then
			self.attack = nil
			mover:set_animation ("stand")
			return true
		end
		-- If it's no longer possible to attack the
		-- target, abandon it immediately.
		if not self:should_continue_to_attack (self.attack) then
			self.attack = nil
			mover:set_animation ("stand")
			return true
		end
		target_pos = self.attack:get_pos ()
		local distance = vector.distance (self_pos, target_pos)
		if distance > self.tracking_distance then
			self.attack = nil
			mover:set_animation ("stand")
			return true
		end
		local line_of_sight = self:target_visible (self_pos, self.attack)
		if not self.esp and not line_of_sight then
			local t = self.target_invisible_time
			self.target_invisible_time = t - dtime

			if t < 0 then
				self.attack = nil
				mover:set_animation ("stand")
				return true
			end
		else
			self.target_invisible_time = self._sight_persistence
		end

		local attack_type = self.attack_type
		if attack_type == "null" then
			if self.attack_null then
				self:attack_null (self_pos, dtime, target_pos, line_of_sight)
			end
		elseif attack_type == "bowshoot" then
			self:attack_bowshoot (self_pos, dtime, target_pos,
					      line_of_sight)
		elseif attack_type == "crossbow" then
			-- TODO
		elseif attack_type == "ranged" then
			self:attack_ranged (self_pos, dtime, target_pos, line_of_sight)
		elseif attack_type == "melee" then
			self:attack_melee (self_pos, dtime, target_pos, line_of_sight)
		else
			minetest.log ("warning", "unknown attack type " .. self.attack_type)
		end

		return true
	end
	return false
end
