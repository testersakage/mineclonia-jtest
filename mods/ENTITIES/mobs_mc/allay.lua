mcl_mobs.register_mob("mobs_mc:allay", {
	type = "animal",
	spawn_class = "passive",
	--damage = 1,
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	-- attack_type = "dogshoot",
	reach = 3,
	armor = 10,
	collisionbox = { -0.2, -0.1, -0.2, 0.2, 0.7, 0.2 },
	visual = "mesh",
	mesh = "mobs_mc_allay.b3d",
	visual_size = { x = 1, y = 1 },
	textures = {
		{"mobs_mc_allay.png"},
		{"mobs_mc_allay2.png"},
		{"mobs_mc_allay3.png"},
		{"mobs_mc_allay4.png"},
		{"mobs_mc_allay5.png"},
		{"mobs_mc_allay6.png"},
		{"mobs_mc_allay7.png"},
		},
	glow = 4,
	fly = true,
	fly_in = { "air" },
	fly_velocity = 4,
	--walk_velocity = 1,
	--run_velocity = 2,
	sounds = {
	   -- random = "",
	},
	drops = {
	   -- {name = "Allay:Allay", min = 1, max = 2},
	},
	view_range = 16,
	stepheight = 1.1,
	fall_damage = false,
	--instant_death = true,
	--fire_resistant = true,
	--suffocation = true,
	animation = {
				-- Dacing = 110,185
				-- Holding Item = 200,220
		stand_start = 0, stand_end = 40, stand_speed = 10,
		walk_start = 50, walk_end = 89, speed_normal = 10,
		run_start = 50, run_end = 89, speed_run = 15,
		--punch_start = 0, punch_end = 0, punch_speed =0,
		--shoot_start = 0, shoot_end = 0, die_speed = 0,
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

mcl_mobs.register_egg("mobs_mc:allay", "Allay", "#38e0e5", "#f7f8f8", 0)
