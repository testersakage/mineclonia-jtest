local S = core.get_translator(core.get_current_modname())

local gravity = -1.6

local ONE_TICK			= 0.05

local AIR_DRAG = 0.98
local FALL_FLYING_DRAG_HORIZ	= 0.99
local FALL_FLYING_DRAG_ASCENT	= 0.04
local FALL_FLYING_ACC_DESCENT	= 3.2
local FALL_FLYING_ROTATION_DRAG = 0.1

local BASE_ROCKET_BOOST = 2.0
local ROCKET_BOOST_FORCE = 30.0

local elytra_entity = {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_elytra_entity.obj",
		textures = { "blank.png" },
		visual_size = {x=1.0, y=1.0},
		collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
		pointable = false,
		physical = true,
		collide_with_objects = false,
		static_save = false,
	},
	_horiz_collision = false,
	_damage_immune = 0,
	_timer = 0,
}

local function horiz_collision (moveresult)
	for _, item in ipairs (moveresult.collisions) do
		if item.axis == "x" or item.axis == "z" then
			-- Exclude ignore nodes from collision detection.
			if item.type ~= "node"
				or core.get_node_or_nil (item.node_pos) then
				return true, item.old_velocity, item.new_velocity
			end
		end
	end
	return false, nil
end

function elytra_entity:rotate()
	local player = self._player
	local pitch = -player:get_look_vertical()
	local yaw = player:get_look_horizontal()
	local rot = vector.new(pitch, yaw, 0)
	self.object:set_rotation (rot)
end

function elytra_entity:attach(player)
	local player_v = player:get_velocity()
	mcl_player.players[player].elytra.active = true
	self.object:set_velocity(player_v)
	player:set_attach (self.object, "", vector.zero(), vector.zero())
	self._player = player
end

function elytra_entity:remove(player)
	local elytra = mcl_player.players[player].elytra
	mcl_player.players[player].elytra.active = false
	elytra.rocketing = 0
	self.object:remove()
end

function elytra_entity:detach(player)
	player:add_velocity (self.object:get_velocity ())
	self:remove(player)
	player:set_detach ()
end

function elytra_entity:check_horiz_collision(moveresult)
	local player = self._player
	local elytra = mcl_player.players[player].elytra
	local damage_immune = math.max (self._damage_immune - 1, 0)
	self._damage_immune = damage_immune

	local old, new
	if not self._horiz_collision then
		self._horiz_collision, old, new = horiz_collision (moveresult)
	end

	-- Apply "kinetic damage" when the player collides
	-- with a wall while fall flying.
	if elytra.active and self._horiz_collision then
		if old and new then
			local diff = math.abs (vector.length (old) - vector.length (new))
			if diff >= 6.0 and self._damage_immune == 0 then
				mcl_damage.damage_player (player, diff * 0.5, { type = "fall", })
				self._damage_immune = 10
			end
		end
	end
end

function elytra_entity:rocket_boost(dtime)
	local player = self._player
	local elytra = mcl_player.players[player].elytra
	local dir = player:get_look_dir()
	local self_pos = player:get_pos()
	local v = self.object:get_velocity()

	if elytra.rocketing > 0 then
		v.x = dir.x * BASE_ROCKET_BOOST
			+ (dir.x * ROCKET_BOOST_FORCE - v.x) * 0.5
			+ v.x
		v.y = dir.y * BASE_ROCKET_BOOST
			+ (dir.y * ROCKET_BOOST_FORCE - v.y) * 0.5
			+ v.y
		v.z = dir.z * BASE_ROCKET_BOOST
			+ (dir.z * ROCKET_BOOST_FORCE - v.z) * 0.5
			+ v.z
		elytra.rocketing = elytra.rocketing - dtime
		local dir = vector.new (dir.x, 0, dir.z)
		local pos = vector.normalize (dir)
		local s = pos.x
		local c = pos.z
		pos.x = self_pos.x + (c * 0.5 + s * 0.7)
		pos.y = self_pos.y + 0.3
		pos.z = self_pos.z + (c * 0.7 - s * 0.5)
		core.add_particle ({
			pos = pos,
			expirationtime = 1.0,
			texture = "mcl_bows_rocket_particle.png^[colorize:#bc7a57:127",
		})
	end

	self.object:set_velocity(v)
end

function elytra_entity:consume_durability(dtime)
	self._timer = self._timer + dtime
	if self._timer >= 1.0 then
		local player = self._player
		local inv = mcl_util.get_inventory(player)
		local itemstack = inv:get_stack("armor", 3)
		local durability = mcl_util.calculate_durability (itemstack)
		local remaining = math.floor ((65536 - itemstack:get_wear ())
			* durability / 65536)

		if remaining == 1 then
			self:detach(player)
			mcl_armor.disable_elytra (itemstack)
		else
			mcl_util.use_item_durability(itemstack, 1)
			inv:set_stack("armor", 3, itemstack)
		end

		self._timer = self._timer - 1.0
	end
end

function elytra_entity:step_fall_flying (dtime)
	local player = self._player
	local v = self.object:get_velocity()
	if not v then
		-- The object was unloaded??
		self:detach (player)
		return
	end

	local inv = mcl_util.get_inventory(player)
	local itemstack = inv:get_stack("armor", 3)
	local armor_name = itemstack:get_name()

	if core.get_item_group(armor_name, "elytra") <= 0 then
		self:detach(player)
	end

	local dir = player:get_look_dir()
	local pitch = player:get_look_vertical()
	local horiz = math.sqrt (dir.x * dir.x + dir.z * dir.z)
	local movement = math.sqrt (v.x * v.x + v.z * v.z)
	local incline = math.cos (pitch)
	local v_movement = incline * incline

	-- Vy(n) = (Vy(n - 1) + a) + (Vy(n - 1) + a) * (b * c)
	-- a = -gravity * (-1.0 + v_movement * 0.75)
	-- b = ONE_TICK * -0.1 * v_movement * TICK_TO_SEC
	-- c = (Vy(n - 1) + a) * D
	-- c = (aD((D ^ n) - 1) / (D-1)) + Vy(last)D^(n)
	-- n = dtime / ONE_TICK
	--
	-- Vy(n) = a(b + 1)D((((b + 1)D) ^ n) - 1) / bD + D - 1 + Vy(last)((b + 1)D) ^ n-1

	local D = AIR_DRAG
	local default_b = -0.1 * v_movement
	local a = -gravity * (-1.0 + v_movement * 0.75)
	local n = dtime / ONE_TICK
	local c = v.y * D ^ (n) + (a * D * ((D ^ n) - 1)) / (D - 1)
	local b = (c < 0.0 and horiz > 0.0) and default_b or 0
	local a_factor = ((b + 1) * D * ((((b + 1) * D) ^ n) - 1)) / (b * D + D - 1)
	v.y = v.y * (((b + 1) * D) ^ (n)) + a * a_factor

	local D = FALL_FLYING_DRAG_HORIZ
	local h_factor = (D * ((D ^ n) - 1)) / (D - 1)

	-- Accelerate if moving downward.
	if c < 0.0 and horiz > 0.0 then
		-- Vx(n) = (Vx(n) + d) * D
		-- d = c / horiz * b * dir.x
		-- Vx(n) = (dD((D ^ n) - 1) / (D-1)) + Vx(last)D^(n)

		local d = (dir.x * (default_b * c) / horiz)
		local e = (dir.z * (default_b * c) / horiz)
		v.x = v.x * (D ^ (n)) + (d * h_factor)
		v.z = v.z * (D ^ (n)) + (e * h_factor)
	end
	-- Arrest horizontal movement when moving upward.
	if horiz > 0.0 and pitch < 0.0 then
		local arrest = movement * -math.sin (pitch)
			* FALL_FLYING_DRAG_ASCENT
		v.x = v.x + -dir.x * arrest / horiz * h_factor
		v.y = v.y + arrest * FALL_FLYING_ACC_DESCENT * a_factor
		v.z = v.z + -dir.z * arrest / horiz * h_factor
	end
	-- Apply rotation penalties.
	if horiz > 0.0 then
		v.x = v.x + (dir.x / horiz * movement - v.x)
			* FALL_FLYING_ROTATION_DRAG * h_factor
		v.z = v.z + (dir.z / horiz * movement - v.z)
			* FALL_FLYING_ROTATION_DRAG * h_factor
	end

	self.object:set_velocity(v)
end

function elytra_entity:underwater()
	local player = self._player
	local fly_pos = player:get_pos()
	local fly_node = core.get_node(vector.offset(fly_pos,0,-0.1,0)).name
	local def = core.registered_nodes[fly_node]
	local liquid_type = def and (def.liquidtype or def._liquidtype)

	if liquid_type and liquid_type ~= "none" then
		self:detach(player)
	end
end

function elytra_entity:on_step(dtime, moveresult)
	self:consume_durability(dtime)
	self:check_horiz_collision(moveresult)
	self:step_fall_flying (dtime)
	self:rocket_boost (dtime)
	self:underwater()
	self:rotate()

	local attach = self._player:get_attach()
	if attach and attach:get_luaentity()
		and attach:get_luaentity().name ~= "mcl_armor:elytra_entity" then
		self:remove(self._player)
	end

	if moveresult and moveresult.touching_ground then
		self:detach(self._player)
	end
end

core.register_entity(":mcl_armor:elytra_entity", elytra_entity)

local function attach_elytra (player, itemstack, self_pos)
	if itemstack then
		local durability = mcl_util.calculate_durability (itemstack)
		local remaining = math.floor ((65536 - itemstack:get_wear ())
			* durability / 65536)
		if remaining <= 1 then
			mcl_title.set(player, "actionbar", { text = S("Elytra is already broken."), color = "white", stay = 30 })
			return
		end
	end
	local obj = core.add_entity(self_pos, "mcl_armor:elytra_entity")
	local ent = obj:get_luaentity()
	if obj and ent then
		player:set_pos(vector.offset(self_pos,0,1,0))
		ent:attach(player)
	end
end

core.register_chatcommand ("attach_elytra", {
	privs = { server = true },
	func = function (name, _)
		local player = core.get_player_by_name (name);
		if player then
			player:set_look_vertical (math.rad (21.0))
			player:set_look_horizontal (0)
			attach_elytra (player, nil, player:get_pos ())
		end
	end,
})

mcl_player.register_globalstep(function (player)
	if mcl_serverplayer.is_csm_capable (player) then
		return
	end
	local self_pos = player:get_pos()
	local inv = mcl_util.get_inventory(player)
	local itemstack = inv:get_stack("armor", 3)
	local armor_name = itemstack:get_name()

	local elytra = mcl_player.players[player].elytra

	local fly_pos = player:get_pos()
	local fly_node = core.get_node(vector.offset(fly_pos,0,-0.1,0)).name
	local fly_node_walkable = core.registered_nodes[fly_node]
		and core.registered_nodes[fly_node].walkable
	local is_just_jumped = player:get_player_control().jump and not mcl_player.players[player].is_pressing_jump and not elytra.active
	mcl_player.players[player].is_pressing_jump = player:get_player_control().jump

	local can_fly = false
	can_fly = core.get_item_group(armor_name, "elytra") > 0
		and not player:get_attach()
		and (can_fly or (is_just_jumped and player:get_velocity().y < -0))
		and ((not fly_node_walkable) or fly_node == "ignore")

	if can_fly then
		attach_elytra (player, itemstack, self_pos)
	end
end)
