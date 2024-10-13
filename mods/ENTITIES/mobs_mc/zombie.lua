--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

--###################
--################### ZOMBIE
--###################

local drops_common = {
	{name = "mcl_mobitems:rotten_flesh",
	chance = 1,
	min = 0,
	max = 2,
	looting = "common",},
	{name = "mcl_core:iron_ingot",
	chance = 120, -- 2.5% / 3
	min = 1,
	max = 1,
	looting = "rare",
	looting_factor = 0.01 / 3,},
	{name = "mcl_farming:carrot_item",
	chance = 120, -- 2.5% / 3
	min = 1,
	max = 1,
	looting = "rare",
	looting_factor = 0.01 / 3,},
	{name = "mcl_farming:potato_item",
	chance = 120, -- 2.5% / 3
	min = 1,
	max = 1,
	looting = "rare",
	looting_factor = 0.01 / 3,},
}

local drops_zombie = table.copy(drops_common)
table.insert(drops_zombie, {
	-- Zombie Head
	name = "mcl_heads:zombie",
	chance = 200, -- 0.5%
	min = 1,
	max = 1,
	mob_head = true,
})

local zombie = {
	description = S("Zombie"),
	type = "monster",
	spawn_class = "hostile",
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	head_swivel = "head.control",
	bone_eye_height = 6.3,
	head_eye_height = 1.74,
	curiosity = 7,
	head_pitch_multiplier=-1,
	breath_max = -1,
	wears_armor = "no_pickup",
	armor_drop_probability = {
		head = 0.085,
		torso = 0.085,
		legs = 0.085,
		feet = 0.085,
	},
	armor = {undead = 90, fleshy = 90},
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.94, 0.3},
	visual = "mesh",
	mesh = "mobs_mc_zombie.b3d",
	visual_size = { x = 1, y = 1.1 },
	textures = {
		{
			"mobs_mc_empty.png", -- armor
			"mobs_mc_zombie.png", -- texture
		}
	},
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_mc_zombie_growl",
		war_cry = "mobs_mc_zombie_growl",
		death = "mobs_mc_zombie_death",
		damage = "mobs_mc_zombie_hurt",
	},
	sound_params = {
		max_hear_distance = 16,
		gain = 0.5,
	},
	movement_speed = 4.6,
	damage = 3,
	reach = 2,
	fear_height = 4,
	pathfinding = 1,
	jump_height = 8.4,
	group_attack = { "mobs_mc:zombie", "mobs_mc:baby_zombie", "mobs_mc:husk", "mobs_mc:baby_husk" },
	drops = drops_zombie,
	animation = {
		stand_start = 40, stand_end = 49, stand_speed = 2,
		walk_start = 0, walk_end = 39, speed_normal = 25,
		run_start = 0, run_end = 39, speed_run = 50,
		punch_start = 50, punch_end = 59, punch_speed = 20,
	},
	specific_attack = {
		"mobs_mc:iron_golem"
	},
	ignited_by_sunlight = true,
	floats = 0,
	view_range = 16,
	attack_type = "melee",
	harmed_by_heal = true,
	attack_npcs = true,
}

function zombie:on_spawn ()
	-- Enable picking up armor for a random subset of
	-- skeletons.
	if math.random () < 0.55 then -- TODO: modify this by difficulty.
		self.wears_armor = true
	end
end

mcl_mobs.register_mob("mobs_mc:zombie", zombie)

-- Baby zombie.
-- A smaller and more dangerous variant of the zombie

local baby_zombie = table.merge(zombie, {
	description = S("Baby Zombie"),
	visual_size = { x = 0.5, y = 0.5, z = 0.5 },
	collisionbox = {-0.25, -0.01, -0.25, 0.25, 0.98, 0.25},
	xp_min = 12,
	xp_max = 12,
	child = 1,
	reach = 1,
	movement_speed = zombie.movement_speed + zombie.movement_speed * 0.5,
	animation = {
		stand_start = 100, stand_end = 109, stand_speed = 2,
		walk_start = 60, walk_end = 99, speed_normal = 40,
		run_start = 60, run_end = 99, speed_run = 80,
		punch_start = 109, punch_end = 119
	},
})

mcl_mobs.register_mob("mobs_mc:baby_zombie", baby_zombie)

-- Husk.
-- Desert variant of the zombie
local husk = table.copy(zombie)
husk.description = S("Husk")
husk.textures = {
		{
			"mobs_mc_empty.png", -- armor
			"mobs_mc_husk.png", -- texture
		}
	}
husk.ignited_by_sunlight = false
husk.drops = drops_common
husk.dealt_effect = {
    name = "hunger",
    dur = 7, -- TODO: regional difficulty.
    level = 1,
}
-- TODO: Husks avoid water

mcl_mobs.register_mob("mobs_mc:husk", husk)

-- Baby husk.
-- A smaller and more dangerous variant of the husk
local baby_husk = table.copy(baby_zombie)
baby_husk.description = S("Baby Husk")
baby_husk.textures = {{
	"mobs_mc_empty.png", -- wielded_item
	"mobs_mc_husk.png", -- texture
}}
baby_husk.ignited_by_sunlight = false
baby_husk.drops = drops_common
baby_husk.dealt_effect = {
    name = "hunger",
    dur = 7, -- TODO: regional difficulty.
    level = 1,
}

mcl_mobs.register_mob("mobs_mc:baby_husk", baby_husk)


mcl_mobs.spawn_setup({
	name = "mobs_mc:zombie",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes_except = {
		"MushroomIslandShore",
		"MushroomIsland"
	},
	chance = 1000,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:baby_zombie",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes_except = {
		"MushroomIslandShore",
		"MushroomIsland"
	},
	chance = 50,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:husk",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes = {
		"Desert",
	},
	chance = 2400,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:baby_husk",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes = {
		"Desert",
	},
	chance = 20,
})

-- Spawn eggs
mcl_mobs.register_egg("mobs_mc:husk", S("Husk"), "#777361", "#ded88f", 0)
mcl_mobs.register_egg("mobs_mc:zombie", S("Zombie"), "#00afaf", "#799c66", 0)
