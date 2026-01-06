local S = core.get_translator(core.get_current_modname())

mcl_bells = {}

function mcl_bells.ring_once(pos)
	local alarm_time = core.get_gametime ()

	core.sound_play( "mcl_bells_bell_stroke", {
		pos = pos, gain = 1.5, max_hear_distance = 150,})
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
	-math.pi/2, -- x-
	math.pi/2,  -- x+
	0,          -- z+
	math.pi,    -- z-
}

local function create_entity(pos, node)
	local param2 = node.param2
	local rot = {x = 0, y = bell_rotations[param2 + 1], z = 0}

	local static_data = {_node = node}
	if node.name == "mcl_bells:bell_floor" then
		static_data._mesh = "mcl_bells_bell_floor.b3d"
		rot.y = bell_rotations[param2 + 2]
	elseif node.name == "mcl_bells:bell_ceiling" then
		static_data._mesh = "mcl_bells_bell_ceiling.b3d"
		rot.z = math.pi
	else
		static_data._mesh = "mcl_bells_bell_wall.b3d"
		rot.x = math.pi/2
	end

	local obj = core.add_entity(pos, "mcl_bells:bell_ent",
														core.serialize(static_data))
	if obj and obj:get_pos() then
		obj:set_rotation(rot)
		return obj:get_luaentity()
	else
		core.log("warning", "[mcl_bells] Failed to create entity at "
								.. (pos and core.pos_to_string(pos, 1) or "nil"))
	end
end

local bell_def = {
	description = S("Bell"),
	paramtype = "light",
	paramtype2 = "wallmounted",
	inventory_image = "mcl_bells_bell.png",
	drawtype = "mesh",
	walkable = true,
	pointable = true,
	tiles = {"mcl_bells_bell_uv.png"},
	wield_image = "mcl_bells_bell.png",
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
		local ent = create_entity(pos, node)
		if ent then ent:ring() end
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
			fakestack:set_name("mcl_bells:bell_floor")
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
				local ent = create_entity(pos, node)
				if ent then ent:ring() end
			end

			core.swap_node(pos, {name = node.name,
							param2 = param2 + (powered and 1 or 0)})
		end
	},
}

core.register_node("mcl_bells:bell", bell_def)

core.register_node("mcl_bells:bell_floor", table.merge(bell_def, {
	paramtype2 = "facedir",
	mesh = "mcl_bells_bell_floor.b3d",
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 1,
		attached_node = 1
	}),
	selection_box = {
    type = "fixed",
    fixed = {
      {-0.3125, -0.3725, -0.3125, 0.3125, 0.3125, 0.3125},
    },
  },
}))
core.register_node("mcl_bells:bell_ceiling", table.merge(bell_def, {
	mesh = "mcl_bells_bell_ceiling.b3d",
	tiles = {"mcl_bells_bell_uv.png^[colorize:#000000:15"},
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 1,
		supported_node_wallmounted = 1,
	}),
	selection_box = {
    type = "fixed",
    fixed = {
      {-0.3125, -0.3525, -0.3125, 0.3125, 0.3425, 0.3125},
    },
  },
}))
core.register_node("mcl_bells:bell_wall", table.merge(bell_def, {
	mesh = "mcl_bells_bell_wall.b3d",
	groups = table.merge(bell_def.groups, {
		not_in_creative_inventory = 1,
		supported_node_wallmounted = 1,
	}),
	selection_box = {
    type = "fixed",
    fixed = {
      {-0.3125, -0.3125, -0.5, 0.3125, 0.3125, 0.2},
    },
  },
}))

core.register_entity("mcl_bells:bell_ent", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_bells_bell_floor.b3d",
		textures = {"mcl_bells_bell_uv.png"},
		physical = true,
		collisionbox = {-0.3125, -0.5, -0.3125, 0.3125, 0.5, 0.3125},
		collide_with_objects = true,
		static_save = false
	},
	on_activate = function(self, staticdata)
		self._generation = 0
		if staticdata and staticdata ~= "" then
			local data = core.deserialize(staticdata)
			if data then
				self._node = data._node
				self._mesh = data._mesh
			end
		end
		self.object:set_properties({ mesh = self._mesh })
		self.object:set_armor_groups({ immortal = 1 })
	end,
	on_deactivate = function (self)
		local pos = self.object:get_pos()
		if self._node then
			core.add_node(pos, self._node)
		end
	end,
	on_rightclick = function (self)
		self:ring()
	end,
	ring = function (self)
		-- Allow entity to be rightclicked repetitively
		-- by only remove latest version of generation
		self._generation = (self._generation or 0) + 1
		local gen = self._generation

		local anim = {x = 1, y = 195}
		local duration = 0.8
		local fps = (anim.y - anim.x) / duration
		self.object:set_animation(anim, fps, 0.0, false)

		local pos = self.object:get_pos()
		mcl_bells.ring_once(pos)

		core.remove_node(pos)
		core.after(duration, function ()
			if not self.object then return end
			if (self._generation or 0) ~= gen then return end
			core.add_node(pos, self._node)
			core.after(0, function ()
				self.object:remove()
			end)
		end)
	end,
})
