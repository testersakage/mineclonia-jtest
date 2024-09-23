mcl_mobs.register_mob("mobs_mc:goat", {
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	damage = 3,
	hp_min = 10,
	hp_max = 10,
	xp_min = 1,
	xp_max = 3,
	---------
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	collisionbox = { -0.6, 0, -0.6, 0.6, 1.2, 0.6 },
	visual = "mesh",
	mesh = "mobs_mc_goat.b3d",
	visual_size = { x = 1, y = 1},
	textures = { "mobs_mc_goat.png" },
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
	   -- {name = "goat:goat", min = 1, max = 2},
	},
	animation = {
		stand_start = 0, stand_end = 20, stand_speed = 10,
		walk_start = 60, walk_end = 139, speed_normal = 10,
		run_start = 160, run_end = 199, speed_run = 10,
		punch_start = 240, punch_end = 260, punch_speed =25,
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

mcl_mobs.register_egg("mobs_mc:goat", "Goat", "#847167", "#e1d1c4", 0)
