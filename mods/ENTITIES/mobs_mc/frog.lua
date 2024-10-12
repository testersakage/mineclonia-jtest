local S = core.get_translator("mobs_mc")
local textures = {
	cold = "mobs_mc_frog.png",
	snowy = "mobs_mc_frog.png",
	medium = "mobs_mc_frog_temperate.png",
	hot = "mobs_mc_frog_warm.png",
}

local function set_textures(self, biome_type)
	local texture = textures[biome_type or "medium"] or textures["medium"]
	self.object:set_properties({
		textures = {
			texture
		},
	})
end

mcl_mobs.register_mob("mobs_mc:frog", {
	description = S("Frog"),
	type = "animal",
	passive = false,
	reach = 1,
	attack_npcs = false,
	attacks_monsters = true,
	attack_animals = false,
	attack_type = "dogfight",
	damage = 1,
	hp_min = 5,
	hp_max = 25,
	armor = 100,
	collisionbox = {-0.268, -0.01, -0.268,  0.268, 0.35, 0.268},
	visual = "mesh",
	mesh = "mobs_mc_frog.b3d",
	drawtype = "front",
	texture_list = {
		{"mobs_mc_frog.png"},
	},
	sounds = {
		random = "frog",
	},
	makes_footstep_sound = true,
	walk_velocity = 1,
	run_velocity = 4,
	view_range = 16,
	stepheight = 1.1,
	jump = true,
	jump_height = 10,
	visual_size = { x = 10, y = 10 },
	specific_attack = { "mobs_mc:magma_cube_tiny", "mobs_mc:slime_tiny",  },
	runaway = true,
	runaway_from = {"mobs_mc:spider", "mobs_mc:axolotl"},
	drops = {
		-- see magma cube for froglight drop
	},
	water_damage = 0,
	lava_damage = 4,
	light_damage = 0,
	fear_height = 6,
	animation = {
		speed_normal = 10, -- default animation speed
		stand_start = 1, stand_end = 80,
		walk_start = 90, walk_end = 105,
		run_start = 115, run_end = 125, run_speed = 15,
		swim_start = 145, swim_end = 165,
		punch_start = 130, punch_end = 140, punch_speed = 15, punch_loop = false,
	},
	swims = true,
	-- frog doesn't take drowning damage
	breath_max = -1,
	floats = 0,
	spawn_in_group = 5,
	spawn_in_group_min = 2,
	follow = {"mcl_mobitems:slimeball"},
	on_rightclick = function(self, clicker)
		if self:follow_holding(clicker) then
			if self:feed_tame(clicker, 8, true, false) then return end
		end
	end,
	on_spawn = function(self)
		local pos = vector.offset(self.object:get_pos(), math.random(-10, 10), 0, math.random(-10, 10))
		local b = core.get_biome_name(core.get_biome_data(pos).biome)
		local bdef = core.registered_biomes[b]
		if bdef then
			set_textures(self,bdef._mcl_biome_type)
		end
	end,
	on_breed = function(self)
		local pos = self.object:get_pos()
		local ww = core.find_nodes_in_area_under_air(vector.offset(pos, -self.view_range, -5, -self.view_range), vector.offset(pos, self.view_range, 20, self.view_range), {"group:water"})
		if ww and #ww > 0 then
			table.sort(ww, function(a, b) return vector.distance(pos, a) < vector.distance(pos, b) end)
			local p = ww[1]
			self:gopath(p, function()
				local sp = vector.offset(p, 0, 1, 0)
				core.set_node(sp, {name = "mcl_mobitems:frogspawn"})
				-- pathfinding sets order = "stand"
				self:roam()
			end)
		end
		return false
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
		"Swampland",
		"Swampland_shore",
		"SwampLand_ocean",
	},
	chance = 20,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level,
	biomes = {
		"flat",
		"Swampland",
		"Swampland_shore"
	},
	chance = 20,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "water",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level -5,
	biomes = {
		"MangroveSwamp",
		"MangroveSwamp_shore",
		"MangroveSwamp_ocean",
	},
	chance = 50,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level,
	biomes = {
		"MangroveSwamp",
		"MangroveSwamp_shore",
	},
	chance = 50,
})

mcl_mobs.register_egg("mobs_mc:frog", S("Frog"), "#00AA00", "#db635f", 0)

mcl_mobs.register_mob("mobs_mc:tadpole", {
	description = S("Tadpole"),
	type = "animal",
	spawn_class = "passive",
	damage = 8,
	hp_min = 6,
	hp_max = 6,
	spawn_in_group = 9,
	tilt_swim = true,
	armor = 100,
	collisionbox = { -0.2, -0.05, -0.2, 0.2, 0.5, 0.2 },
	visual = "mesh",
	mesh = "mobs_mc_tadpole.b3d",
	visual_size = { x = 10, y = 10 },
	texture_list = {
		{"mobs_mc_tadpole.png"},
	},
	makes_footstep_sound = false,
	swims = true,
	breathes_in_water = true,
	jump = false,
	view_range = 16,
	runaway = true,
	fear_height = 4,
	animation = {
		speed_normal = 10, -- default animation speed
		stand_start = 1, stand_end = 20,
		walk_start = 40, walk_end = 80,
		run_start = 40, run_end = 80, run_speed = 15,
	},
	follow = {"mcl_mobitems:slimeball"},
	on_rightclick = function(self, clicker)
		local item = clicker:get_wielded_item()
		local bn = item:get_name()
		if bn == "mcl_buckets:bucket_water" or bn == "mcl_buckets:bucket_river_water" then
			clicker:set_wielded_item("mcl_buckets:bucket_tadpole")
			self:safe_remove()
			return
		end
		if self:follow_holding(clicker) then
			if not core.is_creative_enabled(clicker:get_player_name()) then
				item:take_item()
				clicker:set_wielded_item(item)
			end
			self._grow_timer = self._grow_timer * 0.9
			return
		end
	end,
	on_spawn = function(self)
		self._grow_timer = math.random(600, 1200)
	end,
	do_custom = function(self, dtime)
		self._grow_timer = self._grow_timer - dtime
		if self._grow_timer < 0 then
			mcl_util.replace_mob(self.object, "mobs_mc:frog")
		end
	end
})

mcl_mobs.register_egg("mobs_mc:tadpole", "tadpole", "#3B2103", "#140C05", 0)
