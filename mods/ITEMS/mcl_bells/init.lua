local S = core.get_translator(core.get_current_modname())

mcl_bells = {}

function mcl_bells.ring_once(pos)
	local alarm_time = core.get_gametime ()

	core.sound_play( "mcl_bells_bell_stroke", { pos = pos, gain = 1.5, max_hear_distance = 150,})
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

local bell_rotations = {
	0,          -- ceiling
	0,          -- floor
	math.pi/2,  -- x+
	-math.pi/2, -- x-
	math.pi,    -- z-
	0,          -- z+
}

local function create_entity(pos)
	local node = core.get_node(pos)
	local node_name = node.name
	local node_def = core.registered_nodes[node_name]
	local param2 = node.param2 % 8 -- get first 3 bits

	local static_data = {
		param2 = param2,
		_mesh = node_def._ceiling_mesh,
		_textures = node_def._ceiling_textures
	}

	if param2 == 1 then
		static_data._mesh = node_def._ground_mesh
		static_data._textures = node_def._ground_textures
	elseif param2 > 1 then
		static_data._mesh = node_def._wall_mesh
		static_data._textures = node_def._wall_textures
	end

	local obj = core.add_entity(pos, "mcl_bells:bell_ent",
		                        core.serialize(static_data))
	if obj and obj:get_pos() then
		local rot = {x = 0, y = bell_rotations[param2 + 1], z = 0}
		obj:set_rotation(rot)
	else
		core.log("warning", "[mcl_bells] Failed to create entity at " ..
		             (pos and core.pos_to_string(pos, 1) or "nil"))
	end
end

local function find_entity(pos)
	for obj in core.objects_inside_radius(pos, 0) do
		local luaentity = obj:get_luaentity()
		if luaentity and luaentity.name == "mcl_bells:bell_ent" then
		    return luaentity
		end
	end
end

function mcl_bells.remove_ent(pos)
	local ent = find_entity(pos)
	if ent then
		ent.object:remove()
	end
end

function mcl_bells.find_or_create_entity(pos)
	return find_entity(pos) or create_entity(pos)
end

core.register_node("mcl_bells:bell", {
	description = S("Bell"),
	paramtype = "light",
	inventory_image = "mcl_bells_bell.png",
	paramtype2 = "wallmounted",
	drawtype = "airlike",
	walkable = false,
	pointable = false,
	tiles = {"blank.png"},
	wield_image = "mcl_bells_bell.png",
	is_ground_content = false,
	groups = {
		bell = 1,
		attached_node_wallmounted = 1,
		dig_by_piston = 1,
	},
	sunlight_propagates = true,
	sounds = mcl_sounds.node_sound_metal_defaults(),
	on_rightclick = mcl_bells.ring_once,
	_mcl_redstone = {
		connects_to = function(node, dir)
			return true
		end,
		update = function(pos, node)
			local param2 = node.param2 % 8 -- get first 3 bits
			local other = node.param2 - param2

		    local oldpowered = other ~= 0
		    local powered = mcl_redstone.get_power(pos) ~= 0

		    if powered and not oldpowered then
				local ent = find_entity(pos)
				if ent then
				    mcl_bells.ring_once(pos)
					ent.object:set_animation({x = 0, y = 155}, 20, 0.0, false)
				end
		    end

		    core.swap_node(pos, {name = node.name, param2 = param2 + (powered and 1 or 0)})
		end
	},

	_ceiling_mesh = "mcl_bells_bell_ceiling.gltf",
	_ceiling_textures = {"mcl_bells_bell_uv.png"},
	_ground_mesh = "mcl_bells_bell_ground.gltf",
	_ground_textures = {"mcl_bells_bell_uv.png"},
	_wall_mesh = "mcl_bells_bell_wall.gltf",
	_wall_textures = {"mcl_bells_bell_uv.png"},

	on_construct = function(pos) mcl_bells.find_or_create_entity(pos) end,
	on_destruct = function(pos) mcl_bells.remove_ent(pos) end,
})

core.register_entity("mcl_bells:bell_ent", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_bells_bell_ceiling.gltf",
		textures = {"mcl_bells_bell_uv.png"},
		hp_max = 20,
		physical = true,
		collisionbox = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
		collide_with_objects = true
	},
	_mesh = "bell.gltf",
	_textures = {"bell_uv.png"},
	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
		    local data = core.deserialize(staticdata)
		    if data then
		        self._mesh = data._mesh
		        self._textures = data._textures
		    end
		end
		self.object:set_properties({
		    mesh = self._mesh,
		    textures = self._textures
		})
	end,
	get_staticdata = function(self)
		local data = {_textures = self._textures, _mesh = self._mesh}
		return core.serialize(data)
	end,
	on_punch = function(self, puncher)
		mcl_bells.ring_once(self.object:get_pos())
		self.object:set_animation({x = 0, y = 155}, 20, 0.0, false)

		-- BUGBUG need to handle digging?
		-- To do no damage do this ...
		-- return true
	end,
	on_death = function(self, removal)
		if removal then core.dig_node(self.object:get_pos()) end
	end
})

core.register_lbm({
	label = "Spawn Bell Entity",
	name = "mcl_bells:spawn_bell_entity",
	nodenames = {"group:bell"},
	run_at_every_load = true,
	action = mcl_bells.find_or_create_entity
})
