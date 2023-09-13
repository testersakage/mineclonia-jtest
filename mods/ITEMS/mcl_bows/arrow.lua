local S = minetest.get_translator(minetest.get_current_modname())

--local enable_pvp = minetest.settings:get_bool("enable_pvp")

-- Time in seconds after which a stuck arrow is deleted
local ARROW_TIMEOUT = 60
-- Time after which stuck arrow is rechecked for being stuck
local STUCK_RECHECK_TIME = 5

--local GRAVITY = 9.81

local YAW_OFFSET = -math.pi/2
--[[
local function dir_to_pitch(dir)
	--local dir2 = vector.normalize(dir)
	local xz = math.abs(dir.x) + math.abs(dir.z)
	return -math.atan2(-dir.y, xz)
end

local function random_arrow_positions(positions, placement)
	if positions == "x" then
		return math.random(-4, 4)
	elseif positions == "y" then
		return math.random(0, 10)
	end
	if placement == "front" and positions == "z" then
		return 3
	elseif placement == "back" and positions == "z" then
		return -3
	end
	return 0
end
--]]

minetest.register_craftitem("mcl_bows:arrow", {
	description = S("Arrow"),
	_tt_help = S("Ammunition").."\n"..S("Damage from bow: 1-10").."\n"..S("Damage from dispenser: 3"),
	_doc_items_longdesc = S("Arrows are ammunition for bows and dispensers.").."\n"..
S("An arrow fired from a bow has a regular damage of 1-9. At full charge, there's a 20% chance of a critical hit dealing 10 damage instead. An arrow fired from a dispenser always deals 3 damage.").."\n"..
S("Arrows might get stuck on solid blocks and can be retrieved again. They are also capable of pushing wooden buttons."),
	_doc_items_usagehelp = S("To use arrows as ammunition for a bow, just put them anywhere in your inventory, they will be used up automatically. To use arrows as ammunition for a dispenser, place them in the dispenser's inventory. To retrieve an arrow that sticks in a block, simply walk close to it."),
	inventory_image = "mcl_bows_arrow_inv.png",
	groups = { ammo=1, ammo_bow=1, ammo_bow_regular=1, ammo_crossbow=1 },
	_on_dispense = function(itemstack, dispenserpos, droppos, dropnode, dropdir)
		-- Shoot arrow
		local shootpos = vector.add(dispenserpos, vector.multiply(dropdir, 0.51))
		local yaw = math.atan2(dropdir.z, dropdir.x) + YAW_OFFSET
		mcl_bows.shoot_arrow(itemstack:get_name(), shootpos, dropdir, yaw, nil, 19, 3)
	end,
})

local ARROW_ENTITY={
	physical = true,
	pointable = false,
	visual = "mesh",
	mesh = "mcl_bows_arrow.obj",
	visual_size = {x=-1, y=1},
	textures = {"mcl_bows_arrow.png"},
	collisionbox = {-0.19, -0.125, -0.19, 0.19, 0.125, 0.19},
	collide_with_objects = false,
	_fire_damage_resistant = true,

	_lastpos={},
	_startpos=nil,
	_damage=1,	-- Damage on impact
	_is_critical=false, -- Whether this arrow would deal critical damage
	_stuck=false,   -- Whether arrow is stuck
	_lifetime=0,-- Amount of time (in seconds) the arrow has existed
	_stuckrechecktimer=nil,-- An additional timer for periodically re-checking the stuck status of an arrow
	_stuckin=nil,	--Position of node in which arow is stuck.
	_shooter=nil,	-- ObjectRef of player or mob who shot it
	_is_arrow = true,
	_in_player = false,
	_blocked = false,
	_viscosity=0,   -- Viscosity of node the arrow is currently in
	_deflection_cooloff=0, -- Cooloff timer after an arrow deflection, to prevent many deflections in quick succession
}

-- Destroy arrow entity self at pos and drops it as an item
--[[
local function spawn_item(self, pos)
	if not minetest.is_creative_enabled("") then
		local itemstring = "mcl_bows:arrow"
		if self._itemstring and minetest.registered_items[self._itemstring] then
			itemstring = self._itemstring
		end
		local item = minetest.add_item(pos, itemstring)
		item:set_velocity(vector.new(0, 0, 0))
		item:set_yaw(self.object:get_yaw())
	end
	mcl_burning.extinguish(self.object)
	self.object:remove()
end


local function damage_particles(pos, is_critical)
	if is_critical then
		minetest.add_particlespawner({
			amount = 15,
			time = 0.1,
			minpos = vector.offset(pos, -0.5, -0.5, -0.5),
			maxpos = vector.offset(pos, 0.5, 0.5, 0.5),
			minvel = vector.new(-0.1, -0.1, -0.1),
			maxvel = vector.new(0.1, 0.1, 0.1),
			minexptime = 1,
			maxexptime = 2,
			minsize = 1.5,
			maxsize = 1.5,
			collisiondetection = false,
			vertical = false,
			texture = "mcl_particles_crit.png^[colorize:#bc7a57:127",
		})
	end
end
--]]

function ARROW_ENTITY:hit_node()
	local pos = self.object:get_pos()
	local vel = self.object:get_velocity()
	local dir
	if (math.abs(vel.x) < 0.0001) or (math.abs(vel.z) < 0.0001) or (math.abs(vel.y) < 0.00001) then
		-- Check for the node to which the arrow is pointing
		if math.abs(vel.y) < 0.00001 then
			if self._lastpos.y < pos.y then
				dir = vector.new(0, 1, 0)
			else
				dir = vector.new(0, -1, 0)
			end
		else
			dir = minetest.facedir_to_dir(minetest.dir_to_facedir(minetest.yaw_to_dir(self.object:get_yaw()-YAW_OFFSET)))
		end
	end

	local dpos = vector.round(vector.new(self.object:get_pos())) -- digital pos
	local node = minetest.get_node(dpos)
	local bdef = minetest.registered_nodes[node.name]
	self._stuckin = vector.add(dpos, dir)
	local snode = minetest.get_node(self._stuckin)
	local sdef = minetest.registered_nodes[snode.name]
	if (bdef and bdef._on_arrow_hit) then
		bdef._on_arrow_hit(dpos, self)
	elseif (sdef and sdef._on_arrow_hit) then
		sdef._on_arrow_hit(self._stuckin, self)
	end
end

function ARROW_ENTITY:emit_particle(dtime)
	self.particle_timer = (self.particle_timer or 0.5) - dtime
	if self._damage >= 9 and self._in_player == false and self.particle_timer < 0 then
		minetest.add_particlespawner({
			amount = 20,
			time = .2,
			minpos = vector.new(0,0,0),
			maxpos = vector.new(0,0,0),
			minvel = vector.new(-0.1,-0.1,-0.1),
			maxvel = vector.new(0.1,0.1,0.1),
			minexptime = 0.5,
			maxexptime = 0.5,
			minsize = 2,
			maxsize = 2,
			attached = self.object,
			collisiondetection = false,
			vertical = false,
			texture = "mobs_mc_arrow_particle.png",
			glow = 1,
		})
	end
end

function ARROW_ENTITY:extra_hit(obj)
	if self._extra_hit_func then
		if self._extra_hit_func(obj) then
			return true
		end
	end
end

local function get_obj_box(obj)
	local box

	if obj:is_player() then
		box = obj:get_properties().collisionbox or {-0.5, 0.0, -0.5, 0.5, 1.0, 0.5}
	else
		box = obj:get_luaentity().collisionbox or {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
	end

	return box
end

--[[
local function limit(x, min, max)
	return math.min(math.max(x, min), max)
end
--]]

function ARROW_ENTITY.on_step(self, dtime)
	mcl_burning.tick(self.object, dtime, self)
	-- mcl_burning.tick may remove object immediately
	local pos = self.object:get_pos()
	if not pos then return end



	self._old_pos = self._old_pos or pos
	local ray = minetest.raycast(self._old_pos, pos, true, true)
	local pointed_thing = ray:next()

	self._lifetime = self._lifetime + dtime
	self._nodechecktimer = ( self._nodechecktimer or 0.5) - dtime

	-- adjust pitch when flying
	if not self._attached then
		local velocity = self.object:get_velocity()
		local v_rotation = self.object:get_rotation()
		local pitch = math.atan2(velocity.y, math.sqrt(velocity.x^2 + velocity.z^2))

		self.object:set_rotation({
			x = pitch,
			y = v_rotation.y,
			z = v_rotation.z
		})
	end

	-- remove attached arrows after lifetime
	if self._lifetime > ARROW_TIMEOUT then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end

	-- add particles only when not attached
	if not self._attached and not self._in_liquid then
		self._has_particles = true

		self:emit_particle(dtime)
		--if self._tflp >= self._tool_capabilities.full_punch_interval then
		--	if self._is_critical_hit then
		--		nextgen_bows.particle_effect(self._old_pos, 'arrow_crit')
		--	else
		--		nextgen_bows.particle_effect(self._old_pos, 'arrow')
		--	end
		--end
	end

	-- remove attached arrows after object dies
	if not self.object:get_attach() and self._attached_to and self._attached_to.type == 'object' then
		self.object:remove()
		return
	end

	-- arrow falls down when not attached to node any more
	if self._attached_to and self._attached_to.type == 'node' and self._attached and self._nodechecktimer <= 0 then
		local node = minetest.get_node(self._attached_to.pos)
		self._nodechecktimer = 0.5

		if not node then
			return
		end

		if node.name == 'air' then
			self.object:set_velocity({x = 0, y = -3, z = 0})
			self.object:set_acceleration({x = 0, y = -3, z = 0})
			-- reset values
			self._attached = false
			self._attached_to.type = ''
			self._attached_to.pos = nil
			self.object:set_properties({collisionbox = {0, 0, 0, 0, 0, 0}})

			return
		end
	end

	while pointed_thing do
		local ip_pos = pointed_thing.intersection_point
		local in_pos = pointed_thing.intersection_normal
		self.pointed_thing = pointed_thing

		if pointed_thing.type == 'object'
			and pointed_thing.ref ~= self.object
			and pointed_thing.ref:get_hp() > 0
			and ((pointed_thing.ref:is_player() and pointed_thing.ref:get_player_name() ~= self.user:get_player_name()) or (pointed_thing.ref:get_luaentity() and pointed_thing.ref:get_luaentity().physical and pointed_thing.ref:get_luaentity().name ~= '__builtin:item'))
			and self.object:get_attach() == nil
		then
			if pointed_thing.ref:is_player() then
				minetest.sound_play('nextgen_bows_arrow_successful_hit', {
					to_player = self.user:get_player_name(),
					gain = 0.3
				})
			else
				minetest.sound_play('nextgen_bows_arrow_hit', {
					to_player = self.user:get_player_name(),
					gain = 0.6
				})
			end

			-- store these here before punching in case pointed_thing.ref dies
			local collisionbox = get_obj_box(pointed_thing.ref)
			local xmin = collisionbox[1] * 100
			local ymin = collisionbox[2] * 100
			local zmin = collisionbox[3] * 100
			local xmax = collisionbox[4] * 100
			local ymax = collisionbox[5] * 100
			local zmax = collisionbox[6] * 100

			self.object:set_velocity({x = 0, y = 0, z = 0})
			self.object:set_acceleration({x = 0, y = 0, z = 0})

			-- calculate damage
			--local target_armor_groups = pointed_thing.ref:get_armor_groups()
			local _damage = 0
			--[[
			for group, base_damage in pairs(self._tool_capabilities.damage_groups) do
				_damage = _damage
					+ base_damage
					* limit(self._tflp / self._tool_capabilities.full_punch_interval, 0.0, 1.0)
					* ((target_armor_groups[group] or 0)  --+ get_3d_armor_armor(pointed_thing.ref)) / 100.0
			end
			--]]
			-- crits
			if self._is_critical_hit then
				_damage = _damage * 2
			end

			-- knockback
			local dir = vector.normalize(vector.subtract(self._shot_from_pos, ip_pos))
			local distance = vector.distance(self._shot_from_pos, ip_pos)
			local knockback = minetest.calculate_knockback(
				pointed_thing.ref,
				self.object,
				self._tflp,
				{
					full_punch_interval = self._tool_capabilities.full_punch_interval,
					damage_groups = {fleshy = _damage},
				},
				dir,
				distance,
				_damage
			)

			pointed_thing.ref:add_velocity({
				x = dir.x * knockback * -1,
				y = 7,
				z = dir.z * knockback * -1
			})

			pointed_thing.ref:punch(
				self.object,
				self._tflp,
				{
					full_punch_interval = self._tool_capabilities.full_punch_interval,
					damage_groups = {fleshy = _damage, knockback = knockback}
				},
				{
					x = dir.x * -1,
					y = 7,
					z = dir.z * -1
				}
			)

			-- already dead (entity)
			if not pointed_thing.ref:get_luaentity() and not pointed_thing.ref:is_player() then
				self.object:remove()
				return
			end

			-- already dead (player)
			if pointed_thing.ref:get_hp() <= 0 then
				-- Reset HUD bar color
				hb.change_hudbar(pointed_thing.ref, 'health', nil, nil, 'hudbars_icon_health.png', nil, 'hudbars_bar_health.png')

				self.object:remove()
				return
			end

			-- attach arrow prepare
			local rotation = {x = 0, y = 0, z = 0}
			local position = {x = 0, y = 0, z = 0}

			if in_pos.x == 1 then
				-- x = 0
				-- y = -90
				-- z = 0
				rotation.x = math.random(-10, 10)
				rotation.y = math.random(-100, -80)
				rotation.z = math.random(-10, 10)

				position.x = xmax / 10
				position.y = math.random(ymin, ymax) / 10
				position.z = math.random(zmin, zmax) / 10
			elseif in_pos.x == -1 then
				-- x = 0
				-- y = 90
				-- z = 0
				rotation.x = math.random(-10, 10)
				rotation.y = math.random(80, 100)
				rotation.z = math.random(-10, 10)

				position.x = xmin / 10
				position.y = math.random(ymin, ymax) / 10
				position.z = math.random(zmin, zmax) / 10
			elseif in_pos.y == 1 then
				-- x = -90
				-- y = 0
				-- z = -180
				rotation.x = math.random(-100, -80)
				rotation.y = math.random(-10, 10)
				rotation.z = math.random(-190, -170)

				position.x = math.random(xmin, xmax) / 10
				position.y = ymax / 10
				position.z = math.random(zmin, zmax) / 10
			elseif in_pos.y == -1 then
				-- x = 90
				-- y = 0
				-- z = 180
				rotation.x = math.random(80, 100)
				rotation.y = math.random(-10, 10)
				rotation.z = math.random(170, 190)

				position.x = math.random(xmin, xmax) / 10
				position.y = ymin / 10
				position.z = math.random(zmin, zmax) / 10
			elseif in_pos.z == 1 then
				-- x = 180
				-- y = 0
				-- z = 180
				rotation.x = math.random(170, 190)
				rotation.y = math.random(-10, 10)
				rotation.z = math.random(170, 190)

				position.x = math.random(xmin, xmax) / 10
				position.y = math.random(ymin, ymax) / 10
				position.z = zmax / 10
			elseif in_pos.z == -1 then
				-- x = -180
				-- y = 180
				-- z = -180
				rotation.x = math.random(-190, -170)
				rotation.y = math.random(170, 190)
				rotation.z = math.random(-190, -170)

				position.x = math.random(xmin, xmax) / 10
				position.y = math.random(ymin, ymax) / 10
				position.z = zmin / 10
			end

			-- fix scaling
			local scale = self.object:get_properties().visual_size
			local parent_size = pointed_thing.ref:get_properties().visual_size
			self.object:set_properties({
				visual_size = {
					x = scale.x / parent_size.x,
					y = scale.y / parent_size.y,
					z = scale.z / (parent_size.z or parent_size.x)
				},
			})
			position.x = position.x / parent_size.x
			position.y = position.y / parent_size.y
			position.z = position.z / (parent_size.z or parent_size.x)

			-- attach arrow
			self.object:set_attach(
				pointed_thing.ref,
				'',
				position,
				rotation,
				true
			)
			self._attached = true
			self._attached_to.type = pointed_thing.type
			self._attached_to.pos = position

			local children = pointed_thing.ref:get_children()

			-- remove last arrow when too many already attached
			if #children >= 5 then
				children[1]:remove()
			end

			return

		elseif pointed_thing.type == 'node' and not self._attached then
			local node = minetest.get_node(pointed_thing.under)
			local node_def = minetest.registered_nodes[node.name]

			if not node_def then
				return
			end

			self._velocity = self.object:get_velocity()

			if node_def.drawtype == 'liquid' and not self._is_drowning then
				self._is_drowning = true
				self._in_liquid = true
				local drag = 1 / (node_def.liquid_viscosity * 6)
				self.object:set_velocity(vector.multiply(self._velocity, drag))
				self.object:set_acceleration({x = 0, y = -1.0, z = 0})

				--nextgen_bows.particle_effect(self._old_pos, 'bubble')
			elseif self._is_drowning then
				self._is_drowning = false

				if self._velocity then
					self.object:set_velocity(self._velocity)
				end

				self.object:set_acceleration({x = 0, y = -9.81, z = 0})
			end

			if node_def.walkable then
				self.object:set_velocity({x=0, y=0, z=0})
				self.object:set_acceleration({x=0, y=0, z=0})
				self.object:set_pos(ip_pos)
				self.object:set_rotation(self.object:get_rotation())
				self._attached = true
				self._attached_to.type = pointed_thing.type
				self._attached_to.pos = pointed_thing.under
				self.object:set_properties({collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2}})

				-- remove last arrow when too many already attached
				local children = {}

				for k, object in ipairs(minetest.get_objects_inside_radius(pointed_thing.under, 1)) do
					if not object:is_player() and object:get_luaentity() and object:get_luaentity().is_arrow then
						table.insert(children ,object)
					end
				end

				if #children >= 5 then
					children[#children]:remove()
				end

				minetest.sound_play('nextgen_bows_arrow_hit', {
					pos = pointed_thing.under,
					gain = 0.6,
					max_hear_distance = 16
				})

				return
			end
		end
		pointed_thing = ray:next()
	end

	self._old_pos = pos
end

-- Force recheck of stuck arrows when punched.
-- Otherwise, punching has no effect.
function ARROW_ENTITY.on_punch(self)
	if self._stuck then
		self._stuckrechecktimer = STUCK_RECHECK_TIME
	end
end

function ARROW_ENTITY.get_staticdata(self)
	local out = {
		lastpos = self._lastpos,
		startpos = self._startpos,
		damage = self._damage,
		is_critical = self._is_critical,
		stuck = self._stuck,
		stuckin = self._stuckin,
		stuckin_player = self._in_player,
		itemstring = self._itemstring,
	}
	-- If _lifetime is missing for some reason, assume the maximum
	if not self._lifetime then
		self._lifetime = ARROW_TIMEOUT
	end
	out.starttime = minetest.get_gametime() - self._lifetime
	if self._shooter and self._shooter:is_player() then
		out.shootername = self._shooter:get_player_name()
	end
	return minetest.serialize(out)
end

function ARROW_ENTITY.on_activate(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if data then
		-- First, check if the arrow is already past its life timer. If
		-- yes, delete it. If starttime is nil always delete it.
		self._lifetime = minetest.get_gametime() - (data.starttime or 0)
		if self._lifetime > ARROW_TIMEOUT then
			mcl_burning.extinguish(self.object)
			self.object:remove()
			return
		end
		self._stuck = data.stuck
		if data.stuck then
			-- Perform a stuck recheck on the next step.
			self._stuckrechecktimer = STUCK_RECHECK_TIME

			self._stuckin = data.stuckin
		end

		-- Get the remaining arrow state
		self._lastpos = data.lastpos
		self._startpos = data.startpos
		self._damage = data.damage
		self._is_critical = data.is_critical
		self._itemstring = data.itemstring
		self._is_arrow = true
		if data.shootername then
			local shooter = minetest.get_player_by_name(data.shootername)
			if shooter and shooter:is_player() then
				self._shooter = shooter
			end
		end

		if data.stuckin_player then
			self.object:remove()
		end
	end
	self.object:set_armor_groups({ immortal = 1 })
end

minetest.register_on_respawnplayer(function(player)
	for _, obj in pairs(player:get_children()) do
		local ent = obj:get_luaentity()
		if ent and ent.name and string.find(ent.name, "mcl_bows:arrow_entity") then
			obj:remove()
		end
	end
end)

minetest.register_entity("mcl_bows:arrow_entity", ARROW_ENTITY)

if minetest.get_modpath("mcl_core") and minetest.get_modpath("mcl_mobitems") then
	minetest.register_craft({
		output = "mcl_bows:arrow 4",
		recipe = {
			{"mcl_core:flint"},
			{"mcl_core:stick"},
			{"mcl_mobitems:feather"}
		}
	})
end

if minetest.get_modpath("doc_identifier") then
	doc.sub.identifier.register_object("mcl_bows:arrow_entity", "craftitems", "mcl_bows:arrow")
end
