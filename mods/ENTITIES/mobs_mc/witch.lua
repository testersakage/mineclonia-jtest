--MCmobs v0.2
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

--###################
--################### WITCH
--###################




mcl_mobs.register_mob("mobs_mc:witch", {
	description = S("Witch"),
	type = "monster",
	spawn_class = "hostile",
	can_despawn = true,
	hp_min = 26,
	hp_max = 26,
	xp_min = 5,
	xp_max = 5,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.94, 0.3},
	doll_size_override = { x = 0.95, y = 0.95 },
	visual = "mesh",
	mesh = "mobs_mc_witch.b3d",
	textures = {
		{"mobs_mc_witch.png"},
	},
	visual_size = {x=2.75, y=2.75},
	makes_footstep_sound = true,
	damage = 2,
	reach = 2,
	walk_velocity = 1,
	run_velocity = 1.4,
	pathfinding = 1,
	group_attack = true,
	attack_type = "dogshoot",
	arrow = "mobs_mc:potion_arrow",
	shoot_interval = 2.5,
	shoot_offset = 1,
	dogshoot_switch = 1,
	dogshoot_count_max =1.8,
	max_drops = 3,
	drops = {
		-- TODO: drops some useful potions
		{name = "mcl_potions:glass_bottle", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mcl_nether:glowstone_dust", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mcl_mobitems:gunpowder", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mesecons:redstone", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mcl_mobitems:spider_eye", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mcl_core:sugar", chance = 8, min = 0, max = 2, looting = "common",},
		{name = "mcl_core:stick", chance = 4, min = 0, max = 2, looting = "common",},
	},
	-- TODO: sounds
	animation = {
		speed_normal = 30,
		speed_run = 60,
		stand_start = 0,
		stand_end = 0,
		walk_start = 0,
		walk_end = 40,
		run_start = 0,
		run_end = 40,
		hurt_start = 85,
		hurt_end = 115,
		death_start = 117,
		death_end = 145,
		shoot_start = 50,
		shoot_end = 82,
	},
	view_range = 16,
	fear_height = 4,
	deal_damage = function(self, damage, mcl_reason)
		local factor = 1
		if mcl_reason.type == "magic" then factor = 0.15 end
		self.health = self.health - factor*damage
	end,
})

-- potion projectile (EXPERIMENTAL)
-- TODO: throw varies of potions based on range and/or when player still didn't have the effect
mcl_mobs.register_arrow("mobs_mc:potion_arrow", {
	visual = "sprite",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"mcl_potions_splash_overlay.png^[colorize:#4E9331:127^mcl_potions_splash_bottle.png"},
	velocity = 6,

	-- direct hit, no poison... just plenty of pain
	hit_player = mcl_mobs.get_arrow_damage_func(4, "mob"),
	hit_mob = mcl_mobs.get_arrow_damage_func(4, "mob"),

	-- node hit, splash poison
	hit_node = function(_, pos, _)
		minetest.add_entity(pos, "mcl_potions:poison_2_splash_flying")
	end
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:witch",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes_except = {
		"MushroomIslandShore",
		"MushroomIsland",
		"DeepDark",
	},
	chance = 200,
})

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:witch", S("Witch"), "#340000", "#51a03e", 0, true)

mcl_wip.register_wip_item("mobs_mc:witch")
