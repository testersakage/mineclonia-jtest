mcl_paintings = {}

local modname = core.get_current_modname()
-- dofile(core.get_modpath(modname).."/paintings.lua")

local S = core.get_translator(modname)

-- local wood = "[combine:16x16:-192,0=mcl_paintings_paintings.png"
local wood = "mcl_paintings_frame.png"

-- a painting definition has these fields
-- width         - integer
-- height        - integer
-- texture       - the texture
-- legacy_motive - the old (and extremely stupid) painting identifier, used for backwards compability
local registered_paintings = {}
local maximum_width = 0
local maximum_height = 0
local search_distance = 15

function mcl_paintings.register_painting(name, def)
	def.name = name
	registered_paintings[name] = def
	maximum_width = math.max(maximum_width, def.width)
	maximum_height = math.max(maximum_height, def.height)
end

local function is_node_okay_for_placement(under_node, above_node)
	local under_ndef = core.registered_nodes[under_node.name]
	return above_node.name == "air" and (under_ndef and under_ndef.walkable)
end

local epsilon = 0.001

local function get_biggest_painting_for_position(pos, dir)
	local negative_dir = -dir
	local dir_perpendicular = dir.x ~= 0
		and vector.new(0, 0, dir.x)
		or  vector.new(dir.z, 0, 0)

	-- A table where each element represents the Y level (starting from the bottom).
	-- Where the value is the maximum extend of the width for a painting that wide and that high
	local placement_ranges = {}
	local maximum_so_far = maximum_width

	local neighbouring_painting_positions = {}

	local above_pos = pos + negative_dir
	for obj in core.objects_inside_radius(pos, search_distance) do
		local l = obj:get_luaentity()
		if l and l.name == "mcl_paintings:painting" then
			local pdef = registered_paintings[l._painting_name]
			local obj_pos = obj:get_pos()
			core.debug("lok", obj_pos, l, l and l.name, pdef.width, pdef.height)
			local painting_dir = core.wallmounted_to_dir(l._facing) -- for whatever reason, the wallmounted value is actually reversed...
			local start_position = vector.round(vector.offset(obj_pos, dir_perpendicular.x * pdef.width / 2, -pdef.height / 2, dir_perpendicular.z * pdef.width / 2))
			core.debug(start_position, dir_perpendicular.x * pdef.width / 2, dir_perpendicular.z * pdef.width / 2, painting_dir)
			for y = 0, pdef.height - 1 do
				for i = 0, pdef.width - 1 do
					core.debug("AX", y, i, vector.offset(start_position, -i * dir_perpendicular.x, y, -i * dir_perpendicular.z))
					neighbouring_painting_positions[core.hash_node_position(vector.offset(start_position, -i * dir_perpendicular.x, y, -i * dir_perpendicular.z))] = true
				end
			end
			-- for y = (-pdef.height / 2) + epsilon, (pdef.height / 2) - epsilon do
			-- 	for i = -(pdef.width / 2) + epsilon, (pdef.width / 2) - epsilon do
			-- 		core.debug("AX", y, i, vector.offset(obj_pos, -i * dir_perpendicular.x, y, -i * dir_perpendicular.z), obj_pos.y + y)
			-- 		neighbouring_painting_positions[core.hash_node_position(vector.round(vector.offset(obj_pos, -i * dir_perpendicular.x, y, -i * dir_perpendicular.z)))] = true
			-- 	end
			-- end
		end
	end

	core.debug(dump(neighbouring_painting_positions))

	for y = 0, maximum_height do
		local i = 0
		while i < maximum_so_far do
			local offset_pos = vector.offset(pos, -i * dir_perpendicular.x, y, -i * dir_perpendicular.z)
			local offset_above_pos = offset_pos + dir
			local node_under = core.get_node(offset_pos)
			local node_above = core.get_node(offset_above_pos)

			core.debug(y, i, offset_above_pos, core.hash_node_position(offset_above_pos))
			if is_node_okay_for_placement(node_under, node_above) and not neighbouring_painting_positions[core.hash_node_position(offset_above_pos)] then
				i = i + 1
			else
				break
			end
		end

		maximum_so_far = math.min(i, maximum_so_far)
		table.insert(placement_ranges, maximum_so_far)
	end

	local maximum_volume = -1
	local canditates = {}

	for _, pdef in pairs(registered_paintings) do
		if pdef.width <= placement_ranges[pdef.height] then
			local painting_volume = pdef.width * pdef.height
			if maximum_volume < painting_volume then
					-- or (maximum_volume == painting_volume and math.random() > 0.5) then
				canditates = {pdef}
				maximum_volume = painting_volume
				-- maximum_volume_name = name
			elseif maximum_volume == painting_volume then
				table.insert(canditates, pdef)
			end
		end
	end

	if #canditates == 0 then
		-- This should never happen, since we have 1x1 paintings. But it doesn't hurt to have extra protection
		error("No possible painting canditate found")
	end

	local random_pick = canditates[math.random(1, #canditates)]

	return random_pick
end

core.register_craftitem("mcl_paintings:painting", {
	description = S("Painting"),
	inventory_image = "mcl_paintings_painting.png",
	groups = {deco_block = 1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		local dir = vector.subtract(pointed_thing.above, pointed_thing.under)

		if dir.y ~= 0 then
			return itemstack
		end

		local pdef = get_biggest_painting_for_position(pointed_thing.under, dir)
		local wallm = core.dir_to_wallmounted(dir)

		if not wallm then return itemstack end

		local staticdata = {
			_facing = wallm,
			_painting_name = pdef.name
		}

		local obj = core.add_entity(
			vector.subtract(pointed_thing.above, vector.multiply(dir, 0.5-5/256)) + vector.new(-dir.z * (pdef.width / 2 - 0.5), pdef.height / 2 - 0.5, -dir.x * (pdef.width / 2 - 0.5)),
			"mcl_paintings:painting",
			core.serialize(staticdata)
		)

		if not obj then return itemstack end

		if not core.is_creative_enabled(placer:get_player_name()) then
			itemstack:take_item()
		end
		return itemstack
	end,
})

local function size_to_minmax_entity(size)
	return -size/2, size/2
end

local function set_entity(object, pdef)

	if not pdef then
		-- error("Invalid painting")
		core.log("error", "[mcl_paintings] Painting loaded with missing painting values!")
	end

	core.debug("aa", dump(pdef))

	local ent = object:get_luaentity()
	local wallm = ent._facing
	local exmin, exmax = size_to_minmax_entity(pdef.width)
	local eymin, eymax = size_to_minmax_entity(pdef.height)
	local visual_size = { x=pdef.width-0.0001, y=pdef.height-0.0001, z=1/32 }

	if not ent._xsize or not ent._ysize or not ent._motive then
		core.log("error", "[mcl_paintings] Painting loaded with missing painting values!")
		return
	end

	local box
	if wallm == 2 then
		box = { -3/128, eymin, exmin, 1/64, eymax, exmax }
	elseif wallm == 3 then
		box = { -1/64, eymin, exmin, 3/128, eymax, exmax }
	elseif wallm == 4 then
		box = { exmin, eymin, -3/128, exmax, eymax, 1/64 }
	elseif wallm == 5 then
		box = { exmin, eymin, -1/64, exmax, eymax, 3/128 }
	end
	object:set_properties({
		selectionbox = box,
		visual_size = visual_size,
		textures = { wood, wood, wood, wood, pdef.texture, wood },
	})

	local dir = core.wallmounted_to_dir(wallm)
	if not dir then
		return
	end
	object:set_yaw(core.dir_to_yaw(dir))
end

core.register_entity("mcl_paintings:painting", {
	initial_properties = {
		visual = "cube",
		visual_size = { x=0.999, y=0.999, z=1/32 },
		selectionbox = { -1/64, -0.5, -0.5, 1/64, 0.5, 0.5 },
		physical = false,
		collide_with_objects = false,
		textures = { wood, wood, wood, wood, wood, wood },
		hp_max = 1,
	},

	_mcl_pistons_unmovable = true,
	_motive = 0,
	_pos = nil,
	_facing = 2,
	_xsize = 1,
	_ysize = 1,
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal = 1})
		if staticdata and staticdata ~= "" then
			local data = core.deserialize(staticdata)
			if data then
				self._facing = data._facing
				self._painting_name = data._painting_name
				-- _xsize = xsize,
				-- _ysize = ysize,

				-- Putting the old mcl_painting crap to grave
				if data._motive then
					local successfully_converted = false
					for pname, pdef in pairs(registered_paintings) do
						-- core.debug("loopy", pname, data._motive, data._ysize, data._xsize)
						if pdef.legacy_motive
								-- and pdef.legacy_motive.cx == self._motive.cx
								-- and pdef.legacy_motive.cy == self._motive.cy then
								and pdef.height == data._ysize
								and pdef.width == data._xsize
								and pdef.legacy_motive == data._motive then

							-- core.debug("here", dump(pdef))
							successfully_converted = true
							self._painting_name = pname
							break
							-- yummy nesting
						end
					end

					if not successfully_converted then
						self.object:remove()
						core.log("error", "Could not migrate painting to the new system")
					end
				end
			end
		end
		-- core.debug("moo", dump(self._painting_name))
		set_entity(self.object, registered_paintings[self._painting_name])
	end,
	get_staticdata = function(self)
		local data = {
			_facing = self._facing,
			_painting_name = self._painting_name
		}
		return core.serialize(data)
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage) ---@diagnostic disable-line: unused-local
		if puncher and puncher:is_player() then
			local kname = puncher:get_player_name()
			local pos = self._pos
			if not pos then
				pos = self.object:get_pos()
			end
			if not mcl_util.check_position_protection(pos, puncher) then
				self.object:remove()
				if not core.is_creative_enabled(kname) then
					core.add_item(pos, "mcl_paintings:painting")
				end
			end
		end
	end,
})

mcl_paintings.register_painting("ancient octupus", {
	texture = "ancient_octupus.png",
	width = 1,
	height = 1,
	legacy_motive = 0,
})

mcl_paintings.register_painting("snowy mountain", {
	texture = "snowy_mountain.png",
	width = 1,
	height = 1,
	legacy_motive = 1,
})

mcl_paintings.register_painting("balding man", {
	texture = "balding_man.png",
	width = 1,
	height = 1,
	legacy_motive = 2,
})

mcl_paintings.register_painting("poster", {
	texture = "poster.png",
	width = 1,
	height = 1,
	legacy_motive = 3,
})

mcl_paintings.register_painting("notes", {
	texture = "notes.png",
	width = 1,
	height = 1,
	legacy_motive = 4,
})

mcl_paintings.register_painting("viking shield", {
	texture = "viking_shield.png",
	width = 1,
	height = 1,
	legacy_motive = 5,
})

mcl_paintings.register_painting("butcher knifes", {
	texture = "butcher_knifes.png",
	width = 1,
	height = 1,
	legacy_motive = 6,
})

mcl_paintings.register_painting("green bottles", {
	texture = "green_bottles.png",
	width = 2,
	height = 1,
	legacy_motive = 0,
})

mcl_paintings.register_painting("battle axe", {
	texture = "battle_axe.png",
	width = 2,
	height = 1,
	legacy_motive = 1,
})

mcl_paintings.register_painting("cooking utencils", {
	texture = "cooking_utencils.png",
	width = 2,
	height = 1,
	legacy_motive = 2,
})

mcl_paintings.register_painting("dense jungle forest", {
	texture = "dense_jungle_forest.png",
	width = 2,
	height = 1,
	legacy_motive = 3,
})

mcl_paintings.register_painting("endless dunes", {
	texture = "endless_dunes.png",
	width = 2,
	height = 1,
	legacy_motive = 4,
})

mcl_paintings.register_painting("green banner", {
	texture = "green_banner.png",
	width = 1,
	height = 2,
	legacy_motive = 0,
})

mcl_paintings.register_painting("blue banner", {
	texture = "blue_banner.png",
	width = 1,
	height = 2,
	legacy_motive = 1,
})

mcl_paintings.register_painting("quest board", {
	texture = "quest_board.png",
	width = 4,
	height = 2,
	legacy_motive = 0,
})

mcl_paintings.register_painting("support truss", {
	texture = "support_truss.png",
	width = 2,
	height = 2,
	legacy_motive = 0,
})

mcl_paintings.register_painting("froggy pond", {
	texture = "froggy_pond.png",
	width = 2,
	height = 2,
	legacy_motive = 1,
})

mcl_paintings.register_painting("moonshine thundra", {
	texture = "moonshine_thundra.png",
	width = 2,
	height = 2,
	legacy_motive = 2,
})

mcl_paintings.register_painting("desert castle", {
	texture = "desert_castle.png",
	width = 2,
	height = 2,
	legacy_motive = 3,
})

mcl_paintings.register_painting("sarmatian decoration", {
	texture = "sarmatian_decoration.png",
	width = 2,
	height = 2,
	legacy_motive = 4,
})

mcl_paintings.register_painting("decorative swords", {
	texture = "decorative_swords.png",
	width = 2,
	height = 2,
	legacy_motive = 5,
})

mcl_paintings.register_painting("gloom gloom mountain", {
	texture = "gloom_mountain.png",
	width = 4,
	height = 3,
	legacy_motive = 0,
})

mcl_paintings.register_painting("elf utopia", {
	texture = "elf_utopia.png",
	width = 4,
	height = 3,
	legacy_motive = 1,
})

mcl_paintings.register_painting("waterfall bridge", {
	texture = "waterfall_bridge.png",
	width = 4,
	height = 4,
	legacy_motive = 0,
})

mcl_paintings.register_painting("mountain tower", {
	texture = "mountain_tower.png",
	width = 4,
	height = 4,
	legacy_motive = 1,
})

mcl_paintings.register_painting("child's first drawing", {
	texture = "childs_first_drawing.png",
	width = 4,
	height = 4,
	legacy_motive = 2,
})

core.register_craft({
	output = "mcl_paintings:painting",
	recipe = {
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
		{ "mcl_core:stick", "group:wool", "mcl_core:stick" },
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
	}
})

