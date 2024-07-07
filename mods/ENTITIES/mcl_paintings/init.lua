mcl_paintings = {
	registered_paintings = {},
	old_motives = {},
	texture_size = 16,
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
--[[
local function get_painting(name)
	for _, v in pairs(mcl_paintings.registered_paintings) do
		if v.name == name or not name then return v.file end
	end
end
--]]

local function get_random_painting(x, y)
	table.shuffle(mcl_paintings.registered_paintings)
	for _, v in pairs(mcl_paintings.registered_paintings) do
		if v.width <= x and v.height <= y then return v.file, v.width, v.height end
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

function painting_entity:on_activate(staticdata)
	self.object:set_armor_groups({immortal = 1})
	if staticdata and staticdata ~= "" then
		local data = minetest.deserialize(staticdata)
		if data then
			self._yaw = data._yaw
			self._pos = data._pos
			self._motive = data._motive
			self._xsize = data._xsize
			self._ysize = data._ysize
			if tonumber(self._motive) then
				self._motive = mcl_paintings.old_motives[self._motive]
			end
			if not self._motive then
				self.object:remove()
				return
			end
		end
	end
	self:set_motive()
end

function painting_entity:get_staticdata()
	local data = {
		_facing = self._facing,
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

function painting_entity:set_motive()
	self.object:set_properties({
		--selectionbox = box,
		visual_size = vector.new(self._xsize, self._ysize, 1/32 ),
		textures = { wood, wood, wood, wood, self._motive, wood },
	})
	self.object:set_rotation(vector.new(0, self._yaw or 0, 0))
end

minetest.register_entity("mcl_paintings:painting", painting_entity)

minetest.register_craftitem("mcl_paintings:painting", {
	description = S("Painting"),
	inventory_image = "mcl_paintings_painting.png",
	groups = {deco_block = 1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end
		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end
		local ppos = pointed_thing.above
		if mcl_util.check_position_protection(ppos, placer) then return itemstack end

		local m, x, y = get_random_painting(4, 4)
		minetest.add_entity(ppos, "mcl_paintings:painting", minetest.serialize({
			_yaw = minetest.dir_to_yaw(vector.direction(pointed_thing.under, pointed_thing.above)),
			_pos = ppos,
			_motive = m,
			_xsize = x,
			_ysize = y,
		}))
	end,
})

mcl_paintings.register_painting({ name = "swords", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "mcla", width = 4, height = 3 })
mcl_paintings.register_painting({ name = "axe", width = 2, height = 1 })
mcl_paintings.register_painting({ name = "banner_blue_gold", width = 1, height = 2 })
mcl_paintings.register_painting({ name = "banner_green_gold", width = 1, height = 2 })
mcl_paintings.register_painting({ name = "book", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "book_squid_cards", width = 4, height = 2 })
mcl_paintings.register_painting({ name = "bottles", width = 2, height = 1 })
mcl_paintings.register_painting({ name = "cards", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "crossedswords", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "darktower", width = 4, height = 4 })
mcl_paintings.register_painting({ name = "desert", width = 2, height = 1 })
mcl_paintings.register_painting({ name = "forest", width = 2, height = 1 })
mcl_paintings.register_painting({ name = "house", width = 4, height = 4 })
mcl_paintings.register_painting({ name = "gentle", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "irises", width = 4, height = 3 })
mcl_paintings.register_painting({ name = "mcl2", width = 4, height = 3 })
mcl_paintings.register_painting({ name = "jungle", width = 4, height = 3 })
mcl_paintings.register_painting({ name = "knives", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "mordor", width = 4, height = 3 })
mcl_paintings.register_painting({ name = "pans", width = 2, height = 1 })
mcl_paintings.register_painting({ name = "sandcastle", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "searose", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "shield", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "snowmountain", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "snowtrees", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "squid", width = 1, height = 1 })
mcl_paintings.register_painting({ name = "waterfall", width = 4, height = 4 })
mcl_paintings.register_painting({ name = "timberframe", width = 2, height = 2 })
mcl_paintings.register_painting({ name = "young_man", width = 1, height = 2 })


minetest.register_craft({
	output = "mcl_paintings:painting",
	recipe = {
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
		{ "mcl_core:stick", "group:wool", "mcl_core:stick" },
		{ "mcl_core:stick", "mcl_core:stick", "mcl_core:stick" },
	}
})
