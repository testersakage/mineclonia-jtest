-- Eye of Ender
local S = core.get_translator(core.get_current_modname())

local texpool = {
	{name = "mcl_end_eoe_particle1.png", scale_tween = {0.5, 3}},
	{name = "mcl_end_eoe_particle2.png", scale_tween = {0.5, 3}},
	{name = "mcl_end_eoe_particle3.png", scale_tween = {0.5, 3}},
}

-- Trailing particles of a thrown eye of ender
local traildef = {
	texpool = texpool,
	time = 4,
	exptime = 2,
	amount = 90,
	attached = nil, -- set when spawning.
	pos = {min = vector.new(-0.25, -0.25, -0.25), max = vector.new(0.25, 0.25, 0.25)},
	acc = vector.new(0, -1, 0),
}

-- Implosion animation when eye of ender breaks.
local implodef = {
	texpool = texpool,
	time = 0.1,
	exptime = 0.5,
	amount = 25,
	attract = {
		kind = "point",
		strength = 1,
		origin = nil, -- set when spawning.
	},
	pos = nil, --set when spawning.
	radius = 1,
}

-- Explosion animation when eye of ender breaks.
local explodef = {
	texpool = texpool,
	time = 0.1,
	exptime = 2,
	amount = 100,
	attract = {
		kind = "point",
		strength = -25,
		origin = nil, -- set when spawning.
	},
	pos = nil, --set when spawning.
	radius = 0.1,
	drag = -1,
}

local GRAVITY = vector.new(0, -10, 0)
local BOUNCE_VEL = vector.new(0, 6, 0)
local REBOUNCE_VEL = vector.new(0, 2, 0)

core.register_entity("mcl_end:ender_eye", {
	initial_properties = {
		physical = false,
		textures = {"mcl_end_ender_eye.png"},
		visual_size = {x=1.5, y=1.5},
		collisionbox = {0,0,0,0,0,0},
		pointable = false,
	},

	_age = 0, -- age in seconds
	_phase = 0, -- phase 0: flying. phase 1: idling in mid air, about to drop or shatter

	get_staticdata = function(self)
		return core.serialize({age = self._age, phase = self._phase})
	end,

	on_activate = function(self, staticdata)
		local data = core.deserialize(staticdata) or {}
		self._age = tonumber(data.age) or 0
		self._phase = tonumber(data.phase) or 0
	end,

	on_step = function(self, dtime)
		self._age = self._age + dtime
		if self._age >= 2 and self._phase == 0 then
			self._phase = 1
			-- Stop the eye and bounce it upward.
			self.object:set_acceleration(GRAVITY)
			self.object:set_velocity(BOUNCE_VEL)
		elseif self._age >= 3 and self._phase == 1 then
			self._phase = 2
			self.object:set_velocity(REBOUNCE_VEL)
		elseif self._age >= 3.5 and self._phase == 2 then
			self._phase = 3
			self.object:set_velocity(REBOUNCE_VEL)
		elseif self._age >= 4 then
			-- End of life
			local pos = self.object:get_pos()
			local v = self.object:get_velocity()
			self.object:remove()
			local r = math.random(1,5)
			if r == 1 then
				-- 20% chance to get destroyed completely.
				implodef.pos = pos
				implodef.attract.origin = pos
				core.add_particlespawner(implodef)
				explodef.pos = pos
				explodef.attract.origin = pos
				core.after(0.5, core.add_particlespawner, explodef)
			else
				-- 80% to drop as an item
				local item = core.add_item(pos, "mcl_end:ender_eye")
				item:set_velocity(v)
			end
		end
	end,
})

-- Throw eye of ender to make it fly to the closest stronghold
local function throw_eye(itemstack, user)
	if user == nil then return end
	local origin = user:get_pos()
	origin.y = origin.y + 1.5
	local strongholds = mcl_biome_dispatch.get_stronghold_positions ()
	local dim = mcl_worlds.pos_to_dimension(origin)
	local is_creative = core.is_creative_enabled(user:get_player_name())

	-- Just drop the eye of ender if there are no strongholds
	if #strongholds <= 0 or dim ~= "overworld" then
		if not is_creative then
			core.item_drop(ItemStack("mcl_end:ender_eye"), user, user:get_pos())
			itemstack:take_item()
		end
		return itemstack
	end

	-- Find closest stronghold.
	-- Note: Only the horizontal axes are taken into account.
	local closest_stronghold
	local lowest_dist
	for s=1, #strongholds do
		local h_pos = table.copy(strongholds[s])
		local h_origin = table.copy(origin)
		h_pos.y = 0
		h_origin.y = 0
		local dist = vector.distance(h_origin, h_pos)
		if not closest_stronghold then
			closest_stronghold = strongholds[s]
			lowest_dist = dist
		else
			if dist < lowest_dist then
				closest_stronghold = strongholds[s]
				lowest_dist = dist
			end
		end
	end

	-- Throw it!
	local obj = core.add_entity(origin, "mcl_end:ender_eye")
	if not obj or not obj:get_pos() then return end
	local dir

	if lowest_dist <= 25 then
		local velocity = 4
		-- Stronghold is close: Fly directly to stronghold and take Y into account.
		dir = vector.normalize(vector.direction(origin, closest_stronghold))
		obj:set_velocity({x=dir.x*velocity, y=dir.y*velocity, z=dir.z*velocity})
	else
		local velocity = 12
		-- Don't care about Y if stronghold is still far away.
		-- Fly to direction of X/Z, and always upwards so it can be seen easily.
		local o = {x=origin.x, y=0, z=origin.z}
		local s = {x=closest_stronghold.x, y=0, z=closest_stronghold.z}
		dir = vector.normalize(vector.direction(o, s))
		obj:set_acceleration({x=dir.x*-3, y=4, z=dir.z*-3})
		obj:set_velocity({x=dir.x*velocity, y=3, z=dir.z*velocity})

	end

	traildef.attached = obj
	core.add_particlespawner(traildef)

	if not is_creative then
		itemstack:take_item()
	end
	return itemstack
end

core.register_craftitem("mcl_end:ender_eye", {
	description = S("Eye of Ender"),
	_tt_help = S("Guides the way to the mysterious End dimension"),
	_doc_items_longdesc = S("This item is used to locate End portal shrines in the Overworld and to activate End portals.") .. "\n" .. S("NOTE: The End dimension is currently incomplete and might change in future versions."),
	_doc_items_usagehelp = S("Use the attack key to release the eye of ender. It will rise and fly in the horizontal direction of the closest end portal shrine. If you're very close, the eye of ender will take the direct path to the End portal shrine instead. After a few seconds, it stops. It may drop as an item, but there's a 20% chance it shatters.") .. "\n" .. S("To activate an End portal, eyes of ender need to be placed into each block of an intact End portal frame."),
	wield_image = "mcl_end_ender_eye.png",
	inventory_image = "mcl_end_ender_eye.png",
	on_place = throw_eye,
	on_secondary_use = throw_eye,
})

core.register_craft({
	type = "shapeless",
	output = "mcl_end:ender_eye",
	recipe = {"mcl_mobitems:blaze_powder", "mcl_throwing:ender_pearl"},
})
