mcl_paintings = {
	registered_paintings = {},
}
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local wood = "mcl_paintings_wood.png"

function mcl_paintings.register_painting(def)
	assert(def.file or def.name, "[mcl_painting] attempting to register painting without file or name provided")
	assert(def.name, "[mcl_paintings] attempting to register painting without name")
	if not def.file then
		def.file = "mcl_paintings_"..def.name..".png"
	end
	table.insert(mcl_paintings.registered_paintings, def)
end

function mcl_paintings.get_painting(name)
	for _, v in pairs(mcl_paintings.registered_paintings) do
		if v.name == name or v.file == name then return v end
	end
end

local function get_random_painting(x, y)
	table.shuffle(mcl_paintings.registered_paintings)
	for _, v in pairs(mcl_paintings.registered_paintings) do
		if v.width <= x and v.height <= y then return v end
	end
end

local painting_entity = {
	initial_properties = {
		visual = "cube",
		visual_size = { x=0.999, y=0.999, z=1/32 },
		selectionbox = { -1/64, -0.5, -0.5, 1/64, 0.5, 0.5 },
		physical = false,
		collide_with_objects = false,
		textures = { wood, wood, wood, wood, wood, wood },
		hp_max = 1,
	},

	_motive = nil,
	_pos = nil,
	_facing = 2,
	_xsize = 1,
	_ysize = 1,
}

local function convert_old_motive(self, data)
	if tonumber(data._motive) then
		for _, v in pairs(mcl_paintings.registered_paintings) do
			if v.width == self._xsize and v.height == self._ysize and v.oldid == data._motive then
				local dir = self._facing
				if type(dir) == "table" then
					self._yaw = minetest.wallmounted_to_dir(minetest.dir_to_yaw(dir))
					return v.file
				end
			end
		end
		return false
	end
	return data._motive
end

function painting_entity:on_activate(staticdata)
	self.object:set_armor_groups({immortal = 1})
	if staticdata and staticdata ~= "" then
		local data = minetest.deserialize(staticdata)
		if data then
			self._yaw = data._yaw
			self._pos = data._pos
			self._xsize = data._xsize
			self._ysize = data._ysize
			self._motive = convert_old_motive(self, data)
			local def = mcl_paintings.get_painting(self._motive)
			if not self._motive or not def or def.remove then
				self.object:remove()
				return
			end
		end
	end
	self:set_motive()
end

function painting_entity:get_staticdata()
	local data = {
		_yaw = self._yaw,
		_pos = self._pos,
		_motive = self._motive,
		_xsize = self._xsize,
		_ysize = self._ysize,
	}
	return minetest.serialize(data)
end

function painting_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)
	if puncher and puncher:is_player() then
		local creative = minetest.is_creative_enabled(puncher:get_player_name())
		local pos = self._pos
		if not pos then
			pos = self.object:get_pos()
		end
		if not mcl_util.check_position_protection(pos, puncher) then
			-- Slightly delay removing the painting so nodes behind it won't be dug (particularly in creative mode)
			minetest.after(0.15, function(object)
				if object and object:get_pos() then
					object:remove()
				end
				if not creative then minetest.add_item(pos, "mcl_paintings:painting") end
			end, self.object)
		end
	end
end

local function size_to_minmax_entity(size)
	return -size/2, size/2
end

function painting_entity:set_motive()
	local box
	local exmin, exmax = size_to_minmax_entity(self._xsize)
	local eymin, eymax = size_to_minmax_entity(self._ysize)
	if self._yaw then
		local wallm = minetest.dir_to_wallmounted(minetest.yaw_to_dir(self._yaw))
		if wallm == 2 then
			box = { -3/128, eymin, exmin, 1/64, eymax, exmax }
		elseif wallm == 3 then
			box = { -1/64, eymin, exmin, 3/128, eymax, exmax }
		elseif wallm == 4 then
			box = { exmin, eymin, -3/128, exmax, eymax, 1/64 }
		elseif wallm == 5 then
			box = { exmin, eymin, -1/64, exmax, eymax, 3/128 }
		end
	end
	self.object:set_properties({
		selectionbox = box,
		visual_size = vector.new(self._xsize, self._ysize, 1/32 ),
		textures = { wood, wood, wood, wood, self._motive, wood },
	})
	self.object:set_rotation(vector.new(0, self._yaw or 0, 0))
end

minetest.register_entity("mcl_paintings:painting", painting_entity)

local function get_maxes(pointed_thing)
	local xmax
	local ymax = 4
	local xmaxes = {}
	local ymaxed = false
	local dir = vector.direction(pointed_thing.under, pointed_thing.above)
	local negative = dir.x < 0 or dir.z > 0
	-- Check maximum possible painting size
	local t
	for y=0,3 do
	for x=0,3 do
		local k = x
		if negative then
			k = -k
		end
		if dir.z ~= 0 then
			t = {x=k,y=y,z=0}
		else
			t = {x=0,y=y,z=k}
		end
		local unode = minetest.get_node(vector.add(pointed_thing.under, t))
		local anode = minetest.get_node(vector.add(pointed_thing.above, t))
		local udef = minetest.registered_nodes[unode.name]
		local adef = minetest.registered_nodes[anode.name]
		if (not (udef and udef.walkable)) or (not adef or adef.walkable) then
			xmaxes[y+1] = x
			if x == 0 and not ymaxed then
				ymax = y
				ymaxed = true
			end
			break
		end
	end
	if not xmaxes[y] then
		xmaxes[y] = 4
	end
	end
	xmax = math.max(unpack(xmaxes))
	return xmax, ymax
end

function mcl_paintings.spawn_painting(pointed_thing, def)
	if not def then return end -- prevent crash
	local dir = vector.direction(pointed_thing.under, pointed_thing.above)
	local x, y, m = def.width, def.height, def.file
	if x and y and m then
		local negative = dir.x < 0 or dir.z > 0
		local _, exmax = size_to_minmax_entity(x)
		local _, eymax = size_to_minmax_entity(y)
		local pexmax
		local peymax = eymax - 0.5
		if negative then
			pexmax = -exmax + 0.5
		else
			pexmax = exmax - 0.5
		end
		local pposa = vector.subtract(pointed_thing.above, vector.multiply(dir, 0.5-5/256))
		if dir.z ~= 0 then
			pposa = vector.add(pposa, {x=pexmax, y=peymax, z=0})
		else
			pposa = vector.add(pposa, {x=0, y=peymax, z=pexmax})
		end

		return minetest.add_entity(pposa, "mcl_paintings:painting", minetest.serialize({
			_yaw = minetest.dir_to_yaw(dir),
			_pos = pointed_thing.above,
			_motive = m,
			_xsize = x,
			_ysize = y,
		}))
	end
end

minetest.register_craftitem("mcl_paintings:painting", {
	description = S("Painting"),
	inventory_image = "mcl_paintings_painting.png",
	groups = {deco_block = 1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end
		if mcl_util.check_position_protection(pointed_thing.above, placer) then return itemstack end
		local xmax, ymax = get_maxes(pointed_thing)
		mcl_paintings.spawn_painting(pointed_thing, get_random_painting(xmax, ymax))
		itemstack:take_item()
		return itemstack
	end,
})

mcl_paintings.register_painting({ name = "swords", width = 2, height = 2, oldid = 1 })
mcl_paintings.register_painting({ name = "axe", width = 2, height = 1, oldid = 2  })
mcl_paintings.register_painting({ name = "banner_blue_gold", width = 1, height = 2, oldid = 2 })
mcl_paintings.register_painting({ name = "banner_green_gold", width = 1, height = 2, oldid = 1 })
mcl_paintings.register_painting({ name = "book", width = 1, height = 1, oldid = 4 })
mcl_paintings.register_painting({ name = "book_squid_cards", width = 4, height = 2, oldid = 1 })
mcl_paintings.register_painting({ name = "bottles", width = 2, height = 1, oldid = 1 })
mcl_paintings.register_painting({ name = "cards", width = 1, height = 1, oldid = 5 })
mcl_paintings.register_painting({ name = "crossedswords", width = 2, height = 2, oldid = 5 })
mcl_paintings.register_painting({ name = "darktower", width = 4, height = 4, oldid = 2 })
mcl_paintings.register_painting({ name = "desert", width = 2, height = 1, oldid = 5 })
mcl_paintings.register_painting({ name = "forest", width = 2, height = 1, oldid = 4 })
mcl_paintings.register_painting({ name = "house", width = 4, height = 4, oldid = 3 })
mcl_paintings.register_painting({ name = "gentle", width = 1, height = 1, oldid = 3 })
mcl_paintings.register_painting({ name = "jungle", width = 4, height = 3, oldid = 2 })
mcl_paintings.register_painting({ name = "knives", width = 1, height = 1, oldid = 7 })
mcl_paintings.register_painting({ name = "mordor", width = 4, height = 3, oldid = 4 })
mcl_paintings.register_painting({ name = "pans", width = 2, height = 1, oldid = 3 })
mcl_paintings.register_painting({ name = "sandcastle", width = 2, height = 2, oldid = 4 })
mcl_paintings.register_painting({ name = "searose", width = 2, height = 2, oldid = 2 })
mcl_paintings.register_painting({ name = "shield", width = 1, height = 1, oldid = 6 })
mcl_paintings.register_painting({ name = "snowmountain", width = 1, height = 1, oldid = 2 })
mcl_paintings.register_painting({ name = "snowtrees", width = 2, height = 2, oldid = 3 })
mcl_paintings.register_painting({ name = "squid", width = 1, height = 1, oldid = 1  })
mcl_paintings.register_painting({ name = "timberframe", width = 2, height = 2, oldid = 1 })
mcl_paintings.register_painting({ name = "waterfall", width = 4, height = 4, oldid = 1 })

minetest.register_craft({
	output = "mcl_paintings:painting",
	recipe = {
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
		{ "mcl_core:stick", "group:wool", "mcl_core:stick" },
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
	}
})
