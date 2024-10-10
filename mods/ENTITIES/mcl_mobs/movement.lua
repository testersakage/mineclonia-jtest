local mob_class = mcl_mobs.mob_class
local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false

function mob_class:target_visible(origin, target)
	-- This cache is flushed on each call to on_step.
	if self._targets_visible[target] then
		return true
	end

	if not origin then return end

	if not target and self.attack then
		target = self.attack
	end
	if not target then return end

	local target_pos = target:get_pos()
	if not target_pos then return end

	local origin_eye_pos = vector.offset (origin, 0, self.head_eye_height, 0)
	local eye

	if target:is_player () then
		eye = target:get_properties ().eye_height
	else
		local entity = target:get_luaentity ()
		eye = 0
		if entity and entity.is_mob then
			eye = entity.head_eye_height
		end
	end
	target_pos.y = target_pos.y + eye

	if self:line_of_sight (origin_eye_pos, target_pos) then
		self._targets_visible[target] = true
		return true
	end

	self._targets_visible[target] = false
	return false
end

-- Check line of sight:
-- http://www.cse.yorku.ca/~amana/research/grid.pdf
-- The ubiquitous slab method of intersecting rays with
-- AABBs.

local function signum (number)
	return number == 0.0 and 0 or number < 0 and -1 or 1
end

local function genbox (box, node)
	box[1] = box[1] + node.x
	box[2] = box[2] + node.y
	box[3] = box[3] + node.z
	box[4] = box[4] + node.x
	box[5] = box[5] + node.y
	box[6] = box[6] + node.z
end

local function maxnum (a, b)
	return math.max (a, b)
end

local function minnum (a, b)
	return math.min (a, b)
end

local function aabb_clear (node, origin, pos2, direction, d, typetest)
	local node_type = minetest.get_node (node)
	if node_type.name == "air" then
		return true
	else
		local def = minetest.registered_nodes[node_type.name]
		if def and not def.walkable then
			return true
		elseif typetest and typetest (node_type.name, def) then
			return true
		elseif not def then
			return false
		end
	end
	local boxes = minetest.get_node_boxes ("collision_box", node)

	for _, box in ipairs (boxes) do
		genbox (box, node)
		local x1, y1, z1, x2, y2, z2
			= box[1], box[2], box[3], box[4], box[5], box[6]

		local min, max = -1/0, 1/0
		-- X face.
		local n1 = (x1 - origin.x) * direction.x
		local f1 = (x2 - origin.x) * direction.x
		if n1 > f1 then
			n1, f1 = f1, n1
		end
		min = maxnum (min, n1)
		max = minnum (max, f1)

		-- Y face.
		local n2 = (y1 - origin.y) * direction.y
		local f2 = (y2 - origin.y) * direction.y
		if n2 > f2 then
			n2, f2 = f2, n2
		end
		min = maxnum (min, n2)
		max = minnum (max, f2)

		-- Z face.
		local n3 = (z1 - origin.z) * direction.z
		local f3 = (z2 - origin.z) * direction.z
		if n3 > f3 then
			n3, f3 = f3, n3
		end
		min = maxnum (min, n3)
		max = minnum (max, f3)
		-- Intersection with furthest near face is within the
		-- vector.
		if ((min < 0 and max or min) <= d)
			-- Intersection with closest far face
			-- falls after the origin.
			and (max >= 0)
			-- luacheck: push ignore 581
			and not (max <= min) then
			-- luacheck: pop
			return false
		end
	end
	return true
end

local line_of_sight_scratch = vector.zero ()

local function mod (x)
	return x - math.floor (x)
end

local scale_poses_scratch = vector.zero ()
local scale_poses_scratch_1 = vector.zero ()

local function scale_poses (pos1, pos2)
	local v1, v2 = scale_poses_scratch, scale_poses_scratch_1
	v1.x = pos1.x + 1.0e-7
	v1.y = pos1.y + 1.0e-7
	v1.z = pos1.z + 1.0e-7
	v2.x = pos2.x + -1.0e-7
	v2.y = pos2.y + -1.0e-7
	v2.z = pos2.z + -1.0e-7
	return v1, v2
end

function mob_class:line_of_sight (pos1, pos2, typetest)
	-- Move pos1 and pos2 by minuscule values to avoid generating
	-- Inf or NaN.
	pos1, pos2 = scale_poses (pos1, pos2)
	local traveledx = mod (pos1.x + 0.5)
	local traveledy = mod (pos1.y + 0.5)
	local traveledz = mod (pos1.z + 0.5)
	local x = math.floor (pos1.x + 0.5)
	local y = math.floor (pos1.y + 0.5)
	local z = math.floor (pos1.z + 0.5)
	local dx, dy, dz = pos2.x - pos1.x, pos2.y - pos1.y, pos2.z - pos1.z
	local sx, sy, sz = signum (dx), signum (dy), signum (dz)
	local stepx, stepy, stepz = sx / dx, sy / dy, sz / dz
	local direction = vector.direction (pos1, pos2)
	local distance = vector.distance (pos1, pos2)

	-- Precompute reciprocal.
	direction.x = 1.0 / direction.x
	direction.y = 1.0 / direction.y
	direction.z = 1.0 / direction.z

	if sx == 0 then
		traveledx = 1.0
	elseif sx > 0 then
		traveledx = stepx * (1.0 - traveledx)
	else
		traveledx = stepx * (traveledx)
	end
	if sy == 0 then
		traveledy = 1.0
	elseif sy > 0 then
		traveledy = stepy * (1.0 - traveledy)
	else
		traveledy = stepy * (traveledy)
	end
	if sz == 0 then
		traveledz = 1.0
	elseif sz > 0 then
		traveledz = stepz * (1.0 - traveledz)
	else
		traveledz = stepz * (traveledz)
	end

	local v = line_of_sight_scratch
	v.x = x
	v.y = y
	v.z = z
	if not aabb_clear (v, pos1, pos2, direction, distance, typetest) then
		return false
	end

	while (traveledx <= 1.0)
		or (traveledy <= 1.0)
		or (traveledz <= 1.0) do
		if traveledx < traveledy then
			if traveledx < traveledz then
				x = x + sx
				traveledx = traveledx + stepx
			else
				z = z + sz
				traveledz = traveledz + stepz
			end
		else
			if traveledy < traveledz then
				y = y + sy
				traveledy = traveledy + stepy
			else
				z = z + sz
				traveledz = traveledz + stepz
			end
		end

		v.x = x
		v.y = y
		v.z = z

		if not aabb_clear (v, pos1, pos2, direction, distance) then
			return false
		end
	end

	return true
end

function mob_class:can_jump_cliff()
	local pos = self.object:get_pos()

	--is there nothing under the block in front? if so jump the gap.
	local dir_x, dir_z = self:forward_directions()
	local pos_low = vector.offset(pos, dir_x, -0.5, dir_z)
	local pos_far = vector.offset(pos, dir_x * 2, -0.5, dir_z * 2)
	local pos_far2 = vector.offset(pos, dir_x * 3, -0.5, dir_z * 3)

	local nodLow = mcl_mobs.node_ok(pos_low, "air")
	local nodFar = mcl_mobs.node_ok(pos_far, "air")
	local nodFar2 = mcl_mobs.node_ok(pos_far2, "air")

	if minetest.registered_nodes[nodLow.name]
	and minetest.registered_nodes[nodLow.name].walkable ~= true


	and (minetest.registered_nodes[nodFar.name]
	and minetest.registered_nodes[nodFar.name].walkable == true

	or minetest.registered_nodes[nodFar2.name]
	and minetest.registered_nodes[nodFar2.name].walkable == true)

	then
		--disable fear heigh while we make our jump
		self._jumping_cliff = true
		minetest.after(1, function()
			if self and self.object then
				self._jumping_cliff = false
			end
		end)
		return true
	else
		return false
	end
end

function mob_class:check_jump (self_pos, moveresult)
	local max_y = nil
	local dir = vector.zero ()

	-- Read the height of every colliding node in moveresult,
	-- and the node above.
	for _, item in ipairs (moveresult.collisions) do
		if item.type == "node"
			and (item.new_velocity.x ~= item.old_velocity.x
			     or item.new_velocity.z ~= item.old_velocity.z) then
			dir.x = dir.x + item.old_velocity.x - item.new_velocity.x
			dir.z = dir.z + item.old_velocity.z - item.new_velocity.z
			local pos = item.node_pos
			local boxes = minetest.get_node_boxes ("collision_box", pos)
			if pos.y > self_pos.y then
				for _, box in ipairs (boxes) do
					max_y = math.max (max_y or 0, pos.y + box[2], pos.y + box[5])
				end
			end
		end
	end


	if max_y and (max_y > self_pos.y)
		and (max_y - self_pos.y > self._initial_step_height) then
		-- Verify that the direction of the collision measured as a
		-- force substantially matches the direction of movement.
		dir = vector.normalize (dir)
		local yaw = self.object:get_yaw () + self.rotate
		local d = math.atan2 (dir.z, dir.x) - math.pi / 2
		local diff = math.atan2 (math.sin (d - yaw), math.cos (yaw - d))
		return math.abs (diff) < math.rad (40) -- ~40 deg.
	end
end

local function in_list(list, what)
	return type(list) == "table" and table.indexof(list, what) ~= -1
end

-- should mob follow what I'm holding ?
function mob_class:follow_holding(clicker)
	local item = clicker:get_wielded_item()
	if in_list(self.follow, item:get_name()) then
		return true
	end
	return false
end


-- find and replace what mob is looking for (grass, wheat etc.)
function mob_class:replace(pos)
	if not self.replace_rate
	or not self.replace_what
	or self.child == true
	or self.object:get_velocity().y ~= 0
	or math.random(1, self.replace_rate) > 1 then
		return
	end

	local what, with, y_offset

	if type(self.replace_what[1]) == "table" then
		local num = math.random(#self.replace_what)

		what = self.replace_what[num][1] or ""
		with = self.replace_what[num][2] or ""
		y_offset = self.replace_what[num][3] or 0
	else
		what = self.replace_what
		with = self.replace_with or ""
		y_offset = self.replace_offset or 0
	end

	pos.y = pos.y + y_offset

	local node = minetest.get_node(pos)
	if node.name == what then
		local oldnode = {name = what, param2 = node.param2}
		local newnode = {name = with, param2 = node.param2}
		local on_replace_return = false
		if self.on_replace then
			on_replace_return = self.on_replace(self, pos, oldnode, newnode)
		end

		if on_replace_return ~= false then
			if mobs_griefing then
				minetest.after(self.replace_delay, function()
					if self and self.object and self.object:get_velocity() and self.health > 0 then
						minetest.set_node(pos, newnode)
					end
				end)
			end
		end
	end
end

local function norm_radians (x)
	local x = x % (math.pi * 2)
	if x >= math.pi then
		x = x - math.pi * 2
	end
	if x < -math.pi then
		x = x + math.pi * 2
	end
	return x
end

local function clip_rotation (from, to, limit)
	local difference = norm_radians (to - from)
	if difference > limit then
		difference = limit
	end
	if difference < -limit then
		difference = -limit
	end
	return from + difference
end

function mob_class:look_at (b, clip_to)
	local s = self.object:get_pos()
	local yaw = (math.atan2 (b.z - s.z, b.x - s.x) - math.pi / 2) - self.rotate
	if clip_to then
		local old_yaw = self.object:get_yaw ()
		local x = clip_rotation (old_yaw, yaw, clip_to)
		yaw = x
	end
	self.object:set_yaw (yaw)
end

function mob_class:go_to_pos (b, velocity, animation)
	self.movement_goal = "go_pos"
	self.movement_target = b
	self.movement_velocity = velocity or self.movement_speed
	self:set_animation (animation or "walk")
end

function mob_class:teleport(target)
	if self.do_teleport then
		if self.do_teleport(self, target) == false then
			return
		end
	end
end

function mob_class:check_smooth_rotation(dtime)
	-- smooth rotation by ThomasMonroe314
	if self.delay and self.delay > 0 then
		local yaw = self.object:get_yaw() or 0
		if self.delay == 1 then
			yaw = self.target_yaw
		else
			local dif = math.abs(yaw - self.target_yaw)
			if yaw > self.target_yaw then
				if dif > math.pi then
					dif = 2 * math.pi - dif -- need to add
					yaw = yaw + dif / self.delay
				else
					yaw = yaw - dif / self.delay -- need to subtract
				end
			elseif yaw < self.target_yaw then
				if dif >math.pi then
					dif = 2 * math.pi - dif
					yaw = yaw - dif / self.delay -- need to subtract
				else
					yaw = yaw + dif / self.delay -- need to add
				end
			end
			if yaw > (math.pi * 2) then yaw = yaw - (math.pi * 2) end
			if yaw < 0 then yaw = yaw + (math.pi * 2) end
		end
		self.delay = self.delay - 1
		if self.shaking then
			yaw = yaw + (math.random() * 2 - 1) * 5 * dtime
		end
		self.object:set_yaw(yaw)
	end
	-- end rotation
end

--- Movement mechanics for flying/swimming/landed mobs.

function mob_class:do_go_pos (dtime, moveresult)
	local target = self.movement_target or vector.zero ()
	local vel = self.movement_velocity
	local pos = self.object:get_pos ()
	local dist = vector.distance (pos, target)

	if dist < 0.0005 then
		self.acc_dir.z = 0
		return
	end

	self:look_at (target, math.pi / 2 * (dtime / 0.05))
	self:set_velocity (vel)

	local node_surface = pos.y
	local target_node_surface = math.floor (target.y + 0.5) - 0.5

	if self:check_jump (pos, moveresult) then
		if self.should_jump and self.should_jump > 2
		-- Be more eager to jump if it is really certain that
		-- this mob expects to do so.
			or target_node_surface - node_surface >= 0.98 then
			self._jump = true
			self.movement_goal = "jump"
			self.should_jump = 0
		else
			-- Jump again if the collision remains after
			-- the next step.
			local i = self.should_jump or 0
			self.should_jump = i + 1
		end
		return
	end
end

function mob_class:do_jump_goal (dtime, moveresult)
	local vel = self.movement_velocity

	-- Continue accelerating until contact is made with the
	-- ground, but do not rotate while jumping.
	self:set_velocity (vel)

	if not self._jump
		and (moveresult.touching_ground or moveresult.standing_on_object) then
		self.movement_goal = nil
	end
end

function mob_class:dolphin_do_go_pos (dtime, moveresult)
	local target = self.movement_target
	local pos = self.object:get_pos ()
	local dist = vector.distance (pos, target)

	local dx, dy, dz = target.x - pos.x,
		target.y - pos.y,
		target.z - pos.z
	local dir = math.atan2 (dz, dx) - math.pi / 2 - self.rotate
	local standin = minetest.registered_nodes[self.standing_in]
	local yaw = self.object:get_yaw ()
	local f = dtime / 0.05
	local target_yaw = clip_rotation (yaw, dir, self.max_yaw_movement * f)

	-- Orient the mob vertically.
	local speed = self.movement_velocity
	if standin.groups.water then
		local old_rot = self.object:get_rotation ()
		local xz_mag = math.sqrt (dx * dx + dz * dz)
		local des_pitch
		if xz_mag > 1.0e-5 or xz_mag < -1.0e-5 then
			local swim_max_pitch = self.swim_max_pitch
			local old_pitch = old_rot.x
			des_pitch = -math.atan2 (dy, xz_mag)

			if des_pitch > swim_max_pitch then
				des_pitch = self.swim_max_pitch
			elseif des_pitch < -swim_max_pitch then
				des_pitch = -self.swim_max_pitch
			end

			local target
			-- ~50 degrees.
			target = clip_rotation (old_pitch, des_pitch, 0.8727 * f)
			self.object:set_rotation ({
					x = target,
					y = target_yaw,
					z = 0,
			})
			des_pitch = target
		else
			-- Not moving horizontally.
			des_pitch = self.object:get_rotation ().x
		end
		self.acc_dir.z = math.cos (des_pitch) * speed / 20
		self.acc_dir.y = -math.sin (des_pitch) * speed / 20
		self.acc_speed = speed * self.swim_speed_factor
		self._acc_no_gravity = true
	else
		-- Fish cannot change their pitch outside a body of
		-- water.
		self.acc_dir.y = 0
		self.acc_dir.z = 0
		self._acc_no_gravity = false
		self.object:set_rotation (vector.new (0, target_yaw, 0))
	end
end

function mob_class:do_strafe (dtime, moveresult)
	local vel = self.movement_velocity
	local sx, sz = self.strafe_direction.x, self.strafe_direction.z
	local magnitude = sx * sx + sz * sz

	-- "Normalize" direction if greater than 1.
	if magnitude > 1 then
		vel = vel / magnitude
	end

	-- Don't jump off ledges or head into unwalkable nodes if
	-- strafing in reverse or to the sides.
	local node, est_delta
	local v = { x = sx * vel, y = 0, z = sz * vel, }
	est_delta = self:accelerate_relative (v, vel)
	node = vector.add (self.object:get_pos (),
			   -- Scale the delta to
			   -- reflect the quantity
			   -- of movement applied
			   -- in one Minecraft
			   -- tick.
			   est_delta * 0.05)
	node.x = math.floor (node.x + 0.5)
	node.y = math.floor (node.y + 0.5)
	node.z = math.floor (node.z + 0.5)

	if self:gwp_classify_for_movement (node) ~= "WALKABLE" then
		self.strafe_direction.x, sx = 0, 0
		self.strafe_direction.z, sz = 1, 1
	end

	-- Begin strafing.
	self.acc_speed = vel
	self.acc_dir.x = sx
	self.acc_dir.z = sz
end

function mob_class:halt_in_tracks (immediate)
	self.acc_dir.z = 0
	self.acc_dir.y = 0
	self.acc_dir.x = 0
	self.acc_speed = 0
	self._acc_movement_speed = 0
	self._acc_y_fixed = nil
	self.movement_goal = nil
	self._acc_no_gravity = false

	if self._current_animation == "walk"
		or self._current_animation == "run" then
		self:set_animation ("stand")
	end

	if immediate then
		self.object:set_acceleration (vector.new(0,0,0))
		self.object:set_velocity (vector.new(0,0,0))
	end
end

function mob_class:movement_step (dtime, moveresult)
	if self.dead then
		return
	end
	if self.movement_goal == nil then
		-- Arrest movement.
		self.acc_dir.z = 0
		self.acc_dir.y = 0
		self.acc_dir.x = 0
		self.acc_speed = 0
		return
	elseif self.movement_goal == "go_pos" then
		self:do_go_pos (dtime, moveresult)
	elseif self.movement_goal == "jump" then
		self:do_jump_goal (dtime, moveresult)
	elseif self.movement_goal == "strafe" then
		self:do_strafe (dtime, moveresult)
	end
end

--- Navigation state management.

function mob_class:is_navigating ()
	return self.waypoints or self.stupid_target
end

function mob_class:navigation_finished ()
	if self.waypoints or self.pathfinding_context then
		return false
	end
	if self.stupid_target then
		local v = self.object:get_pos ()
		local target = vector.new (self.stupid_target.x,
					   v.y, self.stupid_target.z)
		if vector.distance (v, target) > 0.5 then
			return false
		end
		self:cancel_navigation ()
	end
	return true
end

function mob_class:navigation_step (dtime, moveresult)
	if self.waypoints or self.pathfinding_context then
		self:next_waypoint (dtime)
	elseif self.stupid_target then
		self:go_to_pos (self.stupid_target, self.stupid_velocity)
	end
end

function mob_class:cancel_navigation ()
	self.pathfinding_context = nil
	self.waypoints = nil
	self.stupid_target = nil
	self.movement_goal = nil
end

function mob_class:go_to_stupidly (pos, velocity)
	self.stupid_target = pos
	self.stupid_velocity = velocity or self.movement_speed
end

--- Mob AI.

function mob_class:pacing_target (pos, width, height, groups)
	local aa = vector.new (pos.x - width, pos.y - height, pos.z - width)
	local bb = vector.new (pos.x + width, pos.y + height, pos.z + width)
	local nodes = minetest.find_nodes_in_area_under_air (aa, bb, groups)

	return #nodes >= 1 and nodes[math.random (#nodes)]
end

function mob_class:target_in_shade (pos, width, height)
	local groups = {"group:solid", "group:water"}
	local aa = vector.new (pos.x - width, pos.y - height, pos.z - width)
	local bb = vector.new (pos.x + width, pos.y + height, pos.z + width)
	local nodes = minetest.find_nodes_in_area_under_air (aa, bb, groups)

	-- Minecraft tries ten times every tick.
	if #nodes < 1 then
		return nil
	end

	local newnode = {}
	for i = 1, 10 do
		local node = nodes[math.random (#nodes)]
		newnode.x = node.x
		newnode.y = node.y + 1
		newnode.z = node.z
		local sunlight = minetest.get_natural_light (newnode, self.time_of_day)
		if sunlight < 12 then
			return newnode
		end
	end
	return nil
end

function mob_class:random_node_direction (limx, limy, direction, range)
	local input = math.atan2 (direction.z, direction.x) - math.pi/2
	local yaw = input + (2 * math.random () - 1.0) * range
	local xdist = math.sqrt (math.random () * 2) * limx
	local x, z = xdist * -math.sin (yaw), xdist * math.cos (yaw)
	local y = math.random (2 * limy + 1) - limy

	if math.abs (x) <= limx and math.abs (y) <= limx then
		return vector.new (math.floor (x),
					math.floor (y),
					math.floor (z))
	end
	return nil
end

function mob_class:target_away_from (pos, pursuer)
	local forward_dir = vector.subtract (pos, pursuer)
	for i = 1, 10 do
		local dir = self:random_node_direction (16, 7, forward_dir, math.pi / 2)
		if dir then
			local pos = vector.add (pos, dir)
			if self:gwp_classify_for_movement (pos) == "WALKABLE" then
				return pos
			end
		end
	end
end

local IDLE_TIME_MAX = 250

function mob_class:init_ai ()
	self.ai_idle_time = 2 + math.random (2)
	if self._active_activity then
		self[self._active_activity]  = nil
		self._active_activity = nil
	end
	self:cancel_navigation ()
	self:halt_in_tracks ()

	if self.swims then
		self:gwp_configure_aquatic_mob ()
		self:configure_aquatic_mob ()
	end
	if self.airborne then
		self:gwp_configure_airborne_mob ()
		self:configure_airborne_mob ()
	end
	-- Last mob to have attacked this mob within the past five
	-- seconds.
	self._recent_attacker = nil
	self._recent_attacker_age = 0
end

function mob_class:is_frightened (dtime)
	return self.passive and (mcl_burning.is_burning (self.object) or self.runaway_timer > 0)
end

function mob_class:ai_step (dtime)
	-- Number of seconds since mob was last punched.
	if self.runaway_timer > 0 then
		self.runaway_timer = self.runaway_timer - dtime
	end
	if self.follow_cooldown and self.follow_cooldown > 0 then
		self.follow_cooldown = self.follow_cooldown - dtime
	else
		self.follow_cooldown = nil
	end
	if self._recent_attacker then
		self._recent_attacker_age = self._recent_attacker_age + dtime
		if not self._recent_attacker:is_valid ()
			or self._recent_attacker_age > 5 then
			self._recent_attacker = nil
			self._recent_attacker_age = 0
		end
	end
	self:tick_breeding ()
end

function mob_class:check_avoid (self_pos)
	local runaway_from = self.runaway_from
	if not runaway_from then
		return false
	end

	if self.avoiding then
		if self:navigation_finished () then
			self.avoiding = nil
		elseif not self.avoiding:is_valid () then
			self.avoiding = nil
			self:cancel_navigation ()
			self:halt_in_tracks ()
		else
			local avoid_pos = self.avoiding:get_pos ()
			local distance = vector.distance (self_pos, avoid_pos)
			if distance < 7.0 then
				self.gowp_velocity
					= self.movement_speed * self.runaway_bonus_near
			else
				self.gowp_velocity
					= self.movement_speed * self.runaway_bonus_far
			end
		end
		return true
	else
		-- Search for nearby mobs to avoid.
		local target, max_distance, target_pos
		local range = self.runaway_view_range
		local objects
			= minetest.get_objects_inside_radius (self_pos, range)
		local runaway_from_players
			= table.indexof (runaway_from, "players") ~= -1
		for _, object in ipairs (objects) do
			local entity = object:get_luaentity ()
			local eligible = false
			if entity
				and table.indexof (runaway_from, entity.name) ~= -1
				and self:target_visible (self_pos, object) then
				eligible = true
			elseif object:is_player ()
				and runaway_from_players
				and not minetest.is_creative_enabled (object:get_player_name ())
				and self:target_visible (self_pos, object) then
				eligible = true
			end
			if eligible then
				local pos = object:get_pos ()
				local distance = vector.distance (self_pos, pos)
				if not max_distance or distance < max_distance then
					target = object
					target_pos = pos
					max_distance = distance
				end
			end
		end
		if target then
			local pos = self:target_away_from (self_pos, target_pos)
			if pos and vector.distance (pos, target_pos) > max_distance then
				local initial_velocity
					= self.movement_speed * self.runaway_bonus_near
				self:gopath (pos, nil, false, initial_velocity)
				self.avoiding = target
				return "avoiding"
			end
		end
	end
	return false
end

function mob_class:check_following (self_pos, dtime)
	if self.following then
		-- Can this mob continue to follow its target?
		local pos = self.following:get_pos ()
		if not pos then
			self.following = nil
			self.follow_cooldown = 4
			self:halt_in_tracks ()
			self:set_animation ("stand")
		else
			local distance = vector.distance (self_pos, pos)
			if not self:follow_holding (self.following) then
				distance = nil
			end
			if not distance or distance > self.follow_distance
				or distance <= self.stop_distance then
				self:halt_in_tracks ()
				self:set_animation ("stand")
				if not distance or distance > self.follow_distance then
					self.following = nil
					self.follow_cooldown = 4
				end
			end
		end
		if self.following then
			-- check_head_swivel is responsible for
			-- looking at the target.
			self:go_to_stupidly (pos)
		end
		return true
	elseif self.follow and not self.follow_cooldown then
		for player in mcl_util.connected_players () do
			local distance = vector.distance (player:get_pos (), self_pos)
			if distance < self.follow_distance
				and distance > self.stop_distance and self:follow_holding (player) then
				self.following = player
				return "following"
			end
		end
	end
	return false
end

function mob_class:check_avoid_sunlight (pos)
	if self.avoiding_sunlight then
		-- Still seeking sunlight?
		if self:navigation_finished () then
			self.avoiding_sunlight = false
			self:set_animation ("stand")
		end
		return true
	elseif self.avoids_sunlight
		and (self.time_of_day > 0.2 and self.time_of_day < 0.8)
		and self.sunlight > 12
		and mcl_burning.is_burning (self.object) then
		local tpos = self:target_in_shade (pos, 10, 3)

		if tpos then
			self:gopath (tpos, nil, true,
				     self.movement_speed * self.run_bonus)
			self.avoiding_sunlight = true
			return "avoiding_sunlight"
		end
	end
	return false
end

function mob_class:check_frightened (pos)
	if self.frightened then
		-- Still frightened?
		if self:navigation_finished () then
			self.frightened = false
			self:set_animation ("stand")
		end
		return true
	else
		if self:is_frightened () then
			-- If this mob is burning, search for water.
			local tpos

			if mcl_burning.is_burning (self.object) then
				tpos = self:pacing_target (pos, 5, 4, {"group:water"})
			end
			if not tpos then
				tpos = self:pacing_target (pos, 5, 4, {"group:solid"})
			end
			if tpos then
				self:gopath (tpos, nil, true,
					     self.movement_speed * self.run_bonus)
				self.frightened = true
				return "frightened"
			end
		end
	end

	return false
end

function mob_class:check_pace (pos)
	if self.pacing then
		-- Still pacing?
		if self:navigation_finished () then
			self.pacing = false
			self:set_animation ("stand")
		end
		return true
	else
		-- Should pace?
		if self.ai_idle_time > self.pace_interval then
			-- Minecraft mobs pace to random positions
			-- within a 20 block distance lengthwise and
			-- 14 blocks vertically.
			local groups = {"group:solid"}
			if self.swims_in and self.swims then
				-- If this is an aquatic mob, search
				-- for nodes in which it is capable of
				-- swimming.
				groups = self.swims_in
			end
			local width, height = self.pace_width, self.pace_height
			local target = self:pacing_target (pos, width, height, groups)
			local speed = self.movement_speed * self.pace_bonus
			if target and self:gopath (target, nil, false, speed) then
				self.pacing = true
				return "pacing"
			end
		end
		return false
	end
end

function mob_class:replace_activity (activity_name)
	if self._active_activity then
		self[self._active_activity] = nil
	end
	self._active_activity = activity_name
end

function mob_class:run_ai (dtime, moveresult)
	local pos = self.object:get_pos ()

	if self.dead then
		self:halt_in_tracks ()
		return
	end
	self._moveresult = moveresult

	local active = nil
	for _, fn in ipairs (self.ai_functions) do
		active = fn (self, pos, dtime)

		if active then
			if active ~= true then
				local current = self._active_activity
				-- Cancel the current activity.
				if current and current ~= active then
					self[current] = nil
				end
				self._active_activity = active
			end
			break
		end
	end

	if active then
		self.ai_idle_time = 0
	elseif self.ai_idle_time < IDLE_TIME_MAX then
		self:set_animation ("stand")
		self._active_activity = nil
		self.ai_idle_time = self.ai_idle_time + dtime
		self:cancel_navigation ()
		self:halt_in_tracks ()
	end
end

------------------------------------------------------------------------
-- Aquatic mob behavior.
------------------------------------------------------------------------

local function aquatic_pacing_target (self, pos, width, height, groups)
	local aa = vector.new (pos.x - width, pos.y - height, pos.z - width)
	local bb = vector.new (pos.x + width, pos.y + height, pos.z + width)
	local nodes = minetest.find_nodes_in_area (aa, bb, groups)

	return #nodes >= 1 and nodes[math.random (#nodes)]
end

local function aquatic_movement_step (self, dtime, moveresult)
	if self.movement_goal ~= "go_pos"
		and self.idle_gravity_in_liquids then
		self._acc_no_gravity = false
	end
	if not self.idle_gravity_in_liquids and self._immersion_depth then
		self._acc_no_gravity
			= self._immersion_depth >= self.head_eye_height
	end
	if self.flops and self._immersion_depth and self._immersion_depth <= 0 then
		local touching_ground
		touching_ground = moveresult.touching_ground
			or moveresult.standing_on_object
		if touching_ground then
			local flop_velocity = {
				x = (math.random () - 0.5) * 2,
				y = 8.0,
				z = (math.random () - 0.5) * 2,
			}
			self.object:add_velocity (flop_velocity)
		end
	end
	self._acc_y_fixed = nil
	mob_class.movement_step (self, dtime, moveresult)
end

function mob_class:fish_do_go_pos (dtime, moveresult)
	local target = self.movement_target or vector.zero ()
	local vel = self.movement_velocity
	local self_pos = self.object:get_pos ()
	local dx, dy, dz = target.x - self_pos.x,
		target.y - self_pos.y,
		target.z - self_pos.z
	local current_speed = self._acc_movement_speed or 0
	current_speed = (vel - current_speed) * 0.125 + current_speed
	local move_speed = 0.4

	self._acc_movement_speed = current_speed
	self.acc_speed = move_speed
	self.acc_dir.z = current_speed / 20
	if dy ~= 0 then
		local dxyz = math.sqrt (dx * dx + dy * dy + dz * dz)
		local t2 = current_speed * (dy / dxyz) * 0.1
		self._acc_y_fixed = t2
	end
	local dir = math.atan2 (dz, dx) - math.pi / 2
	local rotation = clip_rotation (self.object:get_yaw (), dir,
					(math.pi / 2) * dtime / 0.05)
	self.object:set_yaw (rotation)
end

function mob_class.school_init_group (list)
	-- Designate one of the school's fish as its leader.
	local leader = list[math.random (#list)]
	local entity = leader:get_luaentity ()

	entity._school = {}
	entity._desired_school_size = #list - 1
	for _, item in pairs (list) do
		if item ~= leader then
			local mob = item:get_luaentity ()
			table.insert (entity._school, list)
			mob._leader = leader
			mob:replace_activity ("_leader")
		end
	end
end

local function find_school_leader (list, species, cluster)
	for _, mob in pairs (list) do
		local entity = mob:get_luaentity ()
		if entity and entity.name == species
			and entity._school
			and #entity._school > 1
			and #entity._school < cluster then
			return entity
		end
	end
end

function mob_class:check_schooling (self_pos, list)
	if self._leader then
		if not self._leader:is_valid () then
			self._leader = nil
			return false
		end
		local leader_pos = self._leader:get_pos ()
		if vector.distance (leader_pos, self_pos) > 11.0 then
			local luaentity = self._leader:get_luaentity ()
			local index = table.indexof (luaentity._school, self.object)
			assert (index >= 1)
			table.remove (luaentity._school, index)
			self._leader = nil
			return false
		end

		if self:check_timer ("school_pathfind", 0.5) then
			self:gopath (leader_pos, nil, false, nil, nil, 3)
		end
		return true
	elseif self._school and #self._school > 0 then
		-- This fish already leads a school.  Remove invalid
		-- entries from its list of members.
		local cleaned = {}
		for _, follower in pairs (self._school) do
			if follower:is_valid () then
				table.insert (cleaned, follower)
			end
		end
		self._school = cleaned
		return false
	elseif self:check_timer ("form_school", (200 + math.random (20)) / 40) then
		local nearby = minetest.get_objects_inside_radius (self_pos, 8)
		local cluster = self._school_size or self.spawn_in_group or 4
		local leader = find_school_leader (nearby, self.name, cluster) or self
		leader._school = leader._school or {}

		-- Assign nearby unassigned mobs other than the
		-- selected leader to its school.
		for _, mob in pairs (nearby) do
			local entity = mob:get_luaentity ()
			if entity
				and entity.object ~= leader.object
				and entity.name == self.name
				and (not entity._school or #entity._school == 0)
				and (not entity._leader) then
				entity._leader = leader.object
				entity:replace_activity ("_leader")
				table.insert (leader._school, mob)
			end
		end

		-- Was this mob assigned to a leader, or has it gained
		-- a school?
		if self._school and #self._school > 0 then
			return false
		end
		if self._leader then
			return "_leader"
		end
		return false
	end
end

function mob_class:configure_aquatic_mob ()
	self.pacing_target = aquatic_pacing_target
	self.motion_step = self.aquatic_step
	self.movement_step = aquatic_movement_step
	self._acc_no_gravity = false
end

------------------------------------------------------------------------
-- Flying mob behavior.  This only applies to mobs that are truly
-- adapted to flight in all respects, which excludes bats, whose
-- flight is implemented in their AI loop, or ghasts, which do not
-- pathfind.
------------------------------------------------------------------------

function mob_class:airborne_do_go_pos (dtime, moveresult)
	local target = self.movement_target or vector.zero ()
	local vel = self.movement_velocity
	local self_pos = self.object:get_pos ()
	local dx, dy, dz = target.x - self_pos.x,
		target.y - self_pos.y,
		target.z - self_pos.z
	local touching_ground = moveresult.touching_ground
		or moveresult.standing_on_object

	-- Replace movement_speed with airborne_speed if airborne.
	if not touching_ground then
		vel = vel / self.movement_speed * self.airborne_speed
		self:set_animation ("fly")
	else
		self:set_animation ("run")
	end

	local yaw = math.atan2 (dz, dx) - math.pi / 2
	local old_yaw = self.object:get_yaw ()
	local clipped = clip_rotation (old_yaw, yaw, (math.pi / 2) * dtime / 0.05)

	self.object:set_yaw (clipped)
	self:set_velocity (vel)

	local xz_magnitude = math.sqrt (dx * dx + dz * dz)
	if math.abs (dy) > 1.0e-5 or math.abs (xz_magnitude) > 1.0e-5 then
		-- Vertical acceleration is not adjusted by the pitch
		-- in order to simulate real world flight.
		self.acc_dir.y = dy > 0.0 and vel / 20 or -vel / 20
	end
	self._acc_no_gravity = true
end

local function airborne_movement_step (self, dtime, moveresult)
	if self.dead then
		return
	end
	if self.movement_goal == nil then
		-- Arrest movement.
		self.acc_dir.z = 0
		self.acc_dir.y = 0
		self.acc_dir.x = 0
		self.acc_speed = 0
		if not self._hovers then
			self._acc_no_gravity = false
		end
		return
	elseif self.movement_goal == "go_pos" then
		self:do_go_pos (dtime, moveresult)
	end
end

local function airborne_pacing_target (self, pos, width, height, groups)
	return self:airborne_pacing_target (pos, width, height, groups)
end

function mob_class:airborne_pacing_target (pos, width, height, groups)
	-- First, generate a position within 90 degrees of this mob's
	-- current direction of sight.
	local dir = self.object:get_yaw ()
	dir = { x = -math.sin (dir), z = math.cos (dir), }
	local node_pos = vector.copy (pos)
	node_pos.x = math.floor (node_pos.x + 0.5)
	node_pos.y = math.floor (node_pos.y + 0.5)
	node_pos.z = math.floor (node_pos.z + 0.5)
	for i = 1, 10 do
		local node = self:random_node_direction (width, height, dir, math.pi / 20)
		if node then
			local target = node_pos + node
			local class = self:gwp_classify_for_movement (target)

			-- Is this node walkable?
			if class == "WALKABLE" then
				-- Move an arbitrary number of blocks
				-- into the air above this node.
				local n = math.random (3)
				repeat
					target.y = target.y + 1
					if self:gwp_classify_for_movement (target) ~= "OPEN" then
						target.y = target.y - 1
						break
					end
					n = n - 1
				until n < 1
				return target
			end
		end
	end
end

function mob_class:configure_airborne_mob ()
	self.movement_step = airborne_movement_step
	self.do_go_pos = mob_class.airborne_do_go_pos
	self.pacing_target = airborne_pacing_target
end
