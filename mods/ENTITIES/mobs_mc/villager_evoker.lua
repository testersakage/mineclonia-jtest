--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

--###################
--################### EVOKER
--###################

local pr = PseudoRandom(os.time()*666)

mcl_mobs.register_mob("mobs_mc:evoker", {
	description = S("Evoker"),
	type = "monster",
	spawn_class = "hostile",
	can_despawn = false,
	physical = true,
	pathfinding = 1,
	hp_min = 24,
	hp_max = 24,
	xp_min = 10,
	xp_max = 10,
	head_swivel = "head.control",
	bone_eye_height = 6.3,
	head_eye_height = 2.2,
	curiosity = 10,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.95, 0.4},
	visual = "mesh",
	mesh = "mobs_mc_villager.b3d",
	textures = { {
		"mobs_mc_evoker.png",
		"blank.png", --no hat
		-- TODO: Attack glow
	} },
	makes_footstep_sound = true,
	damage = 6,
	walk_velocity = 1.2,
	run_velocity = 1.5,
	group_attack = true,
	attack_type = "dogshoot",
	custom_attack_interval = 15,
	active_vexes = {},
	custom_attack = function(self, _)
		self:fangs_attack()
	end,
	vex_attack = function(self)
		if #self.active_vexes >= 7 then return end
		for k,v in pairs(self.active_vexes) do
			if not v or v.health <= 0 then table.remove(self.active_vexes,k) end
		end
		local r = pr:next(1,4)
		local basepos = self.object:get_pos()
		basepos.y = basepos.y + 1
		for _ = 1, r do
			local spawnpos = vector.add(basepos, minetest.yaw_to_dir(pr:next(0,360)))
			local vex = minetest.add_entity(spawnpos, "mobs_mc:vex")
			if vex and vex:get_pos() then
				local ent = vex:get_luaentity()

				-- Mark vexes as summoned and start their life clock (they take damage it reaches 0)
				ent._summoned = true
				ent._lifetimer = pr:next(33, 108)

				table.insert(self.active_vexes,ent)
			end
		end
	end,
	fangs_attack = function(self)
		if self.attack and self.attack:get_pos() then
			local p = self.object:get_pos()
			local ap = self.attack:get_pos()
			local d = vector.direction(p, ap)
			for i = 1, 7 do
				local fp = vector.round(vector.add(p, d * i))
				fp.y = p.y
				if minetest.get_item_group(minetest.get_node(fp).name, "solid") <= 0 then
					minetest.add_entity(fp, "mobs_mc:evoker_fangs")
				end
			end
		end
	end,
	passive = false,
	drops = {
		{name = "mcl_core:emerald",
		chance = 1,
		min = 0,
		max = 1,
		looting = "common",},
		{name = "mcl_totems:totem",
		chance = 1,
		min = 1,
		max = 1,},
	},
	-- TODO: sounds
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 50,
		run_start = 0, run_end = 40, run_speed = 25,
		shoot_start = 142, shoot_end = 152, -- Magic arm swinging
	},
	view_range = 16,
	fear_height = 4,

	on_spawn = function(self)
		self.timer = 15
		return true
	end,
})

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:evoker", S("Evoker"), "#959b9b", "#1e1c1a", 0)

minetest.register_entity("mobs_mc:evoker_fangs", {
	initial_properties = {
		physical = true,
		collide_with_objects = true,
		visual = "mesh",
		mesh = "mobs_mc_evoker_fangs.b3d",
		textures = { "mobs_mc_evoker_fangs.png" },
		static_save = false,
	},
	_timer = 5,
	on_activate = function(self)
		self.object:set_animation({x = 0, y = 10}, 30, 0, false)
	end,
	on_step = function(self, dtime)
		self._timer = self._timer - dtime
		if self._timer < 0 then
			self.object:remove()
		end
	end
})
