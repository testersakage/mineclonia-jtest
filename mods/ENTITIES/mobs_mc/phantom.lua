local S = minetest.get_translator(minetest.get_current_modname())

mcl_mobs.register_mob("mobs_mc:phantom", {
	description = S("Phantom"),
	type = "monster",
	spawn_class = "hostile",
	damage = 1,
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	attack_type = "dogfight",
	attack_players = true,
	reach = 3,
	armor = 10,
	collisionbox = { -0.4, -0.5, -0.4, 0.4, 0.5, 0.4 },
	visual = "mesh",
	mesh = "mobs_mc_phantom.b3d",
	visual_size = { x = 1, y = 1},
	textures = {
		{"mobs_mc_phantom.png"},
	},
	glow = 6,
	fly = true,
	fly_in = { "air" },
	fly_velocity = 4,
	sounds = {
	   -- random = "",
	},
	drops = {
	   -- {name = "mcl_mobitems:phantom_membrane", min = 1, max = 2},
	},

	view_range = 16,
	stepheight = 1.1,
	fall_damage = false,
   animation = {
				-- Dacing = 110,185
				-- Holding Item = 200,220
		stand_start = 1, stand_end = 160, stand_speed = 15,
		walk_start = 1, walk_end = 160, speed_normal = 15,
		run_start = 1, run_end = 160, speed_run = 15,
		punch_start = 1, punch_end = 160, punch_speed =15,
	},
})

mcl_mobs.register_egg("mobs_mc:phantom", "Phantom", "#162328", "#a078db", 0)
