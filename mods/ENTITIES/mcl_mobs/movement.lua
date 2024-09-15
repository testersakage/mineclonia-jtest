local mob_class = mcl_mobs.mob_class
local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false

local atann = math.atan
local function atan(x)
	if not x or x ~= x then
		return 0
	else
		return atann(x)
	end
end

-- Returns true is node can deal damage to self
function mob_class:is_node_dangerous(nodename)
	local nn = nodename
	if self.lava_damage > 0 then
		if minetest.get_item_group(nn, "lava") ~= 0 then
			return true
		end
	end
	if self.fire_damage > 0 then
		if minetest.get_item_group(nn, "fire") ~= 0 then
			return true
		end
	end
	if minetest.registered_nodes[nn] and minetest.registered_nodes[nn].damage_per_second and minetest.registered_nodes[nn].damage_per_second > 0 then
		return true
	end
	return false
end

-- Returns true if node is a water hazard to this mob
function mob_class:is_node_waterhazard(nodename)
	if self.swims or self.breathes_in_water or self.object:get_properties().breath_max == -1 then
		return false
	end

	if self.water_damage > 0 then
		if minetest.get_item_group(nodename, "water") ~= 0 then
			return true
		end
	end

	if
		minetest.registered_nodes[nodename]
		and minetest.registered_nodes[nodename].drowning
		and minetest.registered_nodes[nodename].drowning > 0
		and minetest.get_item_group(nodename, "water") ~= 0
	then
		return true
	end

	return false
end

function mob_class:target_visible(origin, target)
	if not origin then return end

	if not target and self.attack then
		target = self.attack
	end
	if not target then return end

	local target_pos = target:get_pos()
	if not target_pos then return end

	local origin_eye_pos = vector.offset(origin, 0, self.head_eye_height, 0)

	local targ_head_height, targ_feet_height
	local cbox = self.object:get_properties().collisionbox
	if target:is_player () then
		targ_head_height = vector.offset(target_pos, 0, cbox[5], 0)
		targ_feet_height = target_pos -- Cbox would put feet under ground which interferes with ray
	else
		targ_head_height = vector.offset(target_pos, 0, cbox[5], 0)
		targ_feet_height = vector.offset(target_pos, 0, cbox[2], 0)
	end

	if self:line_of_sight(origin_eye_pos, targ_head_height) then
		return true
	end

	if self:line_of_sight(origin_eye_pos, targ_feet_height) then
		return true
	end

	-- TODO mid way between feet and head

	return false
end

-- check line of sight (BrunoMine)
function mob_class:line_of_sight(pos1, pos2, stepsize)
	stepsize = stepsize or 1
	local s, _ = minetest.line_of_sight(pos1, pos2, stepsize)

	-- normal walking and flying mobs can see you through air
	if s then return true end

	-- New pos1 to be analyzed
	local npos1 = vector.copy(pos1)
	local r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

	if r == true then return true end
	local nn = minetest.get_node(pos).name
	local td = vector.distance(pos1, pos2)
	local ad = 0

	-- It continues to advance in the line of sight in search of a real
	-- obstruction which counts as 'normal' nodebox.
	while minetest.registered_nodes[nn]
	and minetest.registered_nodes[nn].walkable == false do

		-- Check if you can still move forward
		if td < ad + stepsize then
			return true -- Reached the target
		end

		-- Moves the analyzed pos
		local d = vector.distance(pos1, pos2)

		npos1.x = ((pos2.x - pos1.x) / d * stepsize) + pos1.x
		npos1.y = ((pos2.y - pos1.y) / d * stepsize) + pos1.y
		npos1.z = ((pos2.z - pos1.z) / d * stepsize) + pos1.z

		-- NaN checks
		if d == 0
		or npos1.x ~= npos1.x
		or npos1.y ~= npos1.y
		or npos1.z ~= npos1.z then
			return false
		end

		ad = ad + stepsize

		-- scan again
		r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

		if r == true then return true end
		-- New Nodename found
		nn = minetest.get_node(pos).name
	end

	return false
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

-- is mob facing a cliff or danger
function mob_class:is_at_cliff_or_danger()
	if self.fear_height == 0 or self._jumping_cliff or not self.object:get_luaentity() then -- 0 for no falling protection!
		return false
	end

	local cbox = self.object:get_properties().collisionbox
	local dir_x, dir_z = self:forward_directions()
	local pos = self.object:get_pos()

	local free_fall, blocker = minetest.line_of_sight(
		vector.offset(pos, dir_x, cbox[2], dir_z),
		vector.offset(pos, dir_x, -self.fear_height, dir_z))

	if free_fall then
		return true
	else
		local bnode = minetest.get_node(blocker)
		local danger = self:is_node_dangerous(bnode.name)
		if danger then
			return true
		else
			local def = minetest.registered_nodes[bnode.name]
			if def and def.walkable then
				return false
			end
		end
	end

	return false
end

function mob_class:is_at_water_danger()
	if self._jumping_cliff or self.swims or self.fly or self.object:get_properties().breath_max == -1 then
		return false
	end

	local cbox = self.object:get_properties().collisionbox
	local pos = self.object:get_pos()
	local infront = self:node_infront_ok(pos, -1)
	local height = cbox[5] - cbox[2]

	if self:is_node_waterhazard(infront.name) then
		-- if short then mob can drown in a single node
		if height <= 1.0 then
			return true
		else
			-- else it's only dangerous if two nodes deep
			local below_infront = self:node_infront_ok(pos, -2)
			if self:is_node_waterhazard(below_infront.name) then
				return true
			end
		end
	end

	return false
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
		and (max_y - self_pos.y > self.object:get_properties ().stepheight) then
		-- Verify that the direction of the collision measured as a
		-- force substantially matches the direction of movement.
		dir = vector.normalize (dir)
		local yaw = self.object:get_yaw () + self.rotate
		local d = math.atan2 (dir.z, dir.x) - math.pi / 2
		local diff = math.atan2 (math.sin (d - yaw), math.cos (yaw - d))
		return math.abs (diff) < 0.2617 -- ~15 deg.
	end
end

local function in_list(list, what)
	return type(list) == "table" and table.indexof(list, what) ~= -1
end

function mob_class:is_object_in_view(object_list, object_range, node_range, turn_around)
	local s = self.object:get_pos()
	local min_dist = object_range + 1
	local object_pos
	for object in minetest.objects_inside_radius(s, object_range) do
		local name = ""
		if object:is_player() then
			if not (mcl_mobs.invis[ object:get_player_name() ]
			or self.owner == object:get_player_name()
			or (not self:object_in_range(object))) then
				name = "player"
				if not (name ~= self.name
				and in_list(object_list, name)) then
					local item = object:get_wielded_item()
					name = item:get_name() or ""
				end
			end
		else
			local ent = object:get_luaentity()

			if ent then
				object = ent.object
				name = ent.name or ""
			end
		end

		-- find specific mob to avoid or runaway from
		if name ~= "" and name ~= self.name
		and in_list(object_list, name) then

			local p = object:get_pos()
			local dist = vector.distance(p, s)

			-- choose closest player/mob to avoid or runaway from
			if dist < min_dist
			-- aim higher to make looking up hills more realistic
			and self:line_of_sight(vector.offset(s, 0,1,0), vector.offset(p, 0,1,0)) == true then
				min_dist = dist
				object_pos = p
			end
		end
	end

	if not object_pos then
		-- find specific node to avoid or runaway from
		local p = minetest.find_node_near(s, node_range, object_list, true)
		local dist = p and vector.distance(p, s)
		if dist and dist < min_dist
		and self:line_of_sight(s, p) == true then
			object_pos = p
		end
	end

	if object_pos and turn_around then

		local vec = vector.subtract(object_pos, s)
		local yaw = (atan(vec.z / vec.x) + 3 *math.pi/ 2) - self.rotate
		if object_pos.x > s.x then yaw = yaw + math.pi end

		self:set_yaw(yaw, 4)
	end
	return object_pos ~= nil
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

function mob_class:look_at(b)
	local s=self.object:get_pos()
	local v = { x = b.x - s.x, z = b.z - s.z }
	local yaw = (atann(v.z / v.x) +math.pi/ 2) - self.rotate
	if b.x > s.x then yaw = yaw +math.pi end
	self.object:set_yaw(yaw)
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
	if self._turn_to and self.order ~= "sleep" then
		self:set_yaw( self._turn_to, .1)
	end
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

	if dist < 0.5 then
		return
	end

	self:look_at (target)
	self:set_velocity (vel)

	-- Jump if the mob is obstructed.
	if self:check_jump (pos, moveresult) then
		self.order = "jump"
		return
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
	local node, def, est_delta
	local v = { x = sx * vel, y = 0, z = sz * vel, }
	est_delta = self:accelerate_relative (v, vel)
	est_delta.y = -0.25
	node = minetest.get_node (vector.add (self.object:get_pos (), est_delta))
	def = minetest.registered_nodes[node.name]
	if def and not def.walkable then
		sx = 0
		sz = 1
	end

	-- Begin strafing.
	self.acc_speed = vel
	self.acc_dir.x = sx
	self.acc_dir.z = sz
end

function mob_class:do_fly_pos (dtime, moveresult)
end

function mob_class:do_swim_pos (dtime, moveresult)
end

function mob_class:halt_in_tracks (immediate)
	self.acc_dir.z = 0
	self.acc_dir.y = 0
	self.acc_dir.x = 0
	self.acc_speed = 0
	self.movement_goal = nil
	self:cancel_navigation ()

	if immediate then
		self.object:set_acceleration(vector.new(0,0,0))
		self.object:set_velocity(vector.new(0,0,0))
	end
end

function mob_class:movement_step (dtime, moveresult)
	if self.state == "die" then
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
	elseif self.movement_goal == "strafe" then
		self:do_strafe (dtime, moveresult)
	elseif self.movement_goal == "fly_pos" then
		self:do_fly_pos (dtime, moveresult)
	elseif self.movement_goal == "swim_pos" then
		self:do_swim_pos (dtime, moveresult)
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
		self:next_waypoint ()
	elseif self.stupid_target then
		self:go_to_pos (self.stupid_target, self.stupid_velocity)
	end
end

function mob_class:cancel_navigation ()
	self.pathfinding_context = nil
	self.waypoints = nil
	self.stupid_target = nil
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
	local i = 1
	while i <= 10 do
		i = i + 1

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

local IDLE_TIME_MAX = 250

function mob_class:init_ai ()
	self.ai_idle_time = 0
	self.avoiding_sunlight = nil
	self.attack = nil
	self.mate = nil
	self.following = nil
	self.herd_following = nil
	self.pacing = false
	self:cancel_navigation ()
	self:halt_in_tracks ()
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
	self:tick_breeding ()
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
			self:go_to_stupidly (pos, self.movement_speed * self.follow_bonus)
		end
		return true
	elseif self.follow and not self.follow_cooldown then
		for player in mcl_util.connected_players () do
			local distance = vector.distance (player:get_pos (), self_pos)
			if distance < self.follow_distance
				and distance > self.stop_distance and self:follow_holding (player) then
				self.following = player

				-- Interrupt other activities.
				self.herd_following = nil
				self.pacing = nil
				return true
			end
		end
	end
	return false
end

function mob_class:run_ai (dtime)
	local idle = true
	local pos = self.object:get_pos ()

	if self.dead then
		self:halt_in_tracks (true)
		return
	end

	if self.avoiding_sunlight then
		idle = false
		-- Still seeking sunlight?
		if self:navigation_finished () then
			self.avoiding_sunlight = false
			self:set_animation ("stand")
		end
	elseif idle and self.avoids_sunlight
		and (self.time_of_day > 0.2 and self.time_of_day < 0.8)
		and self.sunlight > 12
		and mcl_burning.is_burning (self.object) then
		local tpos = self:target_in_shade (pos, 10, 3)

		if tpos then
			self:gopath (tpos, nil, true,
				     self.movement_speed * self.run_bonus)
			self.avoiding_sunlight = true
			-- Interupt other activities.
			self.attack = nil
			self.mate = nil
			self.following = nil
			self.herd_following = nil
			self.pacing = false
			idle = false
		end
	end

	if self.attack_type and not self.avoiding_sunlight then
		idle = not self:check_attack (pos, dtime)
	end

	if self.frightened then
		idle = false
		-- Still frightened?
		if self:navigation_finished () then
			self.frightened = false
			self:set_animation ("stand")
		end
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
				self.frightened = true
				self:gopath (tpos, nil, true,
					     self.movement_speed * self.run_bonus)

				-- Interupt other activities.
				self.mate = nil
				self.following = nil
				self.herd_following = nil
				self.pacing = false
				idle = false
			end
		end
	end

	if idle	and (self:check_breeding (pos)
			or self:check_following (pos)
			or self:follow_herd (pos)) then
		idle = false
	end

	if self.pacing then
		idle = false
		-- Still pacing?
		if self:navigation_finished () then
			self.pacing = false
			self:set_animation ("stand")
		end
	else
		-- Should pace?
		if idle and self.ai_idle_time > 5 and math.random (120) == 1 then
			-- Minecraft mobs pace to random positions
			-- within a 20 block distance lengthwise and
			-- 14 blocks vertically.
			local target = self:pacing_target (pos, 10, 7, {"group:solid"})
			if target and self:gopath (target) then
				self.pacing = true
			end
			idle = false
		end
	end

	if not idle then
		self.ai_idle_time = 0
	elseif self.ai_idle_time < IDLE_TIME_MAX then
		self:set_animation ("stand")
		self.ai_idle_time = self.ai_idle_time + dtime
	end
end
