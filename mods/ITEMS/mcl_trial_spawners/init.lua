local modname = core.get_current_modname()
local S = core.get_translator(modname)

local activation_radius = 14
local spawning_radius = 4
local activation_cooldown = 30 * 60 * 1000
local spawning_interval = 2 * 1000

local standard_loot_table = {
	stacks_min = 1,
	stacks_max = 1,
	items = {
		{ itemstring = "mcl_farming:bread",             weight = 3, amount_min = 1, amount_max = 3 },
		{ itemstring = "mcl_mobitems:cooked_chicken",   weight = 3, amount_min = 1, amount_max = 1 },
		{ itemstring = "mcl_farming:potato_item_baked", weight = 2, amount_min = 1, amount_max = 3 },
		{ itemstring = "mcl_potions:regeneration",      weight = 1, amount_min = 1, amount_max = 1 },
		{ itemstring = "mcl_potions:swiftness",         weight = 1, amount_min = 1, amount_max = 1 },
	}
}

local ominous_loot_table = {
	stacks_min = 1,
	stacks_max = 1,
	items = {
		{ itemstring = "mcl_farming:potato_item_baked", weight = 3, amount_min = 2, amount_max = 4 },
		{ itemstring = "mcl_mobitems:cooked_beef",      weight = 3, amount_min = 1, amount_max = 2 },
		{ itemstring = "mcl_farming:carrot_item_gold",  weight = 2, amount_min = 1, amount_max = 2 },
		{ itemstring = "mcl_potions:regeneration",      weight = 1, amount_min = 1, amount_max = 1 },
		{ itemstring = "mcl_potions:strength",          weight = 1, amount_min = 1, amount_max = 1 },
	}
}

local function modify_aromr(stack, trim)
	stack = mcl_enchanting.enchant(stack, "protection", 4)
	stack = mcl_enchanting.enchant(stack, "projectile_protection", 4)
	stack = mcl_enchanting.enchant(stack, "fire_protection", 4)
	mcl_armor.trim(stack, trim, ItemStack("mcl_copper:copper_ingot"))
	return stack
end

local possible_mob_gear
local registered_item_spawners = {}

-- this needs to be initialized so late since mcl_enchanting.enchant can only work after all the mods have loaded
core.register_on_mods_loaded(function()
	possible_mob_gear = {
		chestplates = {
			modify_aromr(ItemStack("mcl_armor:chestplate_diamond"), "flow"),
			modify_aromr(ItemStack("mcl_armor:chestplate_iron"),    "flow"),
			modify_aromr(ItemStack("mcl_armor:chestplate_iron"),    "flow"),
			modify_aromr(ItemStack("mcl_armor:chestplate_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:chestplate_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:chestplate_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:chestplate_chain"),   "bolt"),
		},
		helmets = {
			modify_aromr(ItemStack("mcl_armor:helmet_diamond"), "flow"),
			modify_aromr(ItemStack("mcl_armor:helmet_iron"),    "flow"),
			modify_aromr(ItemStack("mcl_armor:helmet_iron"),    "flow"),
			modify_aromr(ItemStack("mcl_armor:helmet_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:helmet_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:helmet_chain"),   "bolt"),
			modify_aromr(ItemStack("mcl_armor:helmet_chain"),   "bolt"),
		},
		ranged_weapons = {
			ItemStack("mcl_bows:bow"),
			ItemStack("mcl_bows:bow"),
			mcl_enchanting.enchant(ItemStack("mcl_bows:bow"), "power", 1),
			mcl_enchanting.enchant(ItemStack("mcl_bows:bow"), "punch", 1)
		},
		melee_weapons = {
			ItemStack("mcl_tools:sword_iron"),
			ItemStack("mcl_tools:sword_iron"),
			ItemStack("mcl_tools:sword_iron"),
			ItemStack("mcl_tools:sword_iron"),
			mcl_enchanting.enchant(ItemStack("mcl_tools:sword_iron"), "sharpness", 1),
			mcl_enchanting.enchant(ItemStack("mcl_tools:sword_iron"), "knockback", 1),
			ItemStack("mcl_tools:sword_diamond"),
		}
	}
end)

-- This is stored here and not in node metadata because it uses object references, which can't be serialized
local trial_spawners_spawned_mobs = {}

-- We use milisecond timestamps because meta:set_int() can't store such big numbers.
-- This level of precision is completely useless to us either way
local function get_milisecond_timestamp()
	return math.floor(core.get_us_time() / 1000)
end

local function spawn_item_spawner_above_object(obj)
	local obj_pos = obj:get_pos()
	local ray_destination = vector.offset(obj_pos, 0, math.random(2, 6), 0)

	local ray = core.raycast(obj_pos, ray_destination, 0, 0)
	local final_pos = ray_destination

	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			final_pos = pointed_thing.above
			break
		end
	end

	local random_item_spawner, random_item_spawner_name = table.random_element(registered_item_spawners)
	local spawned_obj = core.add_entity(
		final_pos,
		"mcl_trial_spawners:ominous_item_spawner",
		core.serialize({
			type = random_item_spawner_name,
			spawn_time = get_milisecond_timestamp() + ((math.random() * 3) + 3) * 1000
		})
	)
	spawned_obj:set_properties({wield_item = random_item_spawner.entity_item})
end

local function spawn_blue_bar_particles(pos)
	core.add_particlespawner({
		texpool = {
			{
				name = "trialspawner_blue_bar_particles.1.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 8,
					aspect_h = 8,
					length = -1
				}
			},
			{
				name = "trialspawner_blue_bar_particles.2.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 8,
					aspect_h = 8,
					length = -1
				}
			},
		},
		vel = {
			min = vector.new(0, 0.1, 0),
			max = vector.new(0, 1.5, 0),
		},
		exptime = {min = 1.1, max = 1.3},
		amount = 50,
		time = 0.1,
		vertical = true,
		glow = 15,
		pos = pos,
		radius = {min = 0.9, max = 1.1, bias = 1}
	})
end

local function spawn_spawning_particles(pos, is_ominous)
	core.add_particlespawner({
		texture = is_ominous and "mcl_particles_soul_fire_flame.png" or "mcl_particles_fire_flame.png",
		exptime = {min = 0.75, max = 1},
		amount = 25,
		time = 0.01,
		vertical = true,
		glow = 15,
		size = {min = 1, max = 2},
		pos = {
			min = vector.offset(pos, -1, -1, -1),
			max = vector.offset(pos, 1, 1, 1),
		},
	})
end

local function transform_to_ominous_spawner(pos, meta)
	spawn_blue_bar_particles(pos)
	core.swap_node(pos, {name = "mcl_trial_spawners:ominous_trialspawner"})
	meta:set_int("last_activation", 0)
	local hash = core.hash_node_position(pos)

	if trial_spawners_spawned_mobs[hash] then
		for _, obj in pairs(trial_spawners_spawned_mobs[hash]) do
			local l = obj:get_luaentity()
			l:safe_remove()
		end
	end
end

local function trial_spawner_in_eye_sight(spawner_pos, destination_pos)
	local ray = core.raycast(spawner_pos, destination_pos, false, false)
	local obstructed = false

	for pointed_thing in ray do
		if pointed_thing.type ~= "node" or not vector.equals(pointed_thing.under, spawner_pos) then
			obstructed = true
			break
		end
	end

	return not obstructed
end

local function trial_spawner_attempt_spawning_mob(pos, meta, is_ominous)
	local hash = core.hash_node_position(pos)

	local spawned_mob
	local frustration = 0
	while frustration < 50 do
		local spawn_attempt_pos = pos + vector.multiply(vector.random_direction(), (math.random() * (spawning_radius - 1) + 1))

		if trial_spawner_in_eye_sight(pos, spawn_attempt_pos) then
			local mob_name = meta:get_string("mob")
			spawned_mob = core.add_entity(spawn_attempt_pos, mob_name)
			local l = spawned_mob:get_luaentity()
			l.persistent = true
			spawn_spawning_particles(pos, is_ominous)
			spawn_spawning_particles(spawned_mob:get_pos(), is_ominous)

			if is_ominous then
				local mobdef = mcl_mobs.registered_mobs[mob_name]

				if mobdef.wears_armor then
					if math.random() > 0.5 then
						l.armor_list.torso = table.random_element(possible_mob_gear.chestplates):get_name()
					end

					if math.random() > 0.5 then
						l.armor_list.head = table.random_element(possible_mob_gear.helmets):get_name()
					end

					if l.can_wield_items then
						if l.attack_type == "melee" then
							l:set_wielditem(ItemStack(table.random_element(possible_mob_gear.melee_weapons):get_name()))
						elseif l.attack_type == "bowshoot" then
							l:set_wielditem(ItemStack(table.random_element(possible_mob_gear.ranged_weapons):get_name()))
						end
					end

					l:set_armor_texture()
				end
			end

			break
		end
	end

	if not spawned_mob then
		return
	end

	if not trial_spawners_spawned_mobs[hash] then
		trial_spawners_spawned_mobs[hash] = {}
	end

	table.insert(trial_spawners_spawned_mobs[hash], spawned_mob)

	meta:set_int("total_mobs_spawned", meta:get_int("total_mobs_spawned") + 1)
	meta:set_int("last_spawn", get_milisecond_timestamp())
end

-- not optimized as it could be, but should be fine since these tables are so short
local function prune_invalid_objrefs(list)
	local i = 1
	while #list >= i do
		if not list[i]:is_valid() then
			table.remove(list, i)
		else
			i = i + 1
		end
	end
end

local function trial_spawner_is_complete(pos, meta, player_count, is_ominous)
	local total_spawn_limit = (player_count - 1) * meta:get_int("total_mobs_added_per_player") + meta:get_int("base_total_mobs")
	local total_mobs_spawned = meta:get_int("total_mobs_spawned")
	local hash = core.hash_node_position(pos)
	local spawned = trial_spawners_spawned_mobs[hash] or {}

	prune_invalid_objrefs(spawned)

	if is_ominous and not mcl_mobs.registered_mobs[meta:get_string("mob")].wears_armor then
		total_spawn_limit = total_spawn_limit * 2
	end

	return total_mobs_spawned >= total_spawn_limit and #spawned == 0
end

local function trial_spawner_can_spawn_mobs(pos, meta, player_count, is_ominous)
	local total_spawn_limit = (player_count - 1) * meta:get_int("total_mobs_added_per_player") + meta:get_int("base_total_mobs")
	local total_mobs_spawned = meta:get_int("total_mobs_spawned")

	if is_ominous and not mcl_mobs.registered_mobs[meta:get_string("mob")].wears_armor then
		total_spawn_limit = total_spawn_limit * 2
	end

	if total_mobs_spawned >= total_spawn_limit then
		return false
	end

	local hash = core.hash_node_position(pos)
	local spawned = trial_spawners_spawned_mobs[hash] or {}
	local simultaneous_mobs_limit = (player_count - 1) * meta:get_int("simultaneous_mobs_added_per_player")
		+ meta:get_int("base_simultaneous_mobs")
		+ (is_ominous and 1 or 0)

	prune_invalid_objrefs(spawned)

	return #spawned < simultaneous_mobs_limit
end

local function on_trial_spawner_complete(pos, meta, is_ominous)
	meta:set_int("last_activation", get_milisecond_timestamp())
	meta:set_int("last_spawn", 0)
	meta:set_int("total_mobs_spawned", 0)
	core.swap_node(pos, {name = "mcl_trial_spawners:trialspawner"})

	local item_count = #core.deserialize(meta:get_string("active_players"))

	local key_drop_chance = is_ominous and 0.3 or 0.5

	local drop_pos = vector.offset(pos, 0, 1, 0)
	if math.random() > key_drop_chance then
		local loot_table = is_ominous and ominous_loot_table or standard_loot_table

		loot_table.stacks_min = item_count
		loot_table.stacks_max = item_count
		local loot = mcl_loot.get_loot(loot_table, PcgRandom(os.time()))

		local function drop_items()
			local stack = loot[#loot]
			loot[#loot] = nil

			core.add_item(drop_pos, stack)

			if #loot > 0 then
				core.after(2, function()
					drop_items()
				end)
			end
		end

		drop_items()
	else
		local function drop_keys(count)
			core.add_item(drop_pos, is_ominous and ItemStack("mcl_vaults:ominous_trial_key") or ItemStack("mcl_vaults:trial_key"))

			if count > 0 then
				core.after(2, function()
					drop_keys(count - 1)
				end)
			end
		end

		drop_keys(item_count - 1)
	end
end

local function trial_spawner_step(pos, meta)
	local last_activation = meta:get_int("last_activation")
	local timestamp = get_milisecond_timestamp()

	local node = core.get_node(pos)
	local is_ominous = node.name == "mcl_trial_spawners:ominous_trialspawner"
	local is_active = node.name ~= "mcl_trial_spawners:trialspawner"
	local last_spawn = meta:get_int("last_spawn")
	local players = core.deserialize(meta:get_string("active_players"))
	local new_players = {}

	for obj in core.objects_inside_radius(pos, activation_radius) do
		if core.is_player(obj)
				and table.indexof(players, obj:get_player_name()) == -1
				-- and not core.is_creative_enabled(obj:get_player_name())
				and trial_spawner_in_eye_sight(pos, vector.offset(obj:get_pos(), 0, 1.5, 0)) then
			table.insert(new_players, obj:get_player_name())
		end
	end

	if #new_players ~= 0 then
		table.insert_all(players, new_players)

		if is_active then
			meta:set_string("active_players", core.serialize(players))
		end
	end

	if not is_ominous then
		local transformed = false
		for _, name in pairs(players) do
			local player = core.get_player_by_name(name)
			local ominous_effect = mcl_potions.get_effect_level(player, "bad_omen") or 0

			if ominous_effect > 0 then
				mcl_potions.give_effect_by_level("trial_omen", player, 1, 60 * 15 * ominous_effect)
				mcl_potions.clear_effect(player, "bad_omen")
			end

			local trial_omen_effect = mcl_potions.get_effect_level(player, "trial_omen") or 0

			if trial_omen_effect > 0 then
				transformed = true
				spawn_blue_bar_particles(vector.offset(player:get_pos(), 0, 1.5, 0))
				transform_to_ominous_spawner(pos, meta)
			end
		end

		if transformed then
			return
		end
	end

	if not is_active and timestamp - last_activation < activation_cooldown then
		return
	end

	if is_active then
		if timestamp - last_spawn >= spawning_interval and trial_spawner_can_spawn_mobs(pos, meta, #players) then
			trial_spawner_attempt_spawning_mob(pos, meta, is_ominous)
		elseif trial_spawner_is_complete(pos, meta, #players, is_ominous) then
			on_trial_spawner_complete(pos, meta, is_ominous)
		elseif is_ominous and timestamp - meta:get_int("last_item_spawner") >= 8000 then
			local spawned = trial_spawners_spawned_mobs[core.hash_node_position(pos)] or {}
			for obj in core.objects_inside_radius(pos, activation_radius) do
				if table.indexof(spawned, obj) ~= -1 or core.is_player(obj) then
					spawn_item_spawner_above_object(obj)
					meta:set_int("last_item_spawner", get_milisecond_timestamp())
					break
				end
			end
		end
	else
		if #players ~= 0 then
			core.add_particlespawner({
				texpool = {
					{
						name = "trialspawner_orange_bar_particles.1.png",
						animation = {
							type = "vertical_frames",
							aspect_w = 8,
							aspect_h = 8,
							length = -1
						}
					},
					{
						name = "trialspawner_orange_bar_particles.2.png",
						animation = {
							type = "vertical_frames",
							aspect_w = 8,
							aspect_h = 8,
							length = -1
						}
					},
				},
				vel = {
					min = vector.new(0, 0.1, 0),
					max = vector.new(0, 1.5, 0),
				},
				exptime = {min = 1.1, max = 1.3},
				amount = 50,
				time = 0.1,
				vertical = true,
				glow = 15,
				pos = pos,
				radius = {min = 0.9, max = 1.1, bias = 1}
			})

			core.swap_node(pos, {name = "mcl_trial_spawners:trialspawner_on"})
		end
	end
end

local tpl = {
	description = S("Trial spawner"),
	_tt_help = S("Spawns mobs when players are nearby"),
	_doc_items_longdesc = S("Spawns mobs when there are players in eyesight, when the player has the ominous trial effect, gets converted to the ominous trial spawner"),
	_doc_items_usagehelp = S("Spawns mobs when there are players in eyesight, when the player has the ominous trial effect, gets converted to the ominous trial spawner"),
	drawtype = "allfaces_optional",
	paramtype2 = "facedir",
	paramtype = "light",
	tiles = {"trialspawner_top.png", "trialspawner_bottom.png", "trialspawner_side.png", "trialspawner_side.png", "trialspawner_side.png", "trialspawner_side.png"},
	groups = {deco_block=1, features_cannot_replace = 1, },
	is_ground_content = false,
	drop = "",
	light_source = 4,
	_mcl_hardness = 50,
	_mcl_blast_resitance = 50,
	on_construct = function(pos)
		local timer = core.get_node_timer (pos)
		timer:start (1)
	end,
	on_timer = function(pos)
		trial_spawner_step(pos, core.get_meta(pos))
		return true
	end,
	after_place_node = function(pos)
		local meta = core.get_meta(pos)

		meta:set_int("last_activation", 0)
		meta:set_int("last_spawn", 0)
		meta:set_int("last_item_spawner", 0)

		meta:set_string("mob", "mobs_mc:zombie")

		meta:set_int("base_total_mobs", 6)
		meta:set_int("total_mobs_added_per_player", 2)

		meta:set_string("active_players", core.serialize({}))

		meta:set_int("base_simultaneous_mobs", 2)
		meta:set_int("simultaneous_mobs_added_per_player", 1)

		meta:set_int("total_mobs_spawned", 0)

		meta:set_float("spawn_interval", 2)
	end,
	on_destruct = function(pos)
		trial_spawners_spawned_mobs[core.hash_node_position(pos)] = nil
	end,
	on_rightclick = function(pos, _, clicker, stack)
		if not clicker:is_player() then return stack end
		if core.get_item_group(stack:get_name(), "spawn_egg") == 0 then return stack end
		if not core.is_creative_enabled(clicker:get_player_name()) then return stack end

		local meta = core.get_meta(pos)
		meta:set_string("mob", stack:get_name())
	end
}

core.register_node("mcl_trial_spawners:trialspawner", tpl)
core.register_node("mcl_trial_spawners:trialspawner_on", table.merge(tpl, {
	tiles = {
		"trialspawner_top_on.png", "trialspawner_bottom_on.png", "trialspawner_side_on.png",
		"trialspawner_side_on.png", "trialspawner_side_on.png", "trialspawner_side_on.png"
	},
	light_source = 8
}))
core.register_node("mcl_trial_spawners:ominous_trialspawner", table.merge(tpl, {
	description = S("Trial spawner"),
	tiles = {
		"trialspawner_top_ominous.png", "trialspawner_bottom_ominous.png", "trialspawner_side_ominous.png",
		"trialspawner_side_ominous.png", "trialspawner_side_ominous.png", "trialspawner_side_ominous.png"
	},
	groups = table.merge(tpl.groups, {not_in_creative_inventory = 1}),
	light_source = 8
}))

local function register_item_spawner(name, def)
	registered_item_spawners[name] = def
end

register_item_spawner("wind charged splash", {
	entity_item = "mcl_potions:wind_charged_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:wind_charged_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("oozing splash", {
	entity_item = "mcl_potions:oozing_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:oozing_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("weaving splash", {
	entity_item = "mcl_potions:weaving_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:weaving_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("infestation splash", {
	entity_item = "mcl_potions:infestation_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:infestation_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("strength splash", {
	entity_item = "mcl_potions:strength_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:strength_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("swiftness splash", {
	entity_item = "mcl_potions:swiftness_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:swiftness_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("slow falling splash", {
	entity_item = "mcl_potions:slow_falling_lingering",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_potions:slow_falling_lingering_flying")
		obj:set_acceleration(vector.new(0, -9.8, 0))
	end
})

register_item_spawner("wind charge", {
	entity_item = "mcl_charges:wind_charge",
	func = function(pos)
		local obj = core.add_entity(pos, "mcl_charges:wind_charge_flying")
		obj:set_velocity(vector.new(0, -15, 0))
	end
})

register_item_spawner("small fire charge", {
	entity_item = "mcl_fire:fire_charge",
	func = function(pos)
		local obj = core.add_entity(pos, "mobs_mc:blaze_fireball")
		local l = obj:get_luaentity()
		l._shot_from_dispenser = true
		l.switch = 1
		obj:set_velocity(vector.new(0, -15, 0))
	end
})

register_item_spawner("arrow", {
	entity_item = "mcl_bows:arrow",
	func = function(pos)
		mcl_bows.shoot_arrow ("mcl_bows:arrow", pos, vector.new(0, -1, 0), 0, "mcl_trial_spawners:ominous_item_spawner", 1)
	end
})

register_item_spawner("slowness arrow", {
	entity_item = "mcl_potions:slowness_arrow",
	func = function(pos)
		local stack = ItemStack("mcl_potions:slowness_arrow")
		local meta = stack:get_meta()
		meta:set_int("mcl_potions:potion_potent", 4)
		mcl_bows.shoot_arrow (stack:get_name(), pos, vector.new(0, -1, 0), 0, "mcl_trial_spawners:ominous_item_spawner", 1)
	end
})

register_item_spawner("poison arrow", {
	entity_item = "mcl_potions:poison_arrow",
	func = function(pos)
		mcl_bows.shoot_arrow ("mcl_potions:poison_arrow", pos, vector.new(0, -1, 0), 0, "mcl_trial_spawners:ominous_item_spawner", 1)
	end
})

core.register_entity("mcl_trial_spawners:ominous_item_spawner", {
	initial_properties = {
		physical = false,
		pointable = false,
		visual = "wielditem",
		visual_size = {x = 0.2, y = 0.2, z = 0.2},
		automatic_rotate = 1,
		static_save = true
	},
	on_activate = function(self, staticdata)
		local data = core.deserialize(staticdata)
		if not data then return end
		self.type = data.type
		self.spawn_time = data.spawn_time
	end,
	get_staticdata = function(self)
		return core.serialize({
			type = self.type,
			spawn_time = self.spawn_time
		})
	end,
	on_step = function(self)
		if get_milisecond_timestamp() < self.spawn_time then return end

		registered_item_spawners[self.type].func(self.object:get_pos())
		self.object:remove()
	end
})

-- particles: mcl_particles_fire_flame.png
-- particles: mcl_particles_soul_fire_flame.png
