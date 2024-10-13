local S = core.get_translator("mobs_mc")
mcl_mobs.register_mob("mobs_mc:ravager", {
	description = S("Ravager"),
	type = "monster",
	spawn_class = "hostile",
	attack_animals = true,
	attack_npcs = true,
	damage = 1, -- 45
	hp_min = 100,
	hp_max = 100,
	xp_min = 5,
	xp_max = 5,
	attack_type = "dogfight",
	reach = 3,
	armor = 10,
	collisionbox = { -0.8, 0, -0.8, 0.8, 2.2, 0.8 },
	visual = "mesh",
	mesh = "mobs_mc_ravager.b3d",
	visual_size = { x = 1, y = 1},
	texture_list = {
		{"mobs_mc_ravager.png" },
	},
	walk_velocity = 1,
	run_velocity = 3,
	sounds = {
	   -- random = "",
	},
	drops = {
		{ name = "mcl_mobitems:saddle", min = 1, max = 1, chance = 1 },
	},
	view_range = 32,
	stepheight = 1.1,
	fire_resistant = true,
	suffocation = false,
	all_damage = false,
	knock_back = true,
	specific_attack = { "player", "mobs_mc:iron_golem", "mobs_mc:villager", "mobs_mc:wandering_trader" },
	animation = {
		stand_start = 1, stand_end = 40, stand_speed = 10,
		walk_start = 50, walk_end = 90, speed_normal = 10,
		run_start = 50, run_end = 90, run_speed = 20,
		punch_start = 100, punch_end = 140, punch_speed = 20,
	},
})

mcl_mobs.register_egg("mobs_mc:ravager", "Ravager", "#2b2522", "#1c1c1c", 0)
