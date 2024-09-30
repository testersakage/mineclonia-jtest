--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")
local mobs_griefing = minetest.settings:get_bool("mobs_griefing", true)

--###################
--################### GHAST
--###################

local function ghast_do_go_pos (self, dtime, moveresult)
	local target = self.movement_target or vector.zero ()
	local self_pos = self.object:get_pos ()
	local dir = vector.direction (self_pos, target)

	-- This acceleration circumvents the regular physics
	-- mechanism, as in Minecraft.
	self.object:add_velocity (dir * 0.5)

	if not self.attack then
		local dir = math.atan2 (dir.z, dir.x) - math.pi/2
		self.object:set_yaw (dir)

		if moveresult.collides then
			if not self._ghast_collide_time then
				self._ghast_collide_time = dtime
			else
				self._ghast_collide_time
					= self._ghast_collide_time + dtime
			end

			if self._ghast_collide_time > 1 then
				-- If this mob has been colliding for
				-- over a second, abandon this target.
				self:halt_in_tracks ()
			end
		end
	end
end

local function ghast_move_randomly (self, self_pos)
	local activate = false
	if self.movement_goal ~= "go_pos" then
		activate = true
	else
		local target = self.movement_target
		if not target then
			activate = true
		else
			local dist = vector.distance (self_pos, target)
			if dist < 1 or dist > 60 then
				activate = true
			end
		end
	end

	if activate then
		-- Select a random target position and guarantee that
		-- it is unobstructed.
		local x_delta, y_delta, z_delta
		x_delta = (math.random () - 0.5) * 32.0
		y_delta = (math.random () - 0.5) * 32.0
		z_delta = (math.random () - 0.5) * 32.0
		local position
			= vector.offset (self_pos, x_delta, y_delta, z_delta)
		if self:line_of_sight (self_pos, position) then
			self:go_to_pos (position)
		end
	end
end

local function ghast_maybe_discharge (self, self_pos, dtime)
	if self.attack then
		local target_pos = self.attack:get_pos ()
		local distance = vector.distance (target_pos, self_pos)

		if distance < 64 then
			local dir = vector.subtract (target_pos, self_pos)
			local yaw = math.atan2 (dir.z, dir.x) - math.pi/2
			self.object:set_yaw (yaw)
		end

		if distance < 64 and self:target_visible (self_pos, self.attack) then
			self._charge_time = self._charge_time + dtime
			if self._charge_time >= 1.0 then
				self._charge_time = -2
				self:discharge_ranged (self_pos, target_pos)
			end
		elseif self._charge_time > 0 then
			self._charge_time = math.max (self._charge_time - dtime, 0)
		end
	end
end

local function ghast_run_ai (self, dtime)
	local self_pos = self.object:get_pos ()
	ghast_move_randomly (self, self_pos)
	if self:check_attack (self_pos, dtime) then
		ghast_maybe_discharge (self, self_pos, dtime)
	end
end

local function ghast_do_attack (self, target)
	self.attack = target
	self.target_invisible_time = 3.0
	self._charge_time = 0
end

mcl_mobs.register_mob("mobs_mc:ghast", {
	description = S("Ghast"),
	type = "monster",
	spawn_class = "hostile",
	pathfinding = 1,
	group_attack = true,
	hp_min = 10,
	hp_max = 10,
	xp_min = 5,
	xp_max = 5,
	player_active_range = 128,
	collisionbox = {-2, 5, -2, 2, 9, 2},
	doll_size_override = { x = 1.05, y = 1.05 },
	visual = "mesh",
	mesh = "mobs_mc_ghast.b3d",
	spawn_in_group = 1,
	textures = {
		{"mobs_mc_ghast.png"},
	},
	visual_size = {x=12, y=12},
	sounds = {
		shoot_attack = "mobs_fireball",
		attack = "mobs_fireball",
		random = "mobs_eerie",
		distance = 80,
		-- TODO: damage
		-- TODO: better death
	},
	movement_speed = 14,
	drops = {
		{name = "mcl_mobitems:gunpowder", chance = 1, min = 0, max = 2, looting = "common"},
		{name = "mcl_mobitems:ghast_tear", chance = 10/6, min = 0, max = 1, looting = "common", looting_ignore_chance = true},
	},
	animation = {
		stand_speed = 50, walk_speed = 50, run_speed = 50,
		stand_start = 0,		stand_end = 40,
		walk_start = 0,		walk_end = 40,
		run_start = 0,		run_end = 40,
	},
	fall_damage = 0,
	view_range = 64,
	arrow = "mobs_mc:fireball",
	shoot_offset = -5,
	tracking_distance = 64,
	passive = false,
	jump = true,
	jump_height = 4,
	head_eye_height = 2.6,
	floats=1,
	fly = true,
	-- True flight.
	motion_step = mcl_mobs.mob_class.flying_step,
	run_ai = ghast_run_ai,
	do_go_pos = ghast_do_go_pos,
	do_attack = ghast_do_attack,
	makes_footstep_sound = false,
	instant_death = true,
	fire_resistant = true,
	does_not_prevent_sleep = true,
	can_spawn = function(pos)
		if not minetest.get_item_group(minetest.get_node(pos).name,"solid") then return false end
		local p1=vector.offset(pos,-2,1,-2)
		local p2=vector.offset(pos,2,5,2)
		local nn = minetest.find_nodes_in_area(p1,p2,{"air"})
		if #nn< 41 then return false end
		return true
	end,
	do_custom = function(self)
		if self.firing == true then
			self.base_texture = {"mobs_mc_ghast_firing.png"}
			self.object:set_properties({textures=self.base_texture})
		else
			self.base_texture = {"mobs_mc_ghast.png"}
			self.object:set_properties({textures=self.base_texture})
		end
	end,
})


mcl_mobs.spawn_setup({
	name = "mobs_mc:ghast",
	type_of_spawning = "ground",
	dimension = "nether",
	min_light = 0,
	max_light = 15,
	aoc = 2,
	biomes = {
		"Nether",
		"SoulsandValley",
		"BasaltDelta",
	},
	chance = 400,
})

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

-- no damage to nodes explosion
local function fireball_safe_boom (self, pos, strength, no_remove)
	minetest.sound_play(self.sounds and self.sounds.explode or "tnt_explode", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = self.sounds and self.sounds.distance or 32
	}, true)
	local radius = strength
	blast_damage(pos, radius, self.object)
	mcl_mobs.effect(pos, 32, "mcl_particles_smoke.png", radius * 3, radius * 5, radius, 1, 0)
	if not no_remove then
		if self.is_mob then
			self:safe_remove()
		else
			self.object:remove()
		end
	end
end

-- make explosion with protection and tnt mod check
local function fireball_boom (self, pos, strength, fire, no_remove)
	if mobs_griefing and not minetest.is_protected(pos, "") then
		mcl_explosions.explode(pos, strength, { fire = fire }, self.object)
	else
		fireball_safe_boom(self, pos, strength, no_remove)
	end
	if not no_remove then
		if self.is_mob then
			self:safe_remove()
		else
			self.object:remove()
		end
	end
end

-- fireball (projectile)
mcl_mobs.register_arrow("mobs_mc:fireball", {
	description = S("Ghast Fireball"),
	visual = "sprite",
	visual_size = {x = 1, y = 1},
	textures = {"mcl_fire_fire_charge.png"},
	velocity = 24,
	collisionbox = {-.5, -.5, -.5, .5, .5, .5},
	_is_fireball = true,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = true,
	redirectable = true,
	hit_player = function(self, player)
		mcl_mobs.get_arrow_damage_func(6, "fireball")(self, player)
		local p = self.object:get_pos()
		if p then
			fireball_boom (self,p, 1, true)
		else
			fireball_boom (self,player:get_pos(), 1, true)
		end
	end,
	hit_mob = function(self, mob)
		if mob == self._shooter then
			mcl_mobs.get_arrow_damage_func (6000, "fireball") (self, mob)
		else
			mcl_mobs.get_arrow_damage_func(6, "fireball")(self, mob)
		end
		fireball_boom (self,self.object:get_pos(), 1, true)
	end,
	hit_node = function(self, pos, _)
		fireball_boom (self,pos, 1, true)
	end
})


-- spawn eggs
mcl_mobs.register_egg("mobs_mc:ghast", S("Ghast"), "#f9f9f9", "#bcbcbc", 0)
