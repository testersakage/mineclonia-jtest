local S = core.get_translator(core.get_current_modname())

local enable_pvp = core.settings:get_bool("enable_pvp")

-- Time in seconds after which a stuck arrow is deleted
local ARROW_TIMEOUT = 120
-- Time in seconds after which a blocked arrow is deleted
local BLOCKED_ARROW_TIMEOUT = 3
-- Time in seconds after which an attached arrow is deleted
local ATTACHED_ARROW_TIMEOUT = 30
-- Time after which stuck arrow is rechecked for being stuck
local STUCK_RECHECK_TIME = 5
-- Range for stuck arrow to be collected by player
local PICKUP_RANGE = 2

--local GRAVITY = 9.81

local YAW_OFFSET = -math.pi/2

local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function random_arrow_positions(positions, placement)
	if positions == "x" then
		return math.random(-4, 4)
	elseif positions == "y" then
		return math.random(0, 10)
	end
	if placement == "front" and positions == "z" then
		return 3
	elseif placement == "back" and positions == "z" then
		return -3
	end
	return 0
end

core.register_craftitem("mcl_bows:arrow", {
	description = S("Arrow"),
	_tt_help = S("Ammunition").."\n"..S("Damage from bow: 1-10").."\n"..S("Damage from dispenser: 3"),
	_doc_items_longdesc = S("Arrows are ammunition for bows and dispensers.").."\n"..
S("An arrow fired from a bow has a regular damage of 1-9. At full charge, there's a 20% chance of a critical hit dealing 10 damage instead. An arrow fired from a dispenser always deals 3 damage.").."\n"..
S("Arrows might get stuck on solid blocks and can be retrieved again. They are also capable of pushing wooden buttons."),
	_doc_items_usagehelp = S("To use arrows as ammunition for a bow, just put them anywhere in your inventory, they will be used up automatically. To use arrows as ammunition for a dispenser, place them in the dispenser's inventory. To retrieve an arrow that sticks in a block, simply walk close to it."),
	inventory_image = "mcl_bows_arrow_inv.png",
	groups = { ammo=1, ammo_bow=1, ammo_bow_regular=1, ammo_crossbow=1 },
	_on_dispense = function(itemstack, dispenserpos, _, _, dropdir)
		-- Shoot arrow
		local shootpos = vector.add(dispenserpos, vector.multiply(dropdir, 0.51))
		local yaw = math.atan2(dropdir.z, dropdir.x) + YAW_OFFSET
		mcl_bows.shoot_arrow (itemstack:get_name(), shootpos, dropdir, yaw, nil, 0.366666)
	end,
})

local ARROW_ENTITY={
	initial_properties = {
		physical = true,
		pointable = false,
		visual = "mesh",
		mesh = "mcl_bows_arrow.obj",
		visual_size = {x=-1, y=1},
		textures = {"mcl_bows_arrow.png"},
		collisionbox = {-0.19, -0.125, -0.19, 0.19, 0.125, 0.19},
		collide_with_objects = false,
	},

	fire_damage_resistant = true,
	_lastpos={},
	_startpos=nil,
	_damage=1,	-- Damage on impact
	_is_critical=false, -- Whether this arrow would deal critical damage
	_stuck=false,   -- Whether arrow is stuck
	_lifetime=0,-- Amount of time (in seconds) the arrow has existed
	_stuckrechecktimer=nil,-- An additional timer for periodically re-checking the stuck status of an arrow
	_stuckin=nil,	--Position of node in which arow is stuck.
	_shooter=nil,	-- ObjectRef of player or mob who shot it
	_is_arrow = true,
	_in_player = false,
	_blocked = false,
	_viscosity=0,   -- Viscosity of node the arrow is currently in
	_deflection_cooloff=0, -- Cooloff timer after an arrow deflection, to prevent many deflections in quick succession
	_partical_id=nil,
	_ignored=nil,
}

-- Drop arrow as item at pos
local function spawn_item(self, pos)
	if not core.is_creative_enabled("") then
		local itemstring = "mcl_bows:arrow"
		if self._itemstring and core.registered_items[self._itemstring] then
			itemstring = self._itemstring
		end
		local item = core.add_item(pos, itemstring)
		item:set_velocity(vector.new(0, 0, 0))
		item:set_yaw(self.object:get_yaw())
	end
end

local function damage_particles(pos, is_critical)
	if is_critical then
		core.add_particlespawner({
			amount = 15,
			time = 0.1,
			minpos = vector.offset(pos, -0.5, -0.5, -0.5),
			maxpos = vector.offset(pos, 0.5, 0.5, 0.5),
			minvel = vector.new(-0.1, -0.1, -0.1),
			maxvel = vector.new(0.1, 0.1, 0.1),
			minexptime = 1,
			maxexptime = 2,
			minsize = 1.5,
			maxsize = 1.5,
			collisiondetection = false,
			vertical = false,
			texture = "mcl_particles_crit.png^[colorize:#bc7a57:127",
		})
	end
end

-- Multiply x and z velocity by given factor.
function ARROW_ENTITY:multiply_xz_velocity (factor)
	local vel = vector.copy(self.object:get_velocity())
	if math.abs(vel.x) >= 0.001 then
		vel.x = vel.x * factor
	end
	if math.abs(vel.z) >= 0.001 then
		vel.z = vel.z * factor
	end
	self.object:set_velocity(vel)
end

function ARROW_ENTITY:arrow_knockback (object, damage)
	local entity = object:get_luaentity ()
	local v = self.object:get_velocity ()
	v.y = 0
	local dir = vector.normalize (v)

	-- Utilize different methods of applying knockback for
	-- consistency's sake.
	if entity and entity.is_mob then
		entity:projectile_knockback (1, dir)
	elseif object:is_player () then
		mcl_player.player_knockback (object, self.object, dir, nil, damage)
	end

	if self._knockback and self._knockback > 0 then
		local resistance
			= entity and entity.knockback_resistance or 0
		-- Apply an additional horizontal force of
		-- self._knockback * 0.6 * 20 * 0.546 to the object.
		local total_kb = self._knockback * (1.0 - resistance) * 12 * 0.546
		v = vector.multiply (dir, total_kb)

		-- And a vertical force of 2.0 * 0.91.
		v.y = v.y + 2.0 * 0.91 * (1.0 - resistance)

		if object:is_player () then
			v.x = v.x * 0.25
			v.z = v.z * 0.25
		end
		object:add_velocity (v)
	end
end

function ARROW_ENTITY:calculate_damage (v)
	local crit_bonus = 0
	local multiplier = vector.length (v) / 20
	local damage = (self._damage or 2) * multiplier

	if self._is_critical then
		crit_bonus = math.random (damage / 2 + 2)
	end
	return math.floor (damage + crit_bonus)
end

function ARROW_ENTITY:do_particle()
	if not self._is_critical or self._partical_id then return end
	self._partical_id = core.add_particlespawner({
		amount = ARROW_TIMEOUT * 50,
		time = ARROW_TIMEOUT,
		minpos = vector.new(0,0,0),
		maxpos = vector.new(0,0,0),
		minvel = vector.new(-0.1,-0.1,-0.1),
		maxvel = vector.new(0.1,0.1,0.1),
		minexptime = 0.5,
		maxexptime = 0.5,
		minsize = 2,
		maxsize = 2,
		attached = self.object,
		collisiondetection = false,
		vertical = false,
		texture = "mobs_mc_arrow_particle.png",
		glow = 1,
	})
end

-- Calculate damage, knockback, burning, and tipped effect to target.
function ARROW_ENTITY:apply_effects(obj)
	local dmg = self:calculate_damage(self.object:get_velocity())
	local reason = {
		type = "arrow",
		source = self._shooter,
		direct = self.object,
	}
	local damage = mcl_util.deal_damage(obj, dmg, reason)
	self:arrow_knockback(obj, damage)
	if mcl_burning.is_burning(self.object) then
		mcl_burning.set_on_fire(obj, 5)
	end
	if self._extra_hit_func then
		self:_extra_hit_func(obj)
	end
end

-- Remove critical partical effect
function ARROW_ENTITY:stop_particle()
	if not self._partical_id then return end
	core.delete_particlespawner(self._partical_id)
	self._partical_id = nil
end

-- Remove burning status, crit particle effect, and finally the arrow object.
function ARROW_ENTITY:remove(delay, preserve_particle)
	mcl_burning.extinguish(self.object)
	self._ignored = nil
	if not preserve_particle then self:stop_particle() end
	if not delay or delay <= 0 then
		self.object:remove()
	else
		if not self._in_player or not self._blocked then
			core.log("warning", "Delayed arrow removal should be done after setting it to an ignored state.")
		end
		core.after(delay, function() self:remove() end)
	end
end

-- Process hitting a non-player object.  Return true to play damage particle and sound.
function ARROW_ENTITY:on_hit_object(obj, lua)
	if not lua or (not lua.is_mob and not lua._hittable_by_projectile)
	or lua.name == "mobs_mc:enderman" then
		return false
	end
	self:apply_effects(obj)
	return true
end

-- Process hitting a player, deflect if shield blocked, otherwise attach.
function ARROW_ENTITY:on_hit_player(obj)
	if not enable_pvp then return false end
	-- TODO: Checking facing
	if mcl_shields.is_blocking(obj) then -- Blocked by shield
		self._blocked = true
		self.object:set_velocity(vector.multiply(self.object:get_velocity(), -0.25))
		self:remove(BLOCKED_ARROW_TIMEOUT, false)
	else -- Hit and attach to player.
		self:apply_effects(obj)
		self._in_player = true
		self._placement = math.random(1, 2)
		local placement = self._placement == 1 and "front" or "back"
		if placement == "back" then
			self._rotation_station = 90
		else
			self._rotation_station = -90
		end
		self._y_position = random_arrow_positions("y", placement)
		self._x_position = random_arrow_positions("x", placement)
		if self._y_position > 6 and self._x_position < 2 and self._x_position > -2 then
			self._attach_parent = "Head"
			self._y_position = self._y_position - 6
		elseif self._x_position > 2 then
			self._attach_parent = "Arm_Right"
			self._y_position = self._y_position - 3
			self._x_position = self._x_position - 2
		elseif self._x_position < -2 then
			self._attach_parent = "Arm_Left"
			self._y_position = self._y_position - 3
			self._x_position = self._x_position + 2
		else
			self._attach_parent = "Body"
		end
		self._z_rotation = math.random(-30, 30)
		self._y_rotation = math.random( -30, 30)
		self.object:set_attach(
			obj, self._attach_parent,
			vector.new(self._x_position, self._y_position, random_arrow_positions("z", placement)),
			vector.new(0, self._rotation_station + self._y_rotation, self._z_rotation)
		)
		self:remove(ATTACHED_ARROW_TIMEOUT, true)
	end
	return "stop"
end

function ARROW_ENTITY:set_stuck (node_pos, node)
	local selfobj = self.object
	local self_pos = selfobj:get_pos()
	self:stop_particle()
	self._stuck = true
	self._lifetime = 0
	self._dragtime = 0
	self._stuckrechecktimer = 0
	self._ignored = nil
	if not self._stuckin then self._stuckin = node_pos end
	selfobj:set_velocity(vector.new(0, 0, 0))
	selfobj:set_acceleration(vector.new(0, 0, 0))
	core.sound_play({name="mcl_bows_hit_other", gain=0.3}, {pos=self_pos, max_hear_distance=16}, true)

	local self_node_pos = vector.round(vector.copy(self_pos))
	local self_node = core.get_node(self_node_pos)
	local def = core.registered_nodes[self_node.name]
	if (def and def._on_arrow_hit) then   -- Entities: Button, Candle etc.
		def._on_arrow_hit(self_node_pos, self)
	else                                  -- Nodes: TNT, Campfire, Target etc.
		def = core.registered_nodes[node.name]
		if (def and def._on_arrow_hit) then
			def._on_arrow_hit(self._stuckin, self)
		end
	end

	return "stop"
end

-- Hit a non-liquid node.  Either arrow could be stopped by engine or on its way to target.
function ARROW_ENTITY:on_solid_hit (node_pos, node)
	if not node then 
		node = core.get_node(node_pos)
	end
	if node.name == "air" or node.name == "ignore" then return end

	-- Set fire to arrows which pass through lava or fire.
	if core.get_item_group(node.name, "set_on_fire") > 0 then
		mcl_burning.set_on_fire(self.object, ARROW_TIMEOUT)
	end
	return self:set_stuck(node_pos, node)
end

function ARROW_ENTITY:on_liquid_passthrough (node, def)
	-- Slow down arrow in liquids
	local v = def.liquid_viscosity or 0
	--local old_v = self._viscosity
	self._viscosity = v
	local vpenalty = math.max(0.1, 0.98 - 0.1 * v)
	self:multiply_xz_velocity(vpenalty)
end

-- Handle "arrow hitting things".  Return "stop" if arrow is stopped by this thing.
function ARROW_ENTITY:on_intersect(ray_hit)
	local selfobj = self.object
	local result
	local ignored = self._ignored or {}
	local orig_ignore_count = #ignored
	if ray_hit.type == "object" then
		local obj = ray_hit.ref
		if obj:is_valid() and obj:get_hp() > 0
		and ( obj ~= self._shooter or self._lifetime > 0.5 )
		and table.indexof(ignored, obj) == -1 then
			if obj:is_player() then
				result = self:on_hit_player(obj)
			else
				result = self:on_hit_object(obj, obj:get_luaentity())
			end
		end
		if result then
			table.insert(ignored, obj)
			local shooter = self._shooter
			local self_pos = selfobj:get_pos()
			if not self._blocked then
				if obj:is_player() and shooter and shooter:is_valid() and shooter:is_player() then
					-- “Ding” sound for hitting another player
					core.sound_play({name="mcl_bows_hit_player", gain=0.1}, {to_player=shooter:get_player_name()}, true)
				end
				damage_particles(vector.add(self_pos, vector.multiply(selfobj:get_velocity(), 0.1)), self._is_critical)
			end
			core.sound_play({name="mcl_bows_hit_other", gain=0.3}, {pos=self_pos, max_hear_distance=16}, true)
			if result ~= "stop" then
				self:remove()
				result = "stop"
			end
		end
	elseif ray_hit.type == "node" then
		local hit_node_pos = core.get_pointed_thing_position(ray_hit)
		local hit_node_str = hit_node_pos.x .. "," .. hit_node_pos.y .. "," .. hit_node_pos.z
		if table.indexof(ignored, hit_node_str) == -1 then
			local hit_node =  core.get_node(hit_node_pos)
			local def = core.registered_nodes[hit_node.name or ""]

			if def and def.liquidtype ~= "none" then
				result = self:on_liquid_passthrough(hit_node, def)
			elseif def then
				self._stuckin = hit_node_pos
				result = self:on_solid_hit(hit_node_pos, hit_node, def)
			end
			table.insert(ignored, hit_node_str)
		end
	end
	if #ignored ~= orig_ignore_count then
		self._ignored = ignored
	end
	return result
end

function ARROW_ENTITY:on_step(dtime)
	local selfobj = self.object
	local self_pos = selfobj:get_pos()
	if not self_pos then return end
	local last_pos = self._lastpos.x and self._lastpos or self._startpos

	if self._in_player or self._blocked or self._stuck then
		mcl_burning.tick(selfobj, dtime, self)
		if self._stuck then
			self:step_on_stuck(last_pos, dtime)
		end
		return
	end

	self._lifetime = self._lifetime + dtime
	if self._lifetime > ARROW_TIMEOUT then
		self:remove()
		return
	end

	self:do_particle()

	if self._deflection_cooloff > 0 then
		self._deflection_cooloff = self._deflection_cooloff - dtime
	end

	local result = nil
	-- Raycasting movement during dtime to handle lava, water, and hits.
	for ray_hit in core.raycast(last_pos, self_pos, true, true) do
		result = self:on_intersect(ray_hit)
		if result == "stop" then break end
	end

	-- Put out fire if exposed to rain, or if burning expires.
	mcl_burning.tick(selfobj, dtime, self)

	-- Check if arrow has stopped moving in one axis, which probably means it hit something.
	-- This detection is a bit clunky, but MT does not offer a direct collision detection. :-(
	if result ~= "stop" then
		local vel = selfobj:get_velocity()
		if (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) then
			local dir
			if math.abs(vel.y) < 0.00001 then
				if last_pos.y < self_pos.y then
					dir = vector.new(0, 1, 0)
				else
					dir = vector.new(0, -1, 0)
				end
			else
				dir = core.facedir_to_dir(core.dir_to_facedir(core.yaw_to_dir(selfobj:get_yaw()-YAW_OFFSET)))
			end
			local dpos = vector.round(vector.copy(self_pos))
			local stuck_pos = vector.add(dpos, dir)
			local stuck_node = core.get_node(stuck_pos)
			self._stuckin = stuck_pos
			result = self:on_solid_hit(stuck_pos, stuck_node)
			if result ~= "stop" then -- Arrow is stuck at air or other non-stopping block.
				self:set_stuck(stuck_pos, stuck_node)
			end
			return
		end
	end

	-- Predicting froward motion in anticipation of lag
	if result ~= "stop" then
		local vel = selfobj:get_velocity()
		local predict = vector.add(self_pos, vector.multiply(vector.copy(vel), 0.05))
		for ray_hit in core.raycast(self_pos, predict, true, true) do
			if ray_hit.type == "node" then
				break -- Hit a node, stop prediction and defer to next step.
			end
			result = self:on_intersect(ray_hit) -- Hit mob or player.
			if result == "stop" then break end
		end
	end

	-- Update yaw
	if not self._stuck then
		local vel = selfobj:get_velocity()
		if vel then
			local yaw = core.dir_to_yaw(vel)+YAW_OFFSET
			local pitch = dir_to_pitch(vel)
			selfobj:set_rotation({ x = 0, y = yaw, z = pitch })
		end
	end

	-- Update internal variable
	self._lastpos = self_pos
end

function ARROW_ENTITY:step_on_stuck(last_pos, dtime)
	local timer = ( self._stuckrechecktimer or 0 ) + dtime
	self._stuckrechecktimer = timer
	-- Drop arrow as item when it is no longer stuck
	-- FIXME: Arrows are a bit slow to react and continue to float in mid air for a few seconds.
	if timer > STUCK_RECHECK_TIME then
		local stuckin_def
		if self._stuckin then
			stuckin_def = core.registered_nodes[core.get_node(self._stuckin).name]
		end
		-- TODO: In MC, arrow just falls down without turning into an item
		if stuckin_def and stuckin_def.walkable == false then
			if self._collectable then
				spawn_item(self, last_pos)
			end
			self:remove()
			return
		end
		self._stuckrechecktimer = 0
	end

	local self_pos = self.object:get_pos()
	-- Pickup arrow if player is nearby (not in Creative Mode)
	for obj in core.objects_inside_radius(self_pos, PICKUP_RANGE) do
		if obj and obj:is_valid() and obj:is_player() then
			if self._collectable and not core.is_creative_enabled(obj:get_player_name()) then
				if obj:get_inventory():room_for_item("main", self._itemstring or "mcl_bows:arrow") then
					obj:get_inventory():add_item("main", self._itemstring or "mcl_bows:arrow")
					core.sound_play("item_drop_pickup", {
						pos = self_pos,
						max_hear_distance = 16,
						gain = 1.0,
					}, true)
				end
			end
			self:remove()
		end
	end
end

-- Force recheck of stuck arrows when punched.
-- Otherwise, punching has no effect.
function ARROW_ENTITY:on_punch()
	if self._stuck then
		self._stuckrechecktimer = STUCK_RECHECK_TIME
	end
end

function ARROW_ENTITY:get_staticdata()
	local out = {
		lastpos = self._lastpos,
		startpos = self._startpos,
		damage = self._damage,
		is_critical = self._is_critical,
		stuck = self._stuck,
		stuckin = self._stuckin,
		stuckin_player = self._in_player,
		itemstring = self._itemstring,
	}
	-- If _lifetime is missing for some reason, assume the maximum
	if not self._lifetime then
		self._lifetime = ARROW_TIMEOUT
	end
	out.starttime = core.get_gametime() - self._lifetime
	if self._shooter and self._shooter:is_player() then
		out.shootername = self._shooter:get_player_name()
	end
	return core.serialize(out)
end

function ARROW_ENTITY:on_activate(staticdata)
	local data = core.deserialize(staticdata)
	if data then
		-- First, check if the arrow is already past its life timer. If
		-- yes, delete it. If starttime is nil always delete it.
		self._lifetime = core.get_gametime() - (data.starttime or 0)
		if self._lifetime > ARROW_TIMEOUT then
			self:remove()
			return
		end
		self._stuck = data.stuck
		if data.stuck then
			-- Perform a stuck recheck on the next step.
			self._stuckrechecktimer = STUCK_RECHECK_TIME
			self._stuckin = data.stuckin
		end

		-- Get the remaining arrow state
		self._lastpos = data.lastpos
		self._startpos = data.startpos
		self._damage = data.damage
		self._is_critical = data.is_critical
		self._itemstring = data.itemstring
		self._is_arrow = true
		if data.shootername then
			local shooter = core.get_player_by_name(data.shootername)
			if shooter and shooter:is_player() then
				self._shooter = shooter
			end
		end
		if not self._startpos then
			self._startpos = self.object:get_pos()
		end
		if data.stuckin_player then
			self:remove()
			return
		end
		self:do_particle()
	else
		core.after(0, function() self:do_particle() end) -- Runs almost immediately for singleplayer.
	end
	self.object:set_armor_groups({ immortal = 1 })
end

function ARROW_ENTITY:on_deactivate()
	self:stop_particle()
end

minetest.register_on_respawnplayer(function(player)
	for _, obj in pairs(player:get_children()) do
		local ent = obj:get_luaentity()
		if ent and ent.name and string.find(ent.name, "mcl_bows:arrow_entity") then
			obj:remove()
		end
	end
end)

core.register_entity("mcl_bows:arrow_entity", ARROW_ENTITY)

if core.get_modpath("mcl_core") and core.get_modpath("mcl_mobitems") then
	core.register_craft({
		output = "mcl_bows:arrow 4",
		recipe = {
			{"mcl_core:flint"},
			{"mcl_core:stick"},
			{"mcl_mobitems:feather"}
		}
	})
end

if core.get_modpath("doc_identifier") then
	doc.sub.identifier.register_object("mcl_bows:arrow_entity", "craftitems", "mcl_bows:arrow")
end
