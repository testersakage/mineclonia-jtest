local mob_class = mcl_mobs.mob_class
-- API for Mobs Redo: MineClone 2 Edition (MRM)

-- Localize
local S = minetest.get_translator("mcl_mobs")

-- Invisibility mod check
mcl_mobs.invis = {}

function mob_class:set_properties(prop)
	mcl_util.set_properties(self.object, prop)
end

function mob_class:safe_remove()
	self.removed = true
	minetest.after(0,function(obj)
		if obj and obj:get_pos() then
			mcl_burning.extinguish(obj)
			obj:remove()
		end
	end,self.object)
end

function mob_class:get_nametag()
	return self.nametag or ""
end

function mob_class:update_tag() --update nametag and/or the debug box
	self:set_properties({
		nametag = self:get_nametag(),
	})
end

function mob_class:update_timers(dtime)
	for k, v in pairs(self._timers) do
		self._timers[k] = v - dtime
	end
end

function mob_class:check_timer(timer, interval)
	if not self._timers[timer] then
		self._timers[timer] = math.random() * interval --start with a random time to avoid many timers firing simultaneously
	end
	if self._timers[timer] <= 0  then
		self._timers[timer] = interval
		return true
	end
	return false
end

function mob_class:get_staticdata_table ()
	local pos = self.object:get_pos()
	if not mcl_mobs.check_vector(pos) then
		self.object:remove()
		return
	end

	local tmp = {}

	for tag, stat in pairs(self) do
		local t = type(stat)
		if  t ~= "function"
		and t ~= "nil"
		and t ~= "userdata"
		-- This structure is liable to grow to an immense size.
		and tag ~= "pathfinding_context"
		and tag ~= "waypoints"
		and tag ~= "_cmi_components"
		and tag ~= "_targets_visible"
		and tag ~= "_leader"
		and tag ~= "_school" then
			tmp[tag] = self[tag]
		end
	end

	if self._mcl_potions then
		tmp._mcl_potions = self._mcl_potions
		for name_raw, data in pairs(tmp._mcl_potions) do
			data.spawner = nil
			local def = mcl_potions.registered_effects[name_raw:match("^_EF_(.+)$")]
			if def and def.on_save_effect then def.on_save_effect(self.object) end
		end
	else
		tmp._mcl_potions = {}
	end

	-- If fortunately the jockey rider is still present, prefer
	-- staticdata derived "from the horse's mouth" to any saved by
	-- prior on_deactivate callbacks.
	--
	-- If rider(s) have been deactivated first, their staticdata
	-- will none the less have been preserved by on_deactivate and
	-- suchlike.
	if self._jockey_rider and self._jockey_rider:is_valid () then
		local entity = self._jockey_rider:get_luaentity ()
		local rider_data = entity:get_staticdata_table ()
		rider_data.name = entity.name
		tmp._jockey_staticdata = rider_data
	end
	return tmp
end

--[[
NOTE: This function is not called when something is about to despawn.

It is called every 18 seconds.

DO NOT change the state of the mob in this function!

Edit the copied state so it's serialized in the state you need to.
]]
function mob_class:get_staticdata()
	local data = self:get_staticdata_table ()
	return minetest.serialize (data)
end

function mob_class:valid_texture(def_textures)
	if not self.base_texture then
		return false
	end

	if self.texture_selected then
		if #def_textures < self.texture_selected then
			self.texture_selected = nil
		else
			return true
		end
	end
	return false
end

function mob_class:update_textures()
	local def = mcl_mobs.registered_mobs[self.name]
	--If textures in definition change, reload textures
	if not self:valid_texture(def.texture_list) then

		-- compatiblity with old simple mobs textures
		if type(def.texture_list[1]) == "string" then
			def.texture_list = {def.texture_list}
		end

		if not self.texture_selected then
			local c = 1
			if #def.texture_list > c then c = #def.texture_list end
			self.texture_selected = math.random(c)
		end

		-- Otherwise set_armor_texture will modify the texture
		-- list in the metatable, which eventually appears in
		-- mob spawners.
		self.base_texture = table.copy (def.texture_list[self.texture_selected])
		self.base_mesh = def.initial_properties.mesh
		self.base_size = def.initial_properties.visual_size
		self.base_colbox = table.copy (def.initial_properties.collisionbox)
		self.base_selbox = def.initial_properties.selectionbox
	end
end

function mob_class:scale_size_of_child (scale)
	local collisionbox = {
		self.base_colbox[1] * scale,
		self.base_colbox[2] * scale,
		self.base_colbox[3] * scale,
		self.base_colbox[4] * scale,
		self.base_colbox[5] * scale,
		self.base_colbox[6] * scale,
	}
	self.collisionbox = collisionbox
	local initial_size = self.initial_properties.visual_size
	self:set_properties ({
		visual_size = self._child_mesh and initial_size or {
			x = self.base_size.x * scale,
			y = self.base_size.y * scale,
		},
		collisionbox = collisionbox,
		selectionbox = {
			self.base_selbox[1] * scale,
			self.base_selbox[2] * scale,
			self.base_selbox[3] * scale,
			self.base_selbox[4] * scale,
			self.base_selbox[5] * scale,
			self.base_selbox[6] * scale,
		},
		mesh = self._child_mesh or self.base_mesh,
	})
	-- This presumes that the collision box does not extend much
	-- beneath the mob origin.
	self.head_eye_height = self.head_eye_height * scale
end

function mob_class:post_load_staticdata ()
	-- Nothing here but crickets.
end

function mob_class:mob_activate(staticdata, dtime)
	if not self.object:get_pos() or staticdata == "remove" then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end

	if staticdata then
		local tmp = minetest.deserialize(staticdata)

		if tmp then
			for _,stat in pairs(tmp) do
				self[_] = stat
			end
		end
	end

	self:post_load_staticdata ()
	self.acc_dir = vector.zero ()
	self.acc_speed = 0
	self._initial_step_height = self.initial_properties.stepheight
	self._previously_floating = nil
	self._active_texture_list = nil
	self._mob_invisible = false
	self._was_stuck = false
	self._sprinting = false
	self._crouching = false
	self._was_touching_ground = true

	if self.dead then
		self:safe_remove()
		return
		-- TODO
	end

	if mcl_vars.difficulty <= 0 and not self.persist_in_peaceful then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end

	self:update_textures()

	if not self.base_selbox then
		self.base_selbox = self.initial_properties.selectionbox or self.base_colbox
	end

	if self.gotten == true
	and self.gotten_texture then
		self:set_textures (self.gottten_texture)
	end

	if self.gotten == true
	and self.gotten_mesh then
		self:set_properties({mesh = self.gotten_mesh})
	end

	local def = mcl_mobs.registered_mobs[self.name]
	self.collisionbox = self.initial_properties.collisionbox
	if self.child == true then
		self:scale_size_of_child (0.5)
		if def.child_texture then
			self.base_texture = def.child_texture[1]
		end
	end

	if self.health == 0 then
		self.health = math.random (self.hp_min, self.object:get_properties().hp_max)
	end
	if self.breath == nil then
		self.breath = self.object:get_properties().breath_max
	end

	-- Armor groups
	-- immortal=1 because we use custom health
	-- handling (using "health" property)
	local armor
	if type(self.armor) == "table" then
		armor = table.copy(self.armor)
		armor.immortal = 1
	else
		armor = {immortal=1, fleshy = self.armor}
	end
	self.object:set_armor_groups(armor)
	self.sounds.distance = self.sounds.distance or 10

	self.object:set_texture_mod("")

	if not self.nametag then
		self.nametag = def.nametag
	end

	self.base_size = self.base_size or {x = 1, y = 1, z = 1}

	if self.base_texture then
		self:set_textures (self.base_texture)
	end

	self:set_yaw ((math.random(0, 360) - 180) / 180 * math.pi)
	self:update_tag()
	self._current_animation = nil
	self:set_animation( "stand")

	if self.riden_by_jock then --- Old-style jockeys.
		self.object:remove()
		return
	end
	self:restore_jockey ()

	self:init_ai ()
	self:display_wielditem (false)
	self:display_wielditem (true)

	if type (self._armor_texture_slots) == "number" then
		self._armor_texture_slots = {
			[self._armor_texture_slots] = {
				"head",
				"torso",
				"legs",
				"feet",
			},
		}
	end

	if not self.wears_armor and self.armor_list then
		self.armor_list = nil
	elseif not self._run_armor_init and self.wears_armor then
		self.armor_list = { head = "", torso = "", feet = "", legs = "" }
		self:set_armor_texture ()
		self._run_armor_init = true
	end

	if self.on_spawn and not self.on_spawn_run then
		if self:on_spawn() == false then
			self:safe_remove()
			return
		else
			self.on_spawn_run = true
		end
	end

	if not self._mcl_potions then
		self._mcl_potions = {}
	end
	mcl_potions._load_entity_effects(self)

	if def.after_activate then
		def.after_activate(self, staticdata, def, dtime)
	end
	self:remove_texture_mod ("^[colorize:#d42222:175")
end

function mob_class:on_step(dtime, moveresult)
	local pos = self.object:get_pos()
	if not mcl_mobs.check_vector(pos) or self.removed then
		self:safe_remove()
		return
	end
	self._targets_visible = {}
	local should_drive = self:should_drive ()

	if self:check_despawn(pos, dtime) then return true end

	self:update_tag()

	-- Objects which are attached don't receive moveresults.
	-- Create a placeholder object to prevent crashes further
	-- down the line.
	if not moveresult then
		moveresult = {
			touching_ground = false,
			collides = false,
			standing_on_object = true,
			collisions = { },
		}
	end
	self._moveresult = moveresult

	-- Clear remaining momentum if stuck in a cobweb or analogous
	-- node.
	if self._was_stuck then
		self.object:set_velocity (vector.zero ())
		self._was_stuck = false
	end

	-- Get nodes early for use in other functions
	local cbox = self.collisionbox
	local feet = vector.copy (pos)
	local bbase = pos.y + self.collisionbox[2] + 0.5
	feet.y = math.floor (bbase + 1.0e-2)
	if bbase - feet.y <= 1.0e-2 then
		self.standing_in = mcl_mobs.node_ok (feet, "air").name
		feet.y = feet.y - 1
		local node = mcl_mobs.node_ok (feet, "air")
		self.standing_on = node.name
		self.standing_on_param2 = node.param2
	else
		local node = mcl_mobs.node_ok (feet, "air")
		self.standing_in = node.name
		self.standing_on = self.standing_in
		self.standing_on_param2 = node.param2
	end
	local head_y = cbox[2] + (cbox[5] - cbox[2]) * 0.75
	local pos_head = vector.offset (pos, 0, head_y, 0)
	self.head_in = mcl_mobs.node_ok(pos_head, "air").name

	if self:check_jockey_status () then
		return
	end
	self:falling (pos)
	self:check_dying ()

	if self.stupefied then
		-- self.object:set_animation_frame_speed (0)
		if self.waypoints then
			self:navigation_step (dtime, moveresult)
			self:movement_step (dtime, moveresult)
		else
			self:halt_in_tracks ()
		end
		self:rotate_step (dtime)
		self:motion_step (dtime, moveresult)
		return
	end

	if not should_drive then
		self:navigation_step (dtime, moveresult)
		self:movement_step (dtime, moveresult)
		self:motion_step (dtime, moveresult)
	else
		self:drive ("walk", "stand", false, dtime, moveresult)
	end
	self:post_motion_step (pos, dtime)

	self:ai_step (dtime)

	if self.force_step then
		self:force_step(dtime)
	end

	self:update_timers(dtime)
	if self:check_suspend() then
		self.object:set_velocity(vector.zero()) --stop movement otherwise mobs keep moving continuously
		return
	end

	if not self.fire_resistant then
		mcl_burning.tick(self.object, dtime, self)
		-- mcl_burning.tick may remove object immediately
		if not self.object:get_pos() then return end
	end

	if self.dead then return end

	self:rotate_step (dtime)
	self:set_animation_speed ()
	self:check_head_swivel (dtime)

	-- Expel drivers riding submerged mobs.
	self:expel_underwater_drivers ()

	if self.do_custom then
		if self.do_custom(self, dtime, moveresult) == false then
			return
		end
	end

	if self._just_portaled then
		self._just_portaled = self._just_portaled - dtime
		if self._just_portaled < 0 then
			self._just_portaled = nil
		end
	end

	if should_drive then
		self:env_damage (dtime, pos)
		return
	end

	self:check_particlespawners(dtime)
	self:check_item_pickup()

	if self.opinion_sound_cooloff > 0 then
		self.opinion_sound_cooloff = self.opinion_sound_cooloff - dtime
	end
	-- mob plays random sound at times. Should be 120. Zombie and mob farms are ridiculous
	if math.random(1, 70) == 1 then
		self:mob_sound("random", true)
	end

	if self:env_damage (dtime, pos) then return end
	self:run_ai (dtime, moveresult)

	if self.jump_sound_cooloff > 0 then
		self.jump_sound_cooloff = self.jump_sound_cooloff - dtime
	end

	if not self.object:get_luaentity() then
		return false
	end
end

minetest.register_chatcommand("clearmobs",{
	privs = { maphack = true },
	params = "[<all> | <nametagged> | <tamed>] [<range>]",
	description=S("Remove all, nametagged or tamed mobs within the specified distance or everywhere. When unspecified remove all mobs except tamed and nametagged ones."),
	func=function(n,param)
		local sparam = param:split(" ")
		local p = minetest.get_player_by_name(n)

		local typ
		local range
		if sparam[1] then
			typ = sparam[1]
			if typ ~= "all" and typ ~= "nametagged" and typ ~= "tamed" then
				typ = nil
				range = tonumber(sparam[1])
				if not range then
					return false, S("Invalid syntax.")
				end
			end
		end
		if sparam[2] then
			range = tonumber(sparam[2])
			if not range then
				return false, S("Invalid syntax.")
			end
		end

		for _, o in pairs(minetest.luaentities) do
			if o.is_mob then
				if not range or vector.distance(p:get_pos(), o.object:get_pos()) <= range then
					if typ == "all" or
						(typ == "nametagged" and o.nametag) or
						(typ == "tamed" and o.tamed and not o.nametag) or
						(not typ and not o.nametag and not o.tamed) then
						o:safe_remove()
					end
				end
			end
		end
end})
