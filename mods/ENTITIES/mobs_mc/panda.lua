mcl_mobs.register_mob("mobs_mc:panda", {
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	damage = 3,
	hp_min = 10,
	hp_max = 20,
	xp_min = 1,
	xp_max = 3,
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	collisionbox = { -0.6, 0, -0.6, 0.6, 1.4, 0.6 },
	visual = "mesh",
	mesh = "mobs_mc_panda.b3d",
	visual_size = { x = 1, y = 1},
	textures = {
	{"mobs_mc_panda.png"},
	--	{"brown_panda.png"},
	--	{"weak_panda.png"}
	},
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
	   -- {name = "panda:panda", min = 1, max = 2},
	},
   animation = {
				--  Food = 260 , 295
		stand_start = 0, stand_end = 25, stand_speed = 10,
		-- stand2_start = 80, stand2_end = 90, stand2_speed = 10, --Stand Embarrassed
		-- stand3_start = 95, stand3_end = 240, stand3_speed = 10, --Stand Lying
		walk_start = 30, walk_end = 70, speed_normal = 10,
		run_start = 30, run_end = 70, speed_run = 15,
		punch_start = 30, punch_end = 70, punch_speed =15,
		--die_start = 0, die_end = 0, die_speed = 0,--die_loop = 0,
	},
	--[[
	do_custom = function(self,dtime)

	  --

	end,


	on_spawn = function(self, pos)

		   --local pos = self.object:get_pos()
		end




	  on_die = function(self, pos)
		   --
	end

	]]



})


mcl_mobs.register_egg("mobs_mc:panda", "panda", "#fceee3", "#242629", 0)
