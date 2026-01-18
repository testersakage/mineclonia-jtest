local S = core.get_translator(core.get_current_modname())

mcl_bells = {}

local SOUND_PARMS = {
	gain = 1.5,
	max_hear_distance = 150,
}

function mcl_bells.ring_internal (pos)
	local alarm_time = core.get_gametime ()

	SOUND_PARMS.pos = pos
	core.sound_play ("mcl_bells_bell_stroke", SOUND_PARMS)
	for o in core.objects_inside_radius(pos, 32) do
		local entity = o:get_luaentity()
		if entity and entity.name == "mobs_mc:villager" then
			entity._last_alarm_gmt = alarm_time
		end

		if entity and entity.is_mob and entity.raidmob then
			local distance = vector.distance (o:get_pos (), pos)
			if distance <= 48 then
				mcl_potions.give_effect ("glowing", o, o, 1, 3)
			end
		end
	end
end

local find_or_create_entity

function mcl_bells.ring_once (pos, node)
	local node = node or core.get_node (pos)
	local entity = find_or_create_entity (pos, node)
	mcl_bells.ring_internal (pos)
	if entity then
		entity:ring ()
	end
end

local bell_rotations = {
	0,          -- ceiling
	0,          -- floor
	-math.pi/2, -- x-
	math.pi/2,  -- x+
	0,          -- z+
	math.pi,    -- z-
}

local bell_entities = {}

local function create_entity (pos, node)
	local param2 = node.param2
	local rot = {x = 0, y = bell_rotations[param2 + 1], z = 0}
	local mesh

	if node.name == "mcl_bells:bell" then
		mesh = "mcl_bells_bell_floor.b3d"
		rot.y = bell_rotations[param2 + 2]
	elseif node.name == "mcl_bells:bell_ceiling" then
		mesh = "mcl_bells_bell_ceiling.b3d"
		rot.z = math.pi
	else
		mesh = "mcl_bells_bell_wall.b3d"
		rot.x = math.pi/2
	end

	local obj = core.add_entity (pos, "mcl_bells:bell_ent")
	if obj then
		obj:set_rotation (rot)
		obj:set_properties ({
			mesh = mesh,
		})
		obj:set_animation ({ x = 195, y = 195, })
		local entity = obj:get_luaentity()
		local hash = core.hash_node_position (pos)
		entity._node_pos = hash
		bell_entities[hash] = entity
		return entity
	else
		core.log("warning", ("[mcl_bells] Failed to create entity at "
				     .. (pos and core.pos_to_string(pos, 1) or "nil")))
	end
	return nil
end

function find_or_create_entity (pos, node)
	local hash = core.hash_node_position (pos)
	return bell_entities[hash] or create_entity (pos, node)
end

local bell_def = {
	description = S("Bell"),
	paramtype = "light",
	paramtype2 = "wallmounted",
	inventory_image = "mcl_bells_bell.png",
	drawtype = "mesh",
	walkable = true,
	pointable = true,
	tiles = {"mcl_bells_bell_uv_frame.png"},
	use_texture_alpha = "clip",
	wield_image = "mcl_bells_bell.png",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.3125, -0.5, -0.3125, 0.3125, 0.5, 0.3125},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.3125, -0.5, -0.3125, 0.3125, 0.5, 0.3125},
		},
	},
	is_ground_content = true,
	groups = {
		bell = 1,
		dig_by_piston = 1,
		pickaxey = 2,
		deco_block = 1,
		pathfinder_partial = 2,
	},
	sunlight_propagates = true,
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_hardness = 5,
	on_rightclick = function (pos, node)
		mcl_bells.ring_once (pos, node)
	end,
	on_place = function (itemstack, placer, pointed_thing)
		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		local under = pointed_thing.under
		local above = pointed_thing.above
		local wdir = core.dir_to_wallmounted(vector.subtract(under, above))

		local fakestack = ItemStack(itemstack)
		if wdir == 0 then
			fakestack:set_name("mcl_bells:bell_ceiling")
		elseif wdir == 1 then
			fakestack:set_name("mcl_bells:bell")
			local d = placer:get_look_dir()
			wdir = (math.abs(d.x) > math.abs(d.z)) and 0 or 1
		else
			fakestack:set_name("mcl_bells:bell_wall")
		end

		local leftover = core.item_place_node(fakestack, placer, pointed_thing, wdir)
		itemstack:set_count(leftover:get_count())
		itemstack:set_name("mcl_bells:bell")

		return itemstack
	end,
	on_construct = function (pos)
		local node = core.get_node (pos)
		find_or_create_entity (pos, node)
	end,
	_on_arrow_hit = function (pos)
		mcl_bells.ring_once (pos, nil)
	end,
	_mcl_redstone = {
		connects_to = function(node, dir)
			return true
		end,
		update = function(pos, node)
			mcl_bells.ring_once (pos, node)
		end,
		init = function() end,
	},
}

core.register_alias ("mcl_bells:bell_floor", "mcl_bells:bell")

core.register_node("mcl_bells:bell", table.merge(bell_def, {
	paramtype2 = "facedir",
	mesh = "mcl_bells_bell_floor.b3d", 
	drop = "mcl_bells:bell",
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 0,
		attached_node = 1
	}),
}))
core.register_node("mcl_bells:bell_ceiling", table.merge(bell_def, {
	mesh = "mcl_bells_bell_ceiling.b3d", 
	drop = "mcl_bells:bell",
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 1,
		supported_node_wallmounted = 1,
	}),
}))
core.register_node("mcl_bells:bell_wall", table.merge(bell_def, {
	mesh = "mcl_bells_bell_wall.b3d", 
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 1,
		supported_node_wallmounted = 1,
	}),
	drop = "mcl_bells:bell",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.3125, -0.3125, -0.5, 0.3125, 0.3125, 0.5},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.3125, -0.3125, -0.5, 0.3125, 0.3125, 0.5},
		},
	},
}))

local function unhash (hash)
	local x = (hash % 65536) - 32768
	hash  = math.floor (hash / 65536)
	local y = (hash % 65536) - 32768
	hash  = math.floor (hash / 65536)
	local z = (hash % 65536) - 32768
	return x, y, z
end

local cid_bell_floor
	= core.get_content_id ("mcl_bells:bell")
local cid_bell_wall
	= core.get_content_id ("mcl_bells:bell_wall")
local cid_bell_ceiling
	= core.get_content_id ("mcl_bells:bell_ceiling")

core.register_entity("mcl_bells:bell_ent", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_bells_bell_floor.b3d",
		textures = {"mcl_bells_bell_uv_bell.png"},
		physical = false,
		collisionbox = {
			0, 0, 0, 0, 0, 0,
		},
		selectionbox = {
			0, 0, 0, 0, 0, 0,
		},
		static_save = false,
	},
	on_deactivate = function (self)
		local hash = self._node_pos
		if bell_entities[hash] == self then
			bell_entities[hash] = nil
		end
	end,
	ring = function (self)
		local anim = {x = 1, y = 195}
		local duration = 0.8
		local fps = (anim.y - anim.x) / duration
		self.object:set_animation (anim, fps, 0.0, false)
	end,
	on_step = function (self, _)
		if self._node_pos then
			local x, y, z = unhash (self._node_pos)
			local cid, _, _ = core.get_node_raw (x, y, z)
			if cid ~= cid_bell_floor
				and cid ~= cid_bell_ceiling
				and cid ~= cid_bell_wall then
				self.object:remove ()
				return
			end
		end
	end,
})

core.register_lbm ({
	label = "Spawn Bell Entity",
	name = "mcl_bells:spawn_bell_entity",
	nodenames = { "group:bell" },
	run_at_every_load = true,
	action = function (pos, node, _)
		find_or_create_entity (pos, node)
	end,
})
