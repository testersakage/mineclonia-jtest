mcl_mobs.register_mob("mobs_mc:ravager", {
	type = "monster",
	spawn_class = "hostile",
	attack_animals = true,
	attack_npcs = true,
	damage = 1, -- 45
	hp_min = 100,
	hp_max = 100,
	xp_min = 5,
	xp_max = 5,
	attack_type = "dogshoot",
	--double_melee_attack = false,
	reach = 3, -- Height: 2.9 blocks
	armor = 10,
	collisionbox = { -0.8, 0, -0.8, 0.8, 2.2, 0.8 },
	visual = "mesh",
	mesh = "mobs_mc_ravager.b3d",
	visual_size = { x = 1, y = 1},
	textures = { "mobs_mc_ravager.png" },
	walk_velocity = 1,
	run_velocity = 3,
	sounds = {
	   -- random = "",
	},
	drops = {
	   --{name = " ", min = 1, max = 2},
	},
	view_range = 16, -- 16 nodes
	stepheight = 1.1,
	--instant_death = true,
	fire_resistant = true,
	suffocation = false,
	all_damage = false,
	knock_back = false,
	animation = {
		stand_start = 1, stand_end = 40, stand_speed = 10,
		walk_start = 50, walk_end = 90, speed_normal = 10,
		run_start = 50, run_end = 90, speed_run = 20,
		punch_start = 100, punch_end = 140, punch_speed = 20,
	},
	--[[
	do_custom = function(self,dtime)
		---
	end,
	on_spawn = function(self, pos)
	 --
		end
	  on_die = function(self, pos)

	end
	]]
})

mcl_mobs.register_egg("mobs_mc:ravager", "Ravager", "#2b2522", "#1c1c1c", 0)
