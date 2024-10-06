local S = minetest.get_translator("mobs_mc")
local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false
local follow_spawner = minetest.settings:get_bool("wither_follow_spawner") ~= false
local w_strafes = minetest.settings:get_bool("wither_strafes") ~= false

local WITHER_INIT_BOOM = 7
local WITHER_MELEE_COOLDOWN = 3

local function atan(x)
	if not x or x ~= x then
		return 0
	else
		return math.atan(x)
	end
end

local function wither_unstuck(self)
	local pos = self.object:get_pos()
	if mobs_griefing then
		local col = self.object:get_properties().collisionbox or mcl_mobs.registered_mobs["mobs_mc:wither"].initial_properties.collisionbox
		local pos1 = vector.offset(pos, col[1], col[2], col[3])
		local pos2 = vector.offset(pos, col[4], col[5], col[6])
		for z = pos1.z, pos2.z do for y = pos1.y, pos2.y do for x = pos1.x, pos2.x do
			local npos = vector.new(x,y,z)
			local name = minetest.get_node(npos).name
			if name ~= "air" then
				local ndef = minetest.registered_nodes[name]
				if ndef and ndef._mcl_hardness and ndef._mcl_hardness >= 0 and ( ndef.can_dig == nil or ndef.can_dig(npos) )then
					minetest.remove_node(npos)
					local drops = minetest.get_node_drops(name, "")
					if drops then
						for _, item in pairs(drops) do
							minetest.add_item(npos, item)
						end
					end
				end
			end
		end end end
	end
	self:safe_boom(pos, 2, true)
end

local function get_dim_relative_y(pos)
		if (pos.y >= mcl_vars.mg_realm_barrier_overworld_end_max) then
			return pos.y
		elseif (pos.y <= mcl_vars.mg_nether_max + 200) then
			return (pos.y - mcl_vars.mg_nether_min - 20)
		else
			return (pos.y - mcl_vars.mg_end_min - 50)
		end
end

local wither_def = {
	description = S("Wither"),
	type = "monster",
	spawn_class = "hostile",
	hp_max = 300,
	hp_min = 300,
	xp_min = 50,
	xp_max = 50,
	armor = {undead = 80, fleshy = 100},
	-- This deviates from MC Wiki's size, which makes no sense
	collisionbox = {-0.9, 0.4, -0.9, 0.9, 2.45, 0.9},
	doll_size_override = { x = 1.2, y = 1.2 },
	visual = "mesh",
	mesh = "mobs_mc_wither.b3d",
	textures = {
		{"mobs_mc_wither.png"},
	},
	visual_size = {x=4, y=4},
	view_range = 50,
	fear_height = 4,
	movement_speed = 12,
	strafes = w_strafes,
	sounds = {
		shoot_attack = "mobs_mc_ender_dragon_shoot",
		attack = "mobs_mc_ender_dragon_attack",
		-- TODO: sounds
		distance = 60,
	},
	jump_height = 10,
	fly = true,
	makes_footstep_sound = false,
	can_despawn = false,
	drops = {
		{name = "mcl_mobitems:nether_star",
		chance = 1,
		min = 1,
		max = 1},
	},
	_mcl_freeze_damage = 0,
	lava_damage = 0,
	fire_damage = 0,
	attack_type = "custom",
	explosion_strength = 8,
	arrow = "mobs_mc:wither_skull",
	reach = 5,
	shoot_interval = 1,
	shoot_offset = -0.5,
	animation = {
		walk_speed = 12, run_speed = 12, stand_speed = 12,
		stand_start = 0, stand_end = 20,
		walk_start = 0,	walk_end = 20,
		run_start = 0,	run_end = 20,
	},
	harmed_by_heal = true,
	is_boss = true,
	extra_hostile = true,
	attack_exception = function(p)
		local ent = p:get_luaentity()
		if p:is_player() then return false end
		if not ent or not ent.is_mob or ent.harmed_by_heal or ent.name == "mobs_mc:ghast" then return true
		else return false end
	end,
	do_punch = function(self, hitter, tflp, tool_capabilities, dir) ---@diagnostic disable-line: unused-local
		if self._spawning or hitter == self.object then return false end
		local ent = hitter:get_luaentity()
		if ent and self._arrow_resistant and ent._is_arrow then return false end
		wither_unstuck(self)
		return true
	end,
	deal_damage = function(self, damage, mcl_reason)
		if self._spawning then return end
		wither_unstuck(self)
		self.health = self.health - damage
	end,
	on_spawn = function(self)
		minetest.sound_play("mobs_mc_wither_spawn", {gain=1.0})
		self._custom_timer = 0.0
		self._death_timer = 0.0
		self._health_old = self.object:get_properties().hp_max
		self._spawning = 10
		return true
	end,
}

function wither_def:do_custom (self, dtime, moveresult)
	if self._spawning then
		if not self._spw_max then self._spw_max = self._spawning end
		self._spawning = self._spawning - dtime
		local bardef = {
			color = "dark_purple",
			text = "Wither spawning",
			percentage = math.floor((self._spw_max - self._spawning) / self._spw_max * 100),
		}

		local pos = self.object:get_pos()
		for player in mcl_util.connected_players() do
			local d = vector.distance(pos, player:get_pos())
			if d <= 80 then
				mcl_bossbars.add_bar(player, bardef, true, d)
			end
		end
		self.object:set_yaw(self._spawning*10)

		local factor = math.floor((math.sin(self._spawning*10)+1.5) * 85)
		local str = minetest.colorspec_to_colorstring({r=factor, g=factor, b=factor})
		self.object:set_texture_mod("^[brighten^[multiply:"..str)

		if self._spawning <= 0 then
			if mobs_griefing and not minetest.is_protected(pos, "") then
				mcl_explosions.explode(pos, WITHER_INIT_BOOM, { drop_chance = 1.0 }, self.object)
			else
				mcl_mobs.mob_class.safe_boom(self, pos, WITHER_INIT_BOOM)
			end
			self.object:set_texture_mod("")
			self._spawning = nil
			self._spw_max = nil
		else
			return false
		end
	end

	self._custom_timer = self._custom_timer + dtime
	if self._custom_timer > 1 then
		self.health = math.min(self.health + 1, self.object:get_properties().hp_max)
		self._custom_timer = self._custom_timer - 1
	end

	local rand_factor
	if self.health < (self.object:get_properties().hp_max / 2) then
		self.base_texture = "mobs_mc_wither_half_health.png"
		self.fly = false
		self._arrow_resistant = true
		rand_factor = 3
	else
		self.base_texture = "mobs_mc_wither.png"
		self.fly = true
		self._arrow_resistant = false
		rand_factor = 10
	end
	if not self.attack then
		local y = get_dim_relative_y(self.object:get_pos())
		if y > 0 then
			self.fly = false
		else
			self.fly = true
			local vel = self.object:get_velocity()
			-- self.object:set_velocity(vector.new(vel.x, self.walk_velocity, vel.z))
			-- TODO
		end
	end
	self.object:set_properties({textures={self.base_texture}})
	mcl_bossbars.update_boss(self.object, "Wither", "dark_purple")
	if math.random(1, rand_factor) < 2 then
		self.arrow = "mobs_mc:wither_skull_strong"
	else
		self.arrow = "mobs_mc:wither_skull"
	end
end

mcl_mobs.register_mob("mobs_mc:wither", wither_def)

local wither_rose_soil = { "group:grass_block", "mcl_core:dirt", "mcl_core:coarse_dirt", "mcl_nether:netherrack", "group:soul_block", "mcl_mud:mud", "mcl_lush_caves:moss" }
local function spawn_wither_rose(obj)
	local n = minetest.find_node_near(obj:get_pos(),2,wither_rose_soil)
	if n then
		local p = vector.offset(n,0,1,0)
		if minetest.get_node(p).name == "air" then
			if not ( mobs_griefing and minetest.place_node(p,{name="mcl_flowers:wither_rose"}) ) then
				minetest.add_item(p,"mcl_flowers:wither_rose")
			end
		end
	end
end

mcl_mobs.register_arrow("mobs_mc:wither_skull", {
	visual = "cube",
	visual_size = {x = 0.3, y = 0.3},
	textures = {
		"mobs_mc_wither_projectile.png^[verticalframe:6:0", -- top
		"mobs_mc_wither_projectile.png^[verticalframe:6:1", -- bottom
		"mobs_mc_wither_projectile.png^[verticalframe:6:2", -- left
		"mobs_mc_wither_projectile.png^[verticalframe:6:3", -- right
		"mobs_mc_wither_projectile.png^[verticalframe:6:4", -- back
		"mobs_mc_wither_projectile.png^[verticalframe:6:5", -- front
	},
	velocity = 7,
	rotate = 90,
	_lifetime = 350,
	on_punch = function() end,

	-- direct hit
	hit_player = function(self, player)
		local pos = vector.new(self.object:get_pos())
		mcl_potions.give_effect("withering", player, 2, 10)
		player:punch(self.object, 1.0, {
			full_punch_interval = 0.5,
			damage_groups = {fleshy = 8},
		}, nil)
		mcl_mobs.mob_class.boom(self, pos, 1)
		if player:get_hp() <= 0 then
			local shooter = self._shooter:get_luaentity()
			if shooter then shooter.health = shooter.health + 5 end
			spawn_wither_rose(player)
		end
	end,

	hit_mob = function(self, mob)
		local pos = vector.new(self.object:get_pos())
		mcl_potions.give_effect("withering", mob, 2, 10)
		mob:punch(self.object, 1.0, {
			full_punch_interval = 0.5,
			damage_groups = {fleshy = 8},
		}, nil)
		mcl_mobs.mob_class.boom(self, pos, 1)
		local l = mob:get_luaentity()
		if l and l.health - 8 <= 0 then
			local shooter = self._shooter:get_luaentity()
			if shooter then shooter.health = shooter.health + 5 end
			spawn_wither_rose(mob)
		end
	end,

	-- node hit, explode
	hit_node = function(self, pos)
		mcl_mobs.mob_class.boom(self,pos, 1, false, true)
	end
})

mcl_mobs.register_arrow("mobs_mc:wither_skull_strong", {
	visual = "cube",
	visual_size = {x = 0.35, y = 0.35},
	textures = {
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:0", -- top
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:1", -- bottom
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:2", -- left
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:3", -- right
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:4", -- back
		"mobs_mc_wither_projectile_strong.png^[verticalframe:6:5", -- front
	},
	velocity = 4,
	rotate = 90,
	_lifetime = 500,
	on_punch = function() end,

	-- direct hit
	hit_player = function(self, player)
		local pos = vector.new(self.object:get_pos())
		mcl_potions.give_effect("withering", player, 2, 10)
		player:punch(self.object, 1.0, {
			full_punch_interval = 0.5,
			damage_groups = {fleshy = 12},
		}, nil)
		if mobs_griefing and not minetest.is_protected(pos, "") then
			mcl_explosions.explode(pos, 1, { drop_chance = 1.0, max_blast_resistance = 0, }, self.object)
		else
			mcl_mobs.mob_class.safe_boom(self, pos, 1) --need to call it this way bc self is the "arrow" object here
		end
		if player:get_hp() <= 0 then
			local shooter = self._shooter:get_luaentity()
			if shooter then shooter.health = shooter.health + 5 end
			spawn_wither_rose(player)
		end
	end,

	hit_mob = function(self, mob)
		local pos = vector.new(self.object:get_pos())
		mcl_potions.give_effect("withering", mob, 2, 10)
		mob:punch(self.object, 1.0, {
			full_punch_interval = 0.5,
			damage_groups = {fleshy = 12},
		}, nil)
		if mobs_griefing and not minetest.is_protected(pos, "") then
			mcl_explosions.explode(pos, 1, { drop_chance = 1.0, max_blast_resistance = 0, }, self.object)
		else
			mcl_mobs.mob_class.safe_boom(self, pos, 1, true) --need to call it this way bc self is the "arrow" object here
		end
		local l = mob:get_luaentity()
		if l and l.health - 8 <= 0 then
			local shooter = self._shooter:get_luaentity()
			if shooter then shooter.health = shooter.health + 5 end
			spawn_wither_rose(mob)
		end
	end,

	-- node hit, explode
	hit_node = function(self, pos)
		if mobs_griefing and not minetest.is_protected(pos, "") then
			mcl_explosions.explode(pos, 1, { drop_chance = 1.0, max_blast_resistance = 0, }, self.object)
		else
			mcl_mobs.mob_class.safe_boom(self, pos, 1, true) --need to call it this way bc self is the "arrow" object here
		end
	end
})

--Spawn egg
mcl_mobs.register_egg("mobs_mc:wither", S("Wither"), "#4f4f4f", "#4f4f4f", 0, true)

mcl_wip.register_wip_item("mobs_mc:wither")
