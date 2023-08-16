local S = core.get_translator("mobs_mc")
local textures = {
	cold = "mobs_mc_frog.png",
	medium = "mobs_mc_frog_temperate.png",
	hot = "mobs_mc_frog_warm.png",
}

local function set_textures(self, biome_type)
	biome_type = biome_type or "medium"
	self.object:set_properties({
		textures = {
			textures[biome_type]
		},
	})
end

mcl_mobs.register_mob("mobs_mc:frog", {
	description = S("Frog"),
	stepheight = 3,
	type = "animal",
	passive = true,
	reach = 1,
	attack_npcs = false,
	attack_monsters = true,
	attack_animals = false,
	attack_type = "dogfight",
	damage = 1,
	hp_min = 5,
	hp_max = 25,
	armor = 100,
	collisionbox = {-0.268, -0.01, -0.268,  0.268, 0.25, 0.268},
	visual = "mesh",
	mesh = "mobs_mc_frog.b3d",
	drawtype = "front",
	textures = {
		{"mobs_mc_frog.png"},

	},
	sounds = {
		random = "frog",
	},
	makes_footstep_sound = true,
	walk_velocity = 2,
	visual_size = { x = 10, y = 10 },
	run_velocity = 3,
	specific_attack = { "mobs_mc:magma_cube_tiny", "mobs_mc:slime_tiny",  },
	runaway = true,
	runaway_from = {"mobs_mc:spider", "mobs_mc:axolotl"},
	jump = true,
	jump_height = 6,
	drops = {
		--{name = "mcl_mobitems:froglight", chance = 1, min = 1, max = 1},
	},
	water_damage = 0,
	lava_damage = 4,
	light_damage = 0,
	fear_height = 6,
	animation = {
		speed_normal = 100,
		stand_start = 1,
		stand_end = 100,
		walk_start = 100,
		walk_end = 200,
		fly_start = 250, -- swim animation
		fly_end = 350,
		die_start = 200,
		die_end = 300,
		die_speed = 50,
		die_loop = false,
		die_rotate = true,
	},
	fly_in = {"mcl_core:water_source", "mcl_core:water_flowing", "mclx_core:river_water_source", "mclx_core:river_water_flowing"},
	floats = 0,
	spawn_in_group = 6,
	spawn_in_group_min = 2,
	--follow = {},
	view_range = 6,
	--on_rightclick = function(self, clicker)
	--	if mobs:feed_tame(self, clicker, 8, true, true) then return end
	--	if mobs:protect(self, clicker) then return end
	--	if mobs:capture_mob(self, clicker, 15, 25, 0, false, nil) then return end
	--end,
	on_spawn = function(self)
		local pos = self.object:get_pos()
		local b = core.get_biome_name(core.get_biome_data(pos).biome)
		local bdef = core.registered_biomes[b]
		if bdef then
			set_textures(self,bdef._mcl_biome_type)
		end
	end,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "water",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level -5,
	biomes = {
		"flat",
		"MangroveSwamp",
		"MangroveSwamp_shore",
		"MangroveSwamp_ocean",
		"Swampland",
		"Swampland_shore",
		"SwampLand_ocean",
	},
	chance = 15000,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level,
	biomes = {
		"flat",
		"MangroveSwamp",
		"MangroveSwamp_shore",
		"Swampland",
		"Swampland_shore"
	},
	chance = 15000,
})

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:frog", S("Frog"), "#00AA00", "#db635f", 0)
