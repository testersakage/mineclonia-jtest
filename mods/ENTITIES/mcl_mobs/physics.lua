local mob_class = mcl_mobs.mob_class

local ENTITY_CRAMMING_MAX = 24
local CRAMMING_DAMAGE = 3
local DEATH_DELAY = 0.5

local mobs_drop_items = minetest.settings:get_bool("mobs_drop_items") ~= false

-- check if within physical map limits (-30911 to 30927)
local function within_limits(pos, radius)
	local wmin, wmax = -30912, 30928
	if mcl_vars then
		if mcl_vars.mapgen_edge_min and mcl_vars.mapgen_edge_max then
			wmin, wmax = mcl_vars.mapgen_edge_min, mcl_vars.mapgen_edge_max
		end
	end
	if radius then
		wmin = wmin - radius
		wmax = wmax + radius
	end
	if not pos then return true end
	for _,v in pairs(pos) do
		if v < wmin or v > wmax then return false end
	end
	return true
end

function mob_class:player_in_active_range()
	for _ in mcl_util.connected_players(self.object:get_pos(), self.player_active_range) do
		-- slightly larger than the mc 32 since mobs spawn on that circle and easily stand still immediately right after spawning.
		return true
	end
end

function mob_class:object_in_follow_range(object)
	local dist = 6
	local p1, p2 = self.object:get_pos(), object:get_pos()
	return p1 and p2 and (vector.distance(p1, p2) <= dist)
end

-- Return true if object is in view_range
function mob_class:object_in_range(object)
	if not object then
		return false
	end
	local factor
	-- Apply view range reduction for special player armor
	if object:is_player() then
		local factors = mcl_armor.player_view_range_factors[object]
		factor = factors and factors[self.name]
	end
	-- Distance check
	local dist
	if factor and factor == 0 then
		return false
	elseif factor then
		dist = self.view_range * factor
	else
		dist = self.view_range
	end

	local p1, p2 = self.object:get_pos(), object:get_pos()
	return p1 and p2 and (vector.distance(p1, p2) <= dist)
end

function mob_class:item_drop(cooked, looting_level, cmi_cause)
	if not mobs_drop_items then return end
	looting_level = looting_level or 0
	if (self.child and self.type ~= "monster") then
		return
	end
	if not cmi_cause then
	    cmi_cause = self._death_reason
	end

	local obj, item
	local pos = self.object:get_pos()

	self.drops = self.drops or {}

	for _, dropdef in pairs(self.drops) do
		local chance = 1 / dropdef.chance
		local looting_type = dropdef.looting

		-- Always drop mob heads when killed by a charged creeper explosion.
		if (dropdef.mob_head and cmi_cause
		    and cmi_cause.type == "explosion"
		    and cmi_cause.mob_name == "mobs_mc:creeper_charged") then
		    chance = 1
		end

		if looting_level > 0 then
			local chance_function = dropdef.looting_chance_function
			if chance_function then
				chance = chance_function(looting_level)
			elseif looting_type == "rare" then
				chance = chance + (dropdef.looting_factor or 0.01) * looting_level
			end
		end

		local num = 0
		local do_common_looting = (looting_level > 0 and looting_type == "common")
		if math.random() < chance then
			num = math.random(dropdef.min or 1, dropdef.max or 1)
		elseif not dropdef.looting_ignore_chance then
			do_common_looting = false
		end

		if do_common_looting then
			num = num + math.floor(math.random(0, looting_level) + 0.5)
		end

		if num > 0 then
			item = dropdef.name
			if cooked then
				local output = minetest.get_craft_result({ method = "cooking", width = 1, items = {item}})
				if output and output.item and not output.item:is_empty() then
					item = output.item:get_name()
				end
			end

			for _ = 1, num do
				obj = minetest.add_item(pos, ItemStack(item .. " " .. 1))
			end

			if obj and obj:get_luaentity() then
				obj:set_velocity({
					x = math.random(-10, 10) / 9,
					y = 6,
					z = math.random(-10, 10) / 9,
				})
			elseif obj then
				obj:remove() -- item does not exist
			end
		end
	end
	self:drop_armor (looting_level * 0.01)
	self:drop_wielditem (looting_level * 0.01)
	self.drops = {}
end

-- collision function borrowed amended from jordan4ibanez open_ai mod
function mob_class:collision()
	local pos = self.object:get_pos()
	local attach = self.object:get_attach ()

	if not pos or attach then
		return 0, 0
	end
	local x = 0
	local z = 0
	local cbox = self.collisionbox
	local width = -cbox[1] + cbox[4]
	local pushable = self.pushable
	local mob_pushable = self.mob_pushable
	for _,object in pairs(minetest.get_objects_inside_radius(pos, width)) do
		local ent = object:get_luaentity()
		local is_player = object:is_player ()
		if (pushable and is_player and object:get_attach () ~= self.object)
			or (mob_pushable and ent and ent.is_mob
			    and object ~= self.object
			    and object ~= self._jockey_rider) then
			local pos2 = object:get_pos()
			local r1 = (math.random (300) - 150) / 2400
			local r2 = (math.random (300) - 150) / 2400
			local x_diff = pos2.x - pos.x + r1
			local z_diff = pos2.z - pos.z + r2
			local max_diff = math.max (math.abs (x_diff), math.abs (z_diff))
			local d_scale

			if max_diff > 0.01 then
				max_diff = math.sqrt (max_diff)
				d_scale = math.min (1.0, 1.0 / max_diff)
				z_diff = z_diff / max_diff * d_scale
				x_diff = x_diff / max_diff * d_scale

				x = x - x_diff
				z = z - z_diff
			end

			if is_player then
				mcl_player.player_collision (object, self.object)
			end
		end
	end
	return x, z
end

-- move mob in facing direction
function mob_class:set_velocity(v)
	self.acc_speed = v
	-- Minecraft scales forward acceleration by desired
	-- velocity in blocks/tick.
	self.acc_dir.z = v / 20
end

-- calculate mob velocity
function mob_class:get_velocity()
	local v = self.object:get_velocity()
	if v then
		return (v.x * v.x + v.z * v.z) ^ 0.5
	end
	return 0
end

-- check if mob is dead or only hurt
function mob_class:check_for_death(cause, cmi_cause)
	if self.dead then
		self:jockey_death ()
		return true
	end

	-- has health actually changed?
	if self.health == self.old_health and self.health > 0 then
		return false
	end

	local damaged = self.health < ( self.old_health or 0 )
	self.old_health = self.health

	-- still got some health?
	if self.health > 0 then
		-- make sure health isn't higher than max
		self.health = math.min(self.health, self.object:get_properties().hp_max)

		-- play damage sound if health was reduced and make mob flash red.
		if damaged then
			self:add_texture_mod("^[colorize:#d42222:175")
			minetest.after(0.5, function(self)
				if self and self.object and self.object:get_pos() then
					self:remove_texture_mod("^[colorize:#d42222:175")
				end
			end, self)
			self:mob_sound("damage")
		end
		return false
	end

	self:mob_sound("death")
	self:jockey_death ()

	-- execute custom death function
	if self.on_die then
		local pos = self.object:get_pos()
		local on_die_exit = self.on_die(self, pos, cmi_cause)
		if on_die_exit == true then
			self.dead = true
			self:safe_remove()
			return true
		end
	end
	self.dead = true
	self.attack = nil
	self.v_start = false
	self.blinktimer = 0
	self:remove_texture_mod("^[colorize:#FF000040")
	self:remove_texture_mod("^[brighten")
	self.passive = true

	self.object:set_properties({
		pointable = false,
		collide_with_objects = false,
	})

	local length
	-- default death function and die animation (if defined)
	if self.instant_death then
		length = 0
	elseif self.animation
	and self.animation.die_start
	and self.animation.die_end then

		local frames = self.animation.die_end - self.animation.die_start
		local speed = self.animation.die_speed or 15
		length = math.max(frames / speed, 0) + DEATH_DELAY
		self:set_animation( "die")
	else
		length = 1 + DEATH_DELAY
		self:set_animation( "stand", true)
	end

	local killed_by_player = false
	if self.last_player_hit_time and minetest.get_gametime() - self.last_player_hit_time <= 5 then
		killed_by_player  = true
	end

	-- Drop items and xp
	if cmi_cause and (cmi_cause.type == "lava" or cmi_cause.type == "fire") then
		self:item_drop(true, 0, cmi_cause)
	else
		local wielditem = cmi_cause.direct and mcl_util.get_wielditem (cmi_cause.direct)
		local cooked = mcl_burning.is_burning(self.object) or mcl_enchanting.has_enchantment(wielditem, "fire_aspect")
		local looting = mcl_enchanting.get_enchantment(wielditem, "looting")
		self:item_drop(cooked, looting, cmi_cause)
		if killed_by_player then
			if self.type == "monster" or self.name == "mobs_mc:zombified_piglin" and self.last_player_hit_name then
				awards.unlock(self.last_player_hit_name, "mcl:monsterHunter")
			end
			if ((not self.child) or self.type ~= "animal") and (minetest.get_us_time() - self.xp_timestamp <= math.huge) then
				local pos = self.object:get_pos()
				local xp_amount = math.random(self.xp_min, self.xp_max)
				if not minetest.is_creative_enabled(self.last_player_hit_name) and not mcl_sculk.handle_death(pos, xp_amount) then
					mcl_experience.throw_xp(pos, xp_amount)
				end
			end
		end
	end

	-- Remove body after a few seconds
	local kill = function(self)
		if not self.object:get_luaentity() then
			return
		end

		local dpos = self.object:get_pos()
		local cbox = self.object:get_properties().collisionbox
		local yaw = self:get_yaw ()
		self:safe_remove()
		mcl_mobs.death_effect(dpos, yaw, cbox, not self.instant_death)
	end

	if length <= 0 then
		kill(self)
	else
		minetest.after(length, kill, self)
	end

	return true
end

function mob_class:is_in_node(itemstring) --can be group:...
	local cb = self.object:get_properties().collisionbox
	local pos = self.object:get_pos()
	local nn = minetest.find_nodes_in_area(vector.offset(pos, cb[1], cb[2], cb[3]), vector.offset(pos, cb[4], cb[5], cb[6]), {itemstring})
	if nn and #nn > 0 then return true end
end

function mob_class:reset_breath ()
    local max = self.object:get_properties ().breath_max
    if max ~= -1 then
	self.breath = max
    end
end

function mob_class:respire ()
	self.breath = math.min (self.object:get_properties().breath_max, self.breath + 1)
end

-- environmental damage (water, lava, fire, light etc.)
function mob_class:do_env_damage()
	-- feed/tame text timer (so mob 'full' messages dont spam chat)
	if self.htimer > 0 then
		self.htimer = self.htimer - 1
	end

	local pos = self.object:get_pos()
	if not pos then return end

	self.time_of_day = minetest.get_timeofday()
	-- remove mob if beyond map limits
	if not within_limits(pos, 0) then
		self:safe_remove()
		return true
	end

	local sunlight = minetest.get_natural_light(pos, self.time_of_day)
	self.sunlight = sunlight
	local _, dim = mcl_worlds.y_to_layer(pos.y)
	if self.ignited_by_sunlight and (sunlight or 0) >= minetest.LIGHT_MAX and dim == "overworld" then
		if self.armor_list then
			local stack = ItemStack (self.armor_list.head)
			if stack:is_empty () then
				mcl_burning.set_on_fire (self.object, 10)
			else
				-- Damage armor while on fire.
				mcl_util.use_item_durability (stack, 5 * math.random ())
				-- Apply wear to head armor.
				self.armor_list.head = stack:to_string ()
				if stack:is_empty () then
					self:set_armor_texture ()
				end
			end
		end
	end

	-- don't fall when on ignore, just stand still
	if self.standing_in == "ignore" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
		self.acc_dir = vector.zero ()
	-- wither rose effect
	elseif self.standing_in == "mcl_flowers:wither_rose" then
		mcl_potions.give_effect_by_level("withering", self.object, 2, 2)
	end

	local nodef = minetest.registered_nodes[self.standing_in]
	local nodef2 = minetest.registered_nodes[self.standing_on]
	local head_nodedef = minetest.registered_nodes[self.head_in]

	-- rain
	if self.rain_damage > 0 then
		if mcl_weather.rain.raining and mcl_weather.is_outdoor(pos) then
			self:damage_mob("environment", self.rain_damage)

			if self:check_for_death("rain", {type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end
	end

	pos.y = pos.y + 1 -- for particle effect position

	local frozen = false
	-- water damage
	if self.water_damage > 0
	and nodef.groups.water then
		self:damage_mob("environment", self.water_damage)
		mcl_mobs.effect(pos, 5, "mcl_particles_smoke.png", nil, nil, 1, nil)
		if self:check_for_death("water", {type = "environment",
				pos = pos, node = self.standing_in}) then
			return true
		end
	-- magma damage
	elseif self.fire_damage > 0
	and (nodef2.groups.fire) then

		if self.fire_damage ~= 0 then
			self:damage_mob("hot_floor", self.fire_damage)
			if self:check_for_death("fire", {type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end
	-- lava damage
	elseif self.lava_damage > 0
	and self:is_in_node("group:lava") then

		if self.lava_damage ~= 0 then
			self:damage_mob("lava", self.lava_damage)
			mcl_mobs.effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)
			mcl_burning.set_on_fire(self.object, 10)

			if self:check_for_death("lava", {type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end
	-- fire damage
	elseif self.fire_damage > 0
	and self:is_in_node("group:fire") then

		if self.fire_damage ~= 0 then

			self:damage_mob("in_fire", self.fire_damage)

			mcl_mobs.effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)
			mcl_burning.set_on_fire(self.object, 5)

			if self:check_for_death("fire", {type = "environment",
					pos = pos, node = self.standing_in}) then
				return true
			end
		end
	elseif self._mcl_freeze_damage > 0
	and self:is_in_node("mcl_powder_snow:powder_snow") then
		frozen = true
		self._frozen_for = self._frozen_for + 1
		if self._frozen_for >= 8 and self._frozen_for % 2 == 0 then
			self:damage_mob("freeze", self._mcl_freeze_damage)

			if self:check_for_death("freeze", {type = "freeze",
							   pos = pos, node = self.standing_in}) then
				return true
			end
		end
	-- damage_per_second node check
	elseif nodef.damage_per_second ~= 0 and not nodef.groups.lava and not nodef.groups.fire then

		self:damage_mob("environment", nodef.damage_per_second)
		mcl_mobs.effect(pos, 5, "mcl_particles_smoke.png")

		if self:check_for_death("dps", {type = "environment",
				pos = pos, node = self.standing_in}) then
			return true
		end
	end
	-- Drowning damage
	if self.object:get_properties().breath_max ~= -1 then
		local drowning = false
		if self.breathes_in_water then
			if minetest.get_item_group(self.standing_in, "water") == 0 then
				drowning = true
			end
		elseif head_nodedef.drowning > 0 then
			if self._immersion_depth > self.head_eye_height then
				drowning = true
			end
		end
		if drowning then
			self.breath = math.max(0, self.breath - 1)
			-- Only show bubbles if getting close to drowning
			-- Mainly because of dolphins
			if self.breath <= 20 then
				mcl_mobs.effect(pos, 2, "bubble.png", nil, nil, 1, nil)
			end

			if self.breath <= 0 then
				local dmg
				if head_nodedef.drowning > 0 then
					dmg = head_nodedef.drowning
				else
					dmg = 4
				end
				self:damage_effect(dmg)
				self:damage_mob("environment", dmg)
			end
			if self:check_for_death("drowning", {type = "environment",
					pos = pos, node = self.head_in}) then
				return true
			end
		else
			self:respire ()
		end
	end
	if not frozen and self._frozen_for > 0 then
		-- Mobs thaw twice as quickly as they freeze.
		self._frozen_for
			= math.max (0, math.min (self._frozen_for, 7) - 2)
	end
	--- suffocation inside solid node
	if (self.suffocation == true)
	and (head_nodedef.walkable == nil or head_nodedef.walkable == true)
	and (head_nodedef.collision_box == nil or head_nodedef.collision_box.type == "regular")
	and (head_nodedef.node_box == nil or head_nodedef.node_box.type == "regular")
	and (head_nodedef.groups.disable_suffocation ~= 1)
	and (head_nodedef.groups.opaque == 1) then
		-- Short grace period before starting to take suffocation damage.
		-- This is different from players, who take damage instantly.
		-- This has been done because mobs might briefly be inside solid nodes
		-- when e.g. climbing up stairs.
		-- This is a bit hacky because it assumes that do_env_damage
		-- is called roughly every second only.
		if self:check_timer("suffocation", 1) then
			-- 2 damage per second
			-- TODO: Deal this damage once every 1/2 second
			self:damage_mob("environment", 2)

			if self:check_for_death("suffocation", {type = "environment",
					pos = pos, node = self.head_in}) then
				return true
			end
		end
	else
		self._timers["suffocation"] = 1
	end
	return self:check_for_death("", {type = "unknown"})
end

function mob_class:env_damage (_, pos)
	-- Calculate depth of immersion.  This value is also utilized
	-- by run_ai.
	self._immersion_depth = 0
	if ((self.floats or self.swims or self.amphibious)
		and minetest.get_item_group (self.standing_in, "water") > 0)
		or minetest.get_item_group (self.head_in, "water") > 0 then
		local ymin = self.collisionbox[2]
		local height = self.collisionbox[5] - ymin
		local pos = vector.new (pos.x, pos.y, pos.z)
		self._immersion_depth = self:immersion_depth ("water", pos, height)
	end

	-- environmental damage timer (every 1 second)
	if not self:check_timer("env_damage", 1) then return end
	self:check_entity_cramming()
	-- check for environmental damage (water, fire, lava etc.)
	if self:do_env_damage() then
		return true
	end
	-- node replace check (cow eats grass etc.)
	self:replace(pos)
end

function mob_class:damage_mob(reason, damage)
	if not self.health then return end
	damage = math.floor(damage)
	if damage > 0 then
		local mcl_reason = { type = reason }
		mcl_damage.finish_reason(mcl_reason)
		mcl_util.deal_damage(self.object, damage, mcl_reason)

		mcl_mobs.effect(self.object:get_pos(), 5, "mcl_particles_smoke.png", 1, 2, 2, nil)

		if self:check_for_death(reason, {type = reason}) then
			return true
		end
	end
end

function mob_class:check_entity_cramming()
	local p = self.object:get_pos()
	if not p then return end
	local mobs = {}
	for o in minetest.objects_inside_radius(p, 0.5) do
		local l = o:get_luaentity()
		if l and l.is_mob and l.health > 0 then table.insert(mobs,l) end
	end
	local clear = #mobs < ENTITY_CRAMMING_MAX
	local ncram = {}
	for _,l in pairs(mobs) do
		if l then
			if clear then
				l.cram = nil
			elseif l.cram == nil and not self.child then
				table.insert(ncram,l)
			elseif l.cram then
				l:damage_mob("cramming",CRAMMING_DAMAGE)
			end
		end
	end
	for i,l in pairs(ncram) do
		if i > ENTITY_CRAMMING_MAX then
			l.cram = true
		else
			l.cram = nil
		end
	end
end

-- falling and fall damage
-- returns true if mob died
function mob_class:falling(pos)
	if (self.fly or self.swims) and self.dead then
		return
	end

	if self._just_portaled then
		self.reset_fall_damage = 1
		return false -- mob has teleported through portal - it's 99% not falling
	end

	if minetest.registered_nodes[mcl_mobs.node_ok(pos).name].name == "mcl_powder_snow:powder_snow" then
		self.reset_fall_damage = 1
	elseif minetest.registered_nodes[mcl_mobs.node_ok(pos).name].groups.water then
		-- Reset fall damage when falling into water first.
		self.reset_fall_damage = 1
	else
		-- fall damage onto solid ground
		if self.fall_damage == 1
		and self.object:get_velocity().y == 0 then
			local n = mcl_mobs.node_ok(vector.offset(pos,0,-1,0)).name
			-- init old_y to current height if not set.
			local d = (self.old_y or self.object:get_pos().y) - self.object:get_pos().y

			if d > 5 and n ~= "air" and n ~= "ignore" and self.reset_fall_damage ~= 1 then
				local add = minetest.get_item_group(self.standing_on, "fall_damage_add_percent")
				local damage = d - 5
				if add ~= 0 then
					damage = damage + damage * (add/100)
				end
				self:damage_mob ("fall", damage * self.fall_damage_multiplier)
				self.reset_fall_damage = 0
			end
			self.old_y = self.object:get_pos().y
		end
		self.reset_fall_damage = 0
	end
end

function mob_class:check_water_flow ()
	local p, node, nn, def
	p = self.object:get_pos ()
	node = minetest.get_node_or_nil (p)
	if node then
		nn = node.name
		def = minetest.registered_nodes[nn]
	end
	-- Move item around on flowing liquids
	if def and def.liquidtype == "flowing" then
		-- Get flowing direction (function call from flowlib),
		-- if there's a liquid.  NOTE: According to
		-- Qwertymine, flowlib.quickflow is only reliable for
		-- liquids with a flowing distance of 7.  Luckily,
		-- this is exactly what we need if we only care about
		-- water, which has this flowing distance.
		local vec = flowlib.quick_flow(p, node)
		return vec
	end
	return nil
end

function mob_class:check_dying(reason, cmi_cause)
	if (self.dead or self:check_for_death(reason, cmi_cause))
		and not self.animation.die_end then
		if self.object then
			local rot = self.object:get_rotation()
			rot.z = ((math.pi/2-rot.z)*.2)+rot.z
			self.object:set_rotation(rot)
		end
		return true
	end
end

function mob_class:check_suspend()
	if not self:player_in_active_range() then
		local pos = self.object:get_pos()
		local node_under = mcl_mobs.node_ok(vector.offset(pos,0,-1,0)).name
		local acc = self.object:get_acceleration()
		self:set_animation( "stand", true)
		if acc.y > 0 or node_under ~= "air" then
			self:halt_in_tracks (true)
		end
		return true
	end
end

local function apply_physics_factors (self, field, id)
    local base = self._physics_factors[field].base
    for name, value in pairs (self._physics_factors[field]) do
	if name ~= "base" then
	    base = base * value
	end
    end
    self[field] = base
end

function mob_class:add_physics_factor (field, id, factor)
    if not self._physics_factors[field] then
	self._physics_factors[field] = { base = self[field], }
    end
    self._physics_factors[field][id] = factor
    apply_physics_factors (self, field, id)
end

function mob_class:remove_physics_factor (field, id)
    if not self._physics_factors[field] then
	return
    end
    self._physics_factors[field][id] = nil
    apply_physics_factors (self, field, id)
end

function mob_class:stock_value (field)
    if not self._physics_factors[field] then
	    return self[field]
    end
    return self._physics_factors[field].base
end

-- Mob motion routines.

--- Constants.  These remain constant for the duration of the game but
--- are adjusted so as to reflect the global step time.

-- TODO: read floating point settings.
-- local step_length = minetest.settings:get ("dedicated_server_step")
-- step_length = tonumber (step_length) or 0.09
-- local step_length = 0.05

local function pow_by_step (value, dtime)
	return math.pow (value, dtime / 0.05)
end
mcl_mobs.pow_by_step = pow_by_step

local AIR_DRAG			= 0.98
local AIR_FRICTION		= 0.91
local WATER_DRAG		= 0.8
local AQUATIC_WATER_DRAG	= 0.9
local AQUATIC_GRAVITY		= -0.1
local SPRINTING_WATER_DRAG	= 0.9
local LAVA_FRICTION		= 0.5
local LAVA_SPEED		= 0.4
local FLYING_LIQUID_SPEED	= 0.4
local FLYING_GROUND_SPEED	= 2.0
local FLYING_AIR_SPEED		= 0.4
local BASE_SLIPPERY		= 0.98
local BASE_FRICTION		= 0.6
local LIQUID_FORCE		= 0.28
local BASE_FRICTION3		= math.pow (0.6, 3)
local FLYING_BASE_FRICTION3	= math.pow (BASE_FRICTION * AIR_FRICTION, 3)
local LIQUID_JUMP_THRESHOLD	= 0.4
local LIQUID_JUMP_FORCE		= 0.8
local LIQUID_JUMP_FORCE_ONESHOT	= 6.0

local function scale_speed (speed, friction)
	local f = BASE_FRICTION3 / (friction * friction * friction)
	return speed * f
end

local function scale_speed_flying (speed, friction)
	local f = FLYING_BASE_FRICTION3 / (friction * friction * friction)
	return speed * f
end

function mob_class:accelerate_relative (acc, speed)
	local yaw = self:get_yaw ()
	acc = vector.length (acc) <= 1
		and vector.copy (acc)
		or vector.normalize (acc)
	acc.x = acc.x * speed
	acc.z = acc.z * speed
	-- vector.rotate_around_axis is surprisingly inefficient.
	-- local rv = vector.rotate_around_axis (acc, {x = 0, y = 1, z = 0,}, yaw)
	local s = -math.sin (yaw)
	local c = math.cos (yaw)
	local rv = vector.new (acc.x * c + acc.z * s, acc.y * speed, acc.z * c - acc.x * s)
	return rv
end

function mob_class:jump_actual (v)
	self:set_animation ("jump")
	self:mob_sound ("jump")
	v = vector.new (v.x, self.jump_height, v.z)

	-- Apply acceleration if sprinting.
	if self._sprinting then
		local yaw = self:get_yaw ()
		v.x = v.x + math.sin (yaw) * -4.0
		v.z = v.z + math.cos (yaw) * 4.0
	end
	return v
end

local function horiz_collision (v, moveresult)
	for _, item in ipairs (moveresult.collisions) do
		if item.type == "node"
			and (item.axis == "x" or item.axis == "z") then
			return true
		end
	end

	return moveresult.collides and not (moveresult.standing_on_object or moveresult.touching_ground)
end

local function clamp (num, min, max)
	return math.min (max, math.max (num, min))
end

function mob_class:immersion_depth (liquidgroup, pos, max)
	local start = pos.y
	local ymax
	local i = start
	local limit = i + max + 1

	while i < limit do
		local pos = { x = pos.x, y = i, z = pos.z, }
		local node = minetest.get_node (pos)
		local def = minetest.registered_nodes[node.name]
		if def and def.groups[liquidgroup] then
			local height = 1
			if def.liquidtype == "flowing" then
				height = 0.1 + node.param2 * 0.1
			end
			ymax = math.floor (i + 0.5) + height - 0.5
		end
		i = i + 1
	end

	return ymax and ymax - start or 0
end

function mob_class:check_collision ()
	-- can mob be pushed, if so calculate direction
	if self.pushable or self.mob_pushable then
		local c_x, c_y = self:collision ()
		self.object:add_velocity ({x = c_x, y = 0, z = c_y})
	end
end

function mob_class:motion_step (dtime, moveresult)
	if not moveresult then
		return
	end
	local standin = minetest.registered_nodes[self.standing_in]
	local standon = minetest.registered_nodes[self.standing_on]
	local acc_dir = self.acc_dir
	local acc_speed = self.acc_speed
	local fall_speed = self._acc_no_gravity and 0 or self.fall_speed
	local touching_ground = moveresult.touching_ground or moveresult.standing_on_object
	local jumping = self._jump
	local p
	local h_scale, v_scale
	local climbing = false

	-- Note that mobs being controlled by a player should sink.
	if self.floats == 1 and not self.driver and math.random (10) < 8 then
		local depth = self._immersion_depth or 0
		if depth > LIQUID_JUMP_THRESHOLD then
				jumping = true
		end
	end

	if self.jump_timer and self.jump_timer > 0 then
		self.jump_timer = math.max (0, self.jump_timer - dtime)
	end

	p = pow_by_step (AIR_DRAG, dtime)
	acc_dir.x = acc_dir.x * p
	acc_dir.z = acc_dir.z * p

	local v = self.object:get_velocity ()
	local climbable = standin.climbable or standon.climbable

	if self.climb_powder_snow then
		if self.standing_in == "mcl_powder_snow:powder_snow"
			or self.standing_on == "mcl_powder_snow:powder_snow" then
			climbable = true
		end
	end

	-- If standing on a climable block and jumping or impeded
	-- horizontally, begin climbing, and prevent fall speed from
	-- exceeding 3.0 blocks/s.
	if (self.always_climb and horiz_collision (v, moveresult)) or climbable then
		if v.y < -3.0 then
			v.y = -3.0
		end
		v.x = clamp (v.x, -3.0, 3.0)
		v.z = clamp (v.z, -3.0, 3.0)
		if jumping or horiz_collision (v, moveresult) then
			v.y = 4.0
			jumping = false
			self._jump = false
		end
		climbing = true
		self.reset_fall_damage = 1
	end

	-- In Minecraft, gravity is applied after being attenuated by
	-- gravity_drag, but acceleration is unaffected.
	-- Consequently, fv.y must be applied after fall_speed, with
	-- gravity_drag in between.
	local gravity_drag = 1
	if self.gravity_drag and not touching_ground then
		gravity_drag = pow_by_step (self.gravity_drag, dtime)
	end

	local water_vec = not self.swims and self:check_water_flow () or nil
	local velocity_factor = standon._mcl_velocity_factor or 1

	if standin.groups.water then
		local water_friction = self.water_friction
		if self._sprinting then
			water_friction = SPRINTING_WATER_DRAG
		end
		local friction = water_friction * velocity_factor
		local speed = self.water_velocity

		-- Apply depth strider.
		local level = math.min (3, mcl_enchanting.depth_strider_level (self))
		level = touching_ground and level or level / 2
		if level > 0 then
			local delta = BASE_FRICTION * AIR_FRICTION - friction
			friction = friction + delta * level / 3
			delta = acc_speed - speed
			speed = speed + delta * level / 3
		end

		-- TODO: apply Dolphin's Grace.

		-- Adjust speed by friction.  Minecraft applies
		-- friction to acceleration (speed), not just the
		-- previous velocity.
		local r, z = pow_by_step (friction, dtime), friction
		h_scale = (1 - r) / (1 - z)
		speed = speed * h_scale

		local fv = self:accelerate_relative (acc_dir, speed)
		p = pow_by_step (WATER_DRAG, dtime)

		-- Apply friction.
		v = vector.new (v.x * r, v.y * p, v.z * r)

		-- Apply the new velocity in whole.
		v_scale = (1 - p) / (1 - WATER_DRAG)

		-- Apply gravity unless this mob is sprinting.
		if not self._sprinting then
			v.y = v.y + fall_speed / 16 * v_scale
			if v.y > -0.06 and v.y < 0 then
				v.y = -0.06
			end
			if v.y < 0 then
				v.y = v.y * gravity_drag
			end
		end

		if horiz_collision (v, moveresult) then
			-- Climb water as if it were a ladder.
			v.y = 3.0
		end
		v = vector.add (v, fv)
	elseif standin.groups.lava then
		local speed = LAVA_SPEED
		local r, z = pow_by_step (LAVA_FRICTION, dtime), LAVA_FRICTION
		h_scale = (1 - r) / (1 - z)
		speed = speed * h_scale

		local fv = self:accelerate_relative (acc_dir, speed)
		v = vector.multiply (v, r)
		v_scale = h_scale
		v.y = v.y + fall_speed * v_scale
		if v.y < 0 then
			v.y = v.y * gravity_drag
		end
		v = vector.add (v, fv)
	else
		-- If not standing on air, apply slippery to a base value of
		-- 0.6.
		local slippery = standon.groups.slippery
		local friction
		if slippery and slippery > 0 then
			friction = BASE_SLIPPERY
		elseif touching_ground then
			friction = BASE_FRICTION
		else
			friction = 1
		end

		-- Apply friction, relative movement, and speed.
		local speed

		if touching_ground or climbing
			or self._airborne_agile then
			speed = scale_speed (acc_speed, friction)
		else
			speed = 0.4 -- 0.4 blocks/s
		end
		-- Apply friction (velocity_factor) from Soul Sand and
		-- the like.  NOTE: this friction is supposed to be
		-- applied after movement, just as with standard
		-- friction.
		friction = friction * AIR_FRICTION * velocity_factor

		-- Adjust speed by friction.  Minecraft applies
		-- friction to acceleration (speed), not just the
		-- previous velocity.  The manner in which friction is
		-- applied to acceleration is very peculiar, in that
		-- mobs are moved by the original speed each tick,
		-- before the modified speed is integrated into the
		-- velocity.
		--
		-- In Minetest, this is emulated by integrating the
		-- full speed into the velocity after applying
		-- friction to the same, which is more logical anyway.
		local r, z = pow_by_step (friction, dtime), friction
		h_scale = (1 - r) / (1 - z)
		speed = speed * h_scale

		local fv = self:accelerate_relative (acc_dir, speed)
		v_scale = (1 - p) / (1 - AIR_DRAG)
		local new_y = v.y + fall_speed * v_scale
		v = vector.new (v.x * r, new_y * p, v.z * r)
		if v.y < 0 then
			v.y = v.y * gravity_drag
		end

		-- Apply the new velocity in whole.
		v = vector.add (v, fv)
	end

	if water_vec ~= nil and vector.length (water_vec) ~= 0 then
		v.x = v.x + water_vec.x * LIQUID_FORCE * h_scale
		v.y = v.y + water_vec.y * LIQUID_FORCE * h_scale
		v.z = v.z + water_vec.z * LIQUID_FORCE * h_scale
	end

	if jumping then
		if standin.groups.water or standin.groups.lava then
			if self.floats == 1 then
				v.y = v.y + LIQUID_JUMP_FORCE * v_scale
			else
				v.y = v.y + LIQUID_JUMP_FORCE_ONESHOT
			end
		else
			if touching_ground and (not self.jump_timer or self.jump_timer <= 0) then
				v = self:jump_actual (v)
				self.jump_timer = 0.2
			end
		end
	end

	-- Step height should always be configured to zero while not
	-- standing.  This might be slightly counter-intuitive, but it
	-- enables jumping to function correctly when the mob is
	-- accelerating forward.
	if touching_ground and self._previously_floating then
		self._previously_floating = false
		self.object:set_properties ({stepheight = self._initial_step_height})
	elseif not touching_ground and not self._previously_floating then
		self._previously_floating = true
		self.object:set_properties ({stepheight = 0.0})
	end

	-- Clear the jump flag even when jumping is not yet possible.
	self._jump = false
	self.object:set_velocity (v)
	self:check_collision ()
end

-- Simplified `motion_step' for true (i.e., not birds or blazes)
-- flying mobs unaffected by gravity (i.e., not ghasts).

function mob_class:flying_step (dtime, moveresult)
	if not moveresult then
		return
	end
	local standin = minetest.registered_nodes[self.standing_in]
	local standon = minetest.registered_nodes[self.standing_on]
	local touching_ground = moveresult.touching_ground
		or moveresult.standing_on_object
	local v = self.object:get_velocity ()
	local p = pow_by_step (AIR_DRAG, dtime)
	local acc_dir = self.acc_dir
	local fv, speed, scale

	acc_dir.x = acc_dir.x * p
	acc_dir.z = acc_dir.z * p

	if standin.groups.water then
		speed = FLYING_LIQUID_SPEED
		p = pow_by_step (WATER_DRAG, dtime)
		scale = (1 - p) / (1 - WATER_DRAG)
	elseif standin.groups.lava then
		speed = FLYING_LIQUID_SPEED
		p = pow_by_step (LAVA_FRICTION, dtime)
		scale = (1 - p) / (1 - LAVA_FRICTION)
	else
		local slippery = standon.groups.slippery
		local friction

		if slippery and slippery > 0 then
			friction = BASE_SLIPPERY * AIR_FRICTION
			speed = scale_speed_flying (FLYING_GROUND_SPEED, friction)
		elseif touching_ground then
			friction = BASE_FRICTION * AIR_FRICTION
			speed = scale_speed_flying (FLYING_GROUND_SPEED, friction)
		else
			friction = AIR_FRICTION
			speed = FLYING_AIR_SPEED
		end
		p = pow_by_step (friction, dtime)
		scale = (1 - p) / (1 - friction)
	end

	fv = self:accelerate_relative (acc_dir, speed * scale)
	v.x = v.x * p + fv.x
	v.y = v.y * p + fv.y
	v.z = v.z * p + fv.z
	self._previously_floating = true
	self.object:set_properties ({stepheight = 0.0})
	self.object:set_velocity (v)
	self:check_collision ()
end

-- Simplified `motion_step' for true (i.e., not birds or blazes)
-- swimming mobs.

local default_motion_step = mob_class.motion_step

function mob_class:aquatic_step (dtime, moveresult)
	if not moveresult then
		return
	end

	local standin = minetest.registered_nodes[self.standing_in]
	if standin.groups.water then
		local acc_speed = self.acc_speed
		local acc_dir = self.acc_dir
		local acc_fixed = self._acc_y_fixed or 0
		local p = pow_by_step (AIR_DRAG, dtime)
		local fv, scale
		local v = self.object:get_velocity ()

		acc_dir.x = acc_dir.x * p
		acc_dir.z = acc_dir.z * p
		p = pow_by_step (AQUATIC_WATER_DRAG, dtime)
		scale = (1 - p) / (1 - AQUATIC_WATER_DRAG)

		fv = self:accelerate_relative (acc_dir, acc_speed * scale)
		v.x = v.x * p + fv.x
		v.y = v.y * p + fv.y + acc_fixed * scale
		v.z = v.z * p + fv.z

		-- Apply gravity unless attacking mob.
		if not self.attacking and not self._acc_no_gravity then
			v.y = v.y + AQUATIC_GRAVITY * scale
		end

		self.object:set_velocity (v)
		self:check_collision ()
		self._previously_floating = true
		self.object:set_properties ({stepheight = 0.0})
	else
		default_motion_step (self, dtime, moveresult)
	end
end

local floor = math.floor

mcl_mobs.mob_class.slowdown_nodes = {
	["mcl_farming:sweet_berry_bush_1"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_farming:sweet_berry_bush_2"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_farming:sweet_berry_bush_3"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_core:cobweb"] = {
		x = 0.25,
		y = 0.05,
		z = 0.25,
	},
	["mcl_powder_snow:powder_snow"] = {
		x = 0.9,
		y = 1.5,
		z = 0.9,
	},
}

local function standing_in_liquid_or_walkable (self)
	if self.standing_in == "air" then
		return false
	end
	local def = minetest.registered_nodes[self.standing_in]
	return not def and def.liquidtype ~= "flowing" and not def.walkable
end

function mob_class:display_sprinting_particles ()
	-- Don't display such particles if standing in a liquid or
	-- similar block.
	return self._sprinting and not self._crouching
		and not standing_in_liquid_or_walkable (self)
end

function mob_class:post_motion_step (self_pos, dtime)
	-- Apply slowdowns from blocks that should impede movement.
	local xmin, zmin, xmax, zmax, ymin, ymax
	local slowdowns = self.slowdown_nodes
	local v = vector.zero ()

	xmin = floor (self_pos.x + self.collisionbox[1] + 0.5)
	zmin = floor (self_pos.z + self.collisionbox[3] + 0.5)
	xmax = floor (self_pos.x + self.collisionbox[4] + 0.5)
	zmax = floor (self_pos.z + self.collisionbox[6] + 0.5)
	ymin = floor (self_pos.y + self.collisionbox[2] + 0.5)
	ymax = floor (self_pos.y + self.collisionbox[5] + 0.5)
	for x = xmin, xmax do
		v.x = x
		for z = zmin, zmax do
			v.z = z
			for y = ymin, ymax do
				v.y = y
				local node = minetest.get_node_or_nil (v)
				if node and slowdowns[node.name] then
					local slowdown = slowdowns[node.name]
					local v = self.object:get_velocity ()
					v.x = v.x * pow_by_step (slowdown.x, dtime)
					v.y = v.y * pow_by_step (slowdown.y, dtime)
					v.z = v.z * pow_by_step (slowdown.z, dtime)
					self.object:set_velocity (v)

					-- Indicate that the velocity must be reset
					-- upon the next globalstep
					self._was_stuck = true
					return
				end
			end
		end
	end

	-- Generate sprinting particles if and standing on a surface
	-- appropriate.
	if self:display_sprinting_particles () then
		local def = minetest.registered_nodes[self.standing_on]
		if def and def.walkable then
			local p2 = self.standing_on_param2
			local p2_type = def.paramtype2
			local tile = mcl_sprint.get_top_node_tile (p2, p2_type)
			local v = self.object:get_velocity ()
			local xwidth = (self.collisionbox[4] - self.collisionbox[1]) / 2
			local zwidth = (self.collisionbox[6] - self.collisionbox[3]) / 2
			v.x = v.x * -0.2
			v.z = v.z * -0.2
			v.y = 2.15
			minetest.add_particlespawner ({
					amount = math.random (1, 2),
					time = 1,
					minpos = {
						x = -xwidth,
						y = 0.1,
						z = -zwidth,
					},
					maxpos = {
						x = xwidth,
						y = 0.1,
						z = zwidth,
					},
					minvel = v,
					maxvel = v,
					minexptime = 0.1,
					maxexptime = 1.5,
					minacc = {
						x = 0,
						y = -13,
						z = 0,
					},
					maxacc = {
						x = 0,
						y = -13,
						z = 0,
					},
					collisiondetection = true,
					attached = self.object,
					vertical = false,
					node = {
						name = self.standing_on,
						param2 = p2,
					},
					node_tile = tile,
			})
		end
	end
end
