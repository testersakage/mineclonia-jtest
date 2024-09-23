mcl_mobs.register_mob("mobs_mc:fox", {
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	damage = 3,
	hp_min = 10,
	hp_max = 10,
	xp_min = 1,
	xp_max = 3,
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	collisionbox = { -0.45, 0, -0.45, 0.45, 0.65, 0.45 },
	visual = "mesh",
	mesh = "mobs_mc_fox.b3d",
	visual_size = { x = 1, y = 1},
	textures = { "mobs_mc_fox.png" },
	--glow = 4,
	makes_footstep_sound = true,
	walk_velocity = 1,
	run_velocity = 4,
	view_range = 16,
	stepheight = 1.1,
	jump = true,
	jump_height = 10,
	suffocation = true,
	fear_height = 4,
	sounds = {
	   -- random = "",
	},
	drops = {
	   -- {name = "fox:fox", min = 1, max = 2},
	},
   animation = {
				-- SITTING = 30 , 50
				-- Sleeping = 55,75
				-- Widding = 170,230
		stand_start = 1, stand_end = 20, stand_speed = 10,
		walk_start = 120, walk_end = 160, speed_normal = 10,
		run_start = 160, run_end = 199, speed_run = 10,
		punch_start = 80, punch_end = 105, punch_speed =25,
		--die_start = 0, die_end = 0, die_speed = 0,--die_loop = 0,
	},
	--[[
	do_custom = function(self,dtime)
	end,
	on_spawn = function(self, pos)
		   --local pos = self.object:get_pos()
		end
	  on_die = function(self, pos)
		   --
	end
	]]
})

mcl_mobs.register_egg("mobs_mc:fox", "Fox", "#7f493b", "#e57a49", 0)
