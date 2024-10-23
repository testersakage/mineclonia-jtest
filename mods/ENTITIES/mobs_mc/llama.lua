local S = minetest.get_translator("mobs_mc")
local mob_class = mcl_mobs.mob_class
local horse = mobs_mc.horse

-- table mapping unified color names to non-conforming color names in carpet texture filenames
local messytextures = {
	grey = "gray",
	silver = "light_gray",
}

local llama = {
	description = S("Llama"),
	type = "animal",
	spawn_class = "passive",
	passive = false,
	attack_type = "ranged",
	ranged_interval_min = 4.0,
	ranged_interval_max = 4.0,
	ranged_attack_radius = 20.0,
	arrow = "mobs_mc:llamaspit",
	retaliates = true,
	spawn_in_group_min = 4,
	spawn_in_group = 6,
	head_swivel = "head.control",
	bone_eye_height = 11,
	head_eye_height = 1.7765,
	horizontal_head_height=0,
	curiosity = 10,
	head_yaw = "z",
	hp_min = 15,
	hp_max = 30,
	xp_min = 1,
	xp_max = 3,
	collisionbox = {-0.45, -0.01, -0.45, 0.45, 1.86, 0.45},
	visual_size = { x = 1, y = 1, },
	visual = "mesh",
	mesh = "mobs_mc_llama.b3d",
	textures = { -- 1: chest -- 2: decor (carpet) -- 3: llama base texture
		{"blank.png", "blank.png", "mobs_mc_llama_brown.png"},
		{"blank.png", "blank.png", "mobs_mc_llama_creamy.png"},
		{"blank.png", "blank.png", "mobs_mc_llama_gray.png"},
		{"blank.png", "blank.png", "mobs_mc_llama_white.png"},
		{"blank.png", "blank.png", "mobs_mc_llama.png"},
	},
	movement_speed = 3.5,
	drops = {
		{name = "mcl_mobitems:leather",
		 chance = 1,
		 min = 0,
		 max = 2,
		 looting = "common",},
	},
	sounds = {
		random = "mobs_mc_llama",
		eat = "mobs_mc_animal_eat_generic",
		-- TODO: Death and damage sounds
		distance = 16,
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 25,
		run_start = 0, run_end = 40, run_speed = 30,
	},
	child_animations = {
		stand_start = 41, stand_end = 41,
		walk_start = 41, walk_end = 81, walk_speed = 25,
		run_start = 41, run_end = 81, run_speed = 30,
	},
	_food_items = {
		["mcl_farming:wheat_item"] = {
			2.0, -- Health
			10, -- Age delta in MC ticks.
			3, -- Temper.
		},
		["mcl_farming:hay_block"] = {
			10.0, -- Health.
			90, -- Age delta in MC ticks.
			6, -- Temper.
			true,
		},
	},
	_max_temper = 30,
	pacing_bonus = 0.7,
	follow_bonus = 1.25,
	follow_herd_bonus = 1.0,
	follow = {
		"mcl_farming:hay_block",
	},
	tracking_distance = 40,
}

------------------------------------------------------------------------------
-- Llama spawning.
------------------------------------------------------------------------------

local pr = PcgRandom (os.time () + 410)
local r = 1 / 2147483647

function llama:on_breed (parent1, parent2)
	local pos = parent1.object:get_pos()
	local child, parent
	if math.random(1,2) == 1 then
		parent = parent1
	else
		parent = parent2
	end
	child = mcl_mobs.spawn_child(pos, parent.name)
	if child then
		local ent_c = child:get_luaentity()
		ent_c.base_texture = table.copy(ent_c.base_texture)
		ent_c.base_texture[2] = "blank.png"
		ent_c:set_textures (ent_c.base_texture)
		ent_c.owner = parent.owner

		local s1 = parent1._llama_strength
		local s2 = parent2._llama_strength
		local child_strength = pr:next (1, math.max (s1, s2))
		if pr:next (0, 2147483647) * r < 0.05
			and child_strength < 5 then
			child_strength = child_strength + 1
		end
		ent_c._llama_strength = child_strength
		ent_c._inv_size = child_strength * 5
		return false
	end
end

function llama:breeding_possible ()
	return self.tamed
end

function llama:initial_movement_properties ()
	local hp_max = self:generate_hp_max ()

	self.object:set_properties ({
			hp_max = hp_max,
	})
	self.hp_max = hp_max
	self.health = hp_max

	local chance = pr:next (0, 2147483647) * r
	local max_bonus = chance < 0.04 and 5 or 3
	self._llama_strength = 1 + pr:next (0, max_bonus - 1)
	self._inv_size = self._llama_strength * 5
end

function llama:on_spawn ()
	self._naked_texture = self.base_texture[3]
	horse.on_spawn (self)
end

function llama:mob_activate (staticdata, dtime)
	horse.mob_activate (self, staticdata, dtime)
	self:remove_physics_factor ("tracking_distance",
				    "mobs_mc:llama_wolf_attack")
end

------------------------------------------------------------------------------
-- Llama appearances.
------------------------------------------------------------------------------

function llama:extra_textures (colorstring)
	local carpet = ItemStack (self._saddle)
	local chest = self._chest
	local textures = {
		"blank.png",
		"blank.png",
		self._naked_texture,
	}
	if chest then
		textures[1] = self._naked_texture
	end
	local def = carpet:get_definition ()
	if def and def._color then
		local carpet_texture = table.concat ({
			"mobs_mc_llama_decor_",
			messytextures[def._color] or def._color,
			".png",
		})
		textures[2] = carpet_texture
	end
	return textures
end

function llama:is_saddle_item (item)
	local name = item:get_name ()
	local def = item:get_definition ()
	return minetest.get_item_group (name, "carpet") > 0
		and def and def._color
end

------------------------------------------------------------------------------
-- Llama AI.
------------------------------------------------------------------------------

function llama:join_caravan (head)
	local entity = head:get_luaentity ()
	self._caravan_head = head
	entity._caravan_tail = self.object
	self._caravan_timeout = 0
	self._caravan_speed_factor = 2.1
end

function llama:leave_caravan ()
	if self._caravan_head then
		local entity = self._caravan_head:get_luaentity ()
		if entity then
			entity._caravan_tail = nil
		end
		self._caravan_head = nil
	end
	self:cancel_navigation ()
	self:halt_in_tracks ()
end

function llama:check_caravan ()
	if self._caravan_head
		and not self._caravan_head:is_valid () then
		self._caravan_head = nil
	end
	-- Disband caravan if no longer leashed.
	if not self._caravan_head
		and not self:is_leashed ()
		and self._caravan_tail then
		local entity = self._caravan_tail:get_luaentity ()
		self._caravan_tail = nil

		if entity then
			entity._caravan_head = nil
		end
	end
	if self._caravan_tail
		and not self._caravan_tail:is_valid () then
		self._caravan_tail = nil
	end
end

function llama:is_leashed ()
	-- TODO: leashes
	-- -- For the present any llama with a driver is taken to be
	-- -- leashed.
	-- return self.tamed and self.driver ~= nil
	return false
end

function llama:count_ahead ()
	local n = 0
	local head = self._caravan_head
	while head ~= nil do
		local entity = head:get_luaentity ()
		n = n + 1
		head = entity and entity._caravan_head or nil
	end
	return n
end

local function llama_follow_caravan (self, self_pos, dtime)
	self:check_caravan ()
	if self._caravan_head then
		local head_pos = self._caravan_head:get_pos ()
		local distance = vector.distance (self_pos, head_pos)
		local speed_factor = self._caravan_speed_factor
		if distance > 26 then
			if speed_factor < 3.0 then
				speed_factor = speed_factor * 1.2
				self._caravan_speed_factor = speed_factor
				self._caravan_timeout = 2
			end
			self.gowp_velocity
				= self.movement_speed * speed_factor
			if self._caravan_timeout == 0 then
				self:leave_caravan ()
				return false
			end
		end

		self._caravan_timeout
			= math.max (0, self._caravan_timeout - dtime)
		if distance > 3.0 then
			if self:check_timer ("llama_caravan", 0.3) then
				self:gopath (head_pos, nil, true, self._caravan_speed_factor,
					     "run", 3.0)
			end
		else
			self:cancel_navigation ()
			self:halt_in_tracks ()
		end
		return true
	else
		-- Attempt to locate a llama within a 9 block radius
		-- that leashed or is fewer than 7 llamas removed from
		-- its leasher.
		if not self:check_timer ("llama_join_caravan", 0.3) then
			return false
		end
		local closest_straggler, closest_leashed, d1, d2

		for object in minetest.objects_inside_radius (self_pos, 9) do
			local entity = object:get_luaentity ()
			if entity and entity.name == "mobs_mc:llama" then
				local dist = vector.distance (object:get_pos (), self_pos)
				if (not closest_straggler or dist < d1)
					and entity._caravan_head
					and not entity._caravan_tail then
					closest_straggler = entity
					d1 = dist
				end
				if (not closest_leashed or dist < d2)
					and entity:is_leashed ()
					and not entity._caravan_tail then
					closest_leashed = entity
					d2 = dist
				end
			end
		end

		-- Minecraft punts very readily if the closest
		-- straggler is unavailable.
		if closest_straggler then
			local num_llamas = closest_straggler:count_ahead ()
			if num_llamas > 7 then
				return false
			end
			self:join_caravan (closest_straggler.object)
			return "_caravan_head"
		end
		if closest_leashed then
			self:join_caravan (closest_leashed.object)
			return "_caravan_head"
		end
		return false
	end
end

function llama:attack_end ()
	self:remove_physics_factor ("tracking_distance",
				    "mobs_mc:llama_wolf_attack")
end

function llama:discharge_ranged (self_pos, target_pos)
	mob_class.discharge_ranged (self, self_pos, target_pos)

	-- Call off the attack after firing once.
	if self._is_retaliating then
		self.attack = nil
		self:attack_end ()
	end
end

function llama:should_attack (object)
	local entity = object:get_luaentity ()
	return entity
		and entity.name == "mobs_mc:wolf"
		and not entity.tamed
		and entity:valid_enemy ()
end

function llama:retaliate_against (source)
	mob_class.retaliate_against (self, source)
	self._is_retaliating = true
end

function llama:do_attack (object, persistence)
	mob_class.do_attack (self, object, persistence)
	self._is_retaliating = false
end

function llama:attack_default (self_pos, dtime, esp)
	local rc = mob_class.attack_default (self, self_pos, dtime, esp)
	-- Don't be so dogged in pursuing wolves.
	if rc then
		local entity = rc:get_luaentity ()
		if entity and entity.name == "mobs_mc:wolf" then
			self:add_physics_factor ("tracking_distance",
						 "mobs_mc:llama_wolf_attack", 0.25)
		end
	end
	return rc
end

llama.ai_functions = {
	horse.check_tame,
	llama_follow_caravan,
	mob_class.check_attack,
	mob_class.check_frightened,
	mob_class.check_breeding,
	mob_class.check_following,
	mob_class.follow_herd,
	mob_class.check_pace,
}

------------------------------------------------------------------------------
-- Llama inventories.
------------------------------------------------------------------------------

function llama:generate_inventory_formspec ()
	if not self._armor_inv_name then
		return "formspec_version[6]"
	end
	local objectname = mcl_util.get_object_name (self.object)
	objectname = minetest.formspec_escape (objectname)
	local armorname = self._armor_inv_name
	armorname = minetest.formspec_escape ("detached:" .. armorname)
	local chest_itemslots
	if self._chest then
		chest_itemslots = string.format ("list[detached:%s;main;5.375,0.875;%d,3;]",
					 self._inv_id, self._llama_strength)
	else
		chest_itemslots = "image[5.375,0.825;6.10,3.625;mcl_formspec_itemslot.png;2]"
	end
	return table.concat ({
		"formspec_version[6]",
		"size[11.75,10.45]",
		"position[0.5,0.5]",
		string.format ("label[0.375,0.5;%s]", objectname),
		mcl_formspec.get_itemslot_bg_v4 (0.375, 2.25, 1, 1),
		string.format ("list[%s;main;0.375,2.25;1,1;]", armorname),
		"image[1.55,0.825;3.625,3.625;mcl_inventory_background9.png;2]",
		string.format ("model[1.55,0.875;3.625,3.5;horse;mobs_mc_llama_preview.b3d;%s;%s]",
			       table.concat (self.base_texture, ","), "-15,135,0"),
		self._chest and mcl_formspec.get_itemslot_bg_v4 (5.375, 0.875,
								 self._llama_strength, 3) or "",
		chest_itemslots,
		-- Main inventory.
		mcl_formspec.get_itemslot_bg_v4 (0.375, 5, 9, 3),
		"list[current_player;main;0.375,5;9,3;9]",
		-- Hotbar.
		mcl_formspec.get_itemslot_bg_v4 (0.375, 8.95, 9, 1),
		"list[current_player;main;0.375,8.95;9,1;]",
		string.format ("listring[%s;main]", armorname),
		self._chest and string.format ("listring[detached:%s;main]",
					self._inv_id) or "",
		"listring[current_player;main]",
	})
end

------------------------------------------------------------------------
-- Llama mounting.
------------------------------------------------------------------------

function llama:init_attachment_position ()
	local vsize = self.object:get_properties().visual_size
	self.driver_attach_at = {x = 0, y = 12.7, z = -5}
	self.driver_eye_offset = {x = 0, y = 6, z = 0}
	self.driver_scale = {x = 1/vsize.x, y = 1/vsize.y}
end

function llama:should_drive ()
	return false
end

mcl_mobs.register_mob ("mobs_mc:llama", table.merge (horse, llama))

mcl_entity_invs.register_inv("mobs_mc:llama","Llama",nil,true)

mcl_mobs.register_arrow("mobs_mc:llamaspit", {
	visual = "sprite",
	visual_size = {x = 0.10, y = 0.10},
	textures = {"mobs_mc_llama_spit.png"},
	velocity = 20,
	hit_player = mcl_mobs.get_arrow_damage_func (1),
	hit_mob = mcl_mobs.get_arrow_damage_func (1),
	tail = 1,
	tail_texture = "mcl_particles_smoke.png",
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:llama",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 5,
	min_height = mobs_mc.water_level+15,
	biomes = {
		"Savanna",
		"SavannaM",
		"SavannaM_beach",
		"Savanna_beach",
		"Savanna_ocean",
		"ExtremeHills",
		"ExtremeHills_beach",
		"ExtremeHillsM",
	},
	chance = 50,
})

mcl_mobs.register_egg("mobs_mc:llama", S("Llama"), "#c09e7d", "#995f40", 0)
