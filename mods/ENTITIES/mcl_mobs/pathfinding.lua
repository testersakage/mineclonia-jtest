local mob_class = mcl_mobs.mob_class

-- Extensible A* pathfinder.
--
-- Notably, it is capable of moving diagonally, assigning deterrence
-- values to blocks, navigating to multiple targets, and returning
-- incomplete paths.

function mob_class:new_gwp_context ()
	return {
		open_set = PriorityQueue.new ("min"),
		targets = {},
		arrivals = {},
		nodes = {},
		class_cache = {},
		ground_height_cache = {},
		tolerance = 1,
		time_elapsed = 0,
	}
end

local function hashpos (context, x, y, z)
	local x1, y1, z1
	x1 = x - context.minpos.x
	y1 = y - context.minpos.y
	z1 = z - context.minpos.z

	return x1 * 256*256 + y1 * 256 + z1
end

function mob_class:get_gwp_node (context, x, y, z, g, h)
	local hash = hashpos (context, x, y, z)
	if context.nodes[hash] then
		return context.nodes[hash]
	end
	local obj = {
		x = x, y = y, z = z,
		g = g, h = h, penalty = 0,
	}
	context.nodes[hash] = obj
	return obj
end

function mob_class:gwp_target_pos (context, pos)
	local n = mob_class:get_gwp_node (context, math.round (pos.x),
					  math.round (pos.y),
					  math.round (pos.z))
	-- 3d Manhattan distance of closest_node.
	n.closest = -1
	-- Visited node nearest to the target.
	n.closest_node = nil
	-- Class and penalty of this node.
	n.class = self:gwp_classify_node (context, n)
	n.penalty = self.gwp_penalties[n.class]
	return n
end

function mob_class:gwp_start ()
	-- If standing in water...
	local pos = self.object:get_pos ()
	pos.x = math.round (pos.x)
	pos.y = math.round (pos.y)
	pos.z = math.round (pos.z)
	local node = minetest.get_node (pos)
	local ground = minetest.get_node (vector.offset (pos, 0, -1, 0))

	if node.name == "mcl_core:water_source" then
		if self.floats == 0
			and ground == "mcl_core:water_source" then
			local nextnode = minetest.get_node (pos)
			-- Find the first liquid source block beneath
			-- a non-source block.
			while nextnode.name == "mcl_core:water_source" do
				pos.y = pos.y + 1
				nextnode = minetest.get_node (pos)
			end
			pos.y = pos.y - 1
			return pos
		end
	elseif ground ~= "ignore" and ground ~= "air" then
		return pos
	end
	local target_y = pos.y - 128

	while pos.y >= target_y do
		local node = minetest.get_node (pos)
		local def = minetest.registered_nodes[node.name]
		if def and def.walkable then
			pos.y = pos.y + 1
			return pos
		end
		pos.y = pos.y - 1
	end
	return nil
end

local function manhattan3d (ax, ay, az, bx, by, bz)
	return math.abs (ax - bx) + math.abs (az - bz) + math.abs (ay - by)
end

local function d (node1, node2)
	return vector.distance (node1, node2)
end

function mob_class:h_to_nearest_target (node, context)
	local best_distance
	for _, target in ipairs (context.targets) do
		local d = manhattan3d (node.x, node.y, node.z,
				       target.x, target.y, target.z)
		if not best_distance or d < best_distance then
			best_distance = d
		end

		-- Save the nearest node into the target for use in
		-- reconstruction of partial paths.
		if not target.best_distance or target.best_distance > d then
			target.best_distance = d
			target.best_node = node
		end
	end
	assert (best_distance)
	return best_distance
end

function mob_class:gwp_initialize (targets, range)
	local context = self:new_gwp_context ()

	-- Compute pathfinding bounds.
	local pos = vector.apply (self.object:get_pos (), math.round)
	-- This limit is decided by the values `hashpos' is capable of
	-- handling.
	range = range or self.follow_distance * 2
	context.range = math.min (range, 127)
	context.minpos = vector.new (pos.x - range, pos.y - range,
				     pos.z - range)
	context.maxpos = vector.new (pos.x + range, pos.y + range,
				     pos.z + range)

	-- Map target positions to acceptable nodes.
	for _, pos in ipairs (targets) do
		local t = self:gwp_target_pos (context, pos)
		if t then
			table.insert (context.targets, t)
		end
	end

	-- Derive a valid start position if suspended in water or the
	-- like.
	local start = self:gwp_start ()
	if not start or not vector.in_area (start, context.minpos,
					context.maxpos) then
		return nil
	end

	-- Construct initial open set and initialize context for first
	-- cycle.
	start.g = 0
	start.h = self:h_to_nearest_target (start, context)
	context.open_set:enqueue (start, start.h)
	context.stepheight = self.object:get_properties ().stepheight
	context.fall_distance = self:gwp_safe_fall_distance ()
	return context
end

function mob_class:gwp_safe_fall_distance ()
	if self.attack then
		return 6
	end
	return 3
end

function mob_class:gwp_cycle (context, timeout)
	local time = os.clock ()
	local set = context.open_set
	local clock
	context.stepheight = self.object:get_properties ().stepheight
	context.fall_distance = self:gwp_safe_fall_distance ()
	repeat
		if set:empty () then
			local time = os.clock () - time
			context.time_elapsed = context.time_elapsed + time
			return true, time
		end

		local node = set:dequeue ()
		node.covered = true

		-- Evaluate this node...does it arrive at any target?
		for _, target in ipairs (context.targets) do
			if manhattan3d (node.x, node.y, node.z,
					target.x, target.y, target.z)
				< context.tolerance then
				table.insert (context.arrivals, target)
			end
		end
		if #context.arrivals >= 1 then
			local time = os.clock () - time
			context.time_elapsed = context.time_elapsed + time
			return true, time
		end

		-- Enter each neighbor into the queue.
		local neighbors = self:gwp_edges (context, node)
		for _, neighbor in ipairs (neighbors) do
			-- What is the distance from hence to this
			-- neighbor?
			local dist = d (node, neighbor)
			if dist <= context.range then
				local new_g = node.g + dist + neighbor.penalty
				local new_h = self:h_to_nearest_target (neighbor, context) * 1.5 -- Minecraft value.
				if set:contains (neighbor) then
					-- Re-enqueue this neighbor if this
					-- path to it is shorter.
					if new_g < neighbor.g then
						neighbor.g = new_g
						neighbor.h = new_h
						neighbor.referrer = node
						set:update (neighbor, new_g + new_h)
					end
				else
					-- N.B. in this branch neighbor.g and
					-- .h might not yet have been
					-- computed.
					neighbor.g = new_g
					neighbor.h = new_h
					neighbor.referrer = node
					set:enqueue (neighbor, new_g + new_h)
				end
			end
		end
		clock = os.clock ()
	until clock - time >= timeout
	context.time_elapsed = context.time_elapsed + (clock - time)
	return false, clock - time
end

function mob_class:gwp_reconstruct_path (context, arrival)
	local list = {arrival}
	while arrival.referrer ~= nil do
		table.insert (list, arrival.referrer)
		arrival = arrival.referrer
	end
	return list
end

function mob_class:gwp_reconstruct (context)
	local path, partial
	if #context.arrivals > 0 then
		-- Return the path traversing the fewest nodes.
		for _, arrival in ipairs (context.arrivals) do
			local candidate
			local contact = arrival.best_node

			if contact then
				candidate = self:gwp_reconstruct_path (context, contact)
				if not path or #candidate > #path then
					path = candidate
					partial = false
				end
			end
		end
	else
		-- Generate a list of paths to nodes nearest their respective
		-- targets, and select that crossing the fewest nodes.
		local path_dist
		for _, target in ipairs (context.targets) do
			local candidate

			if target.best_node then
				candidate = self:gwp_reconstruct_path (context, target.best_node)
				local dist = d (target.best_node, target)
				if not path or dist >= path_dist and #candidate > #path then
					path = candidate
					path_dist = dist
					partial = true
				end
			end
		end
	end
	return path, partial
end

------------------------------------------------------------------------------
--- Graph edge generation.  It is expected that different versions of
--- these functions will be provided by mobs according to how they
--- move.
------------------------------------------------------------------------------

local function ground_height (context, node)
	local hash = hashpos (context, node.x, node.y, node.z)
	local cache = context.ground_height_cache[hash]
	
	if cache then
		return cache
	end

	local below = vector.offset (node, 0, -1, 0)
	local boxes = minetest.get_node_boxes ("collision_box", below)
	local y = 0

	for _, box in ipairs (boxes) do
		local max = math.max (box[2], box[5])
		if y < max then
			y = max
		end
	end

	-- This is _purposefully_ .5 blocks below the true top face of
	-- the node.
	context.ground_height_cache[hash] = below.y + y
	return below.y + y
end

function mob_class:gwp_essay_jump (context, target)
	local class = self:gwp_classify_node (context, target)
	local penalty = self.gwp_penalties[class]

	if penalty < 0.0 then
		return nil
	end
	-- Return true if this node is walkable or water.
	if class ~= "OPEN" or (self.floats == 0 and class == "WATER") then
		local node = self:get_gwp_node (context, target.x, target.y,
						target.z)
		node.class = class
		node.penalty = math.max (node.penalty, penalty)
		return node
	end
	return nil
end

function mob_class:gwp_essay_drop (context, target)
	local fall_distance = context.fall_distance
	local lim = target.y - fall_distance
	repeat
		target.y = target.y - 1
		local class = self:gwp_classify_node (context, target)
		if class ~= "OPEN" then
			-- Walkable?
			local penalty = self.gwp_penalties[class]
			if penalty < 0 then
				return nil
			end
			local node = self:get_gwp_node (context, target.x, target.y, target.z)
			node.penalty = math.max (penalty, node.penalty)
			node.class = class
			return node
		end
	until target.y < lim
	return nil
end

local MAX_WATER_DROP = 64

function mob_class:gwp_essay_drift (context, target, object)
	local fall_distance = MAX_WATER_DROP
	local lim = target.y - fall_distance
	local last = object and object.class
	while target.y >= lim do
		local class = self:gwp_classify_node (context, target)
		if class ~= "WATER" then
			if not last then
				return nil
			end
			local penalty = self.gwp_penalties[last]
			if penalty < 0 then
				return nil
			end
			local node = self:get_gwp_node (context, target.x,
							target.y + 1, target.z)
			node.penalty = math.max (penalty, node.penalty)
			node.class = last
			return node
		end
		last = class
		target.y = target.y - 1
	end
	return nil
end

local function gwp_edges_1 (self, context, parent, floor, xoff, yoff, zoff, jump, stepheight)
	local node = vector.new (parent.x + xoff, parent.y + yoff,
				 parent.z + zoff)
	if not vector.in_area (node, context.minpos, context.maxpos) then
		return nil
	end
	local ground = ground_height (context, node)
	stepheight = stepheight or context.stepheight

	-- Can this mob climb from PARENT to this node on the same
	-- level without jumping?
	if ground - floor > stepheight then
		return nil
	else
		local class = self:gwp_classify_node (context, node)
		local penalty = self.gwp_penalties[class]
		local object

		-- Is the node traversable?  Return fences though they
		-- are not, as they are needed to validate diagonal
		-- movements.
		if penalty >= 0.0 or class == "FENCE" then
			object = self:get_gwp_node (context, node.x, node.y, node.z)
			object.class = class
			if penalty < 0 then
				object.penalty = penalty
			else
				object.penalty = math.max (penalty, object.penalty)
			end
		end

		-- Is the node unusable?
		if class ~= "WALKABLE" then
			-- Should there be an attempt to jump onto
			-- this node?
			if class == "OPEN" then
				object = self:gwp_essay_drop (context, node)
			elseif class == "BLOCKED" then
				object = self:gwp_essay_jump (context, vector.offset (node, 0, 1, 0))
			elseif (class == "WATER" and self.floats == 0) then
				object = self:gwp_essay_drift (context, node, object)
			elseif class == "IGNORE" then
				object = nil
			end
		end
		if object and not object.covered then
			return object
		end
		return nil
	end
end

mob_class.gwp_penalties = {
	-- A penalty < 0 indicates unconditional rejection, while one
	-- greater than zero compounds the heuristic distance.
	BLOCKED = -1.0,
	IGNORE = -1.0,
	OPEN = 0.0,
	WALKABLE = 0.0,
	DOOR_OPEN = 0.0,
	TRAPDOOR = 0.0,
	WATER = 8.0,
	DANGER_FIRE = 8.0,
	DAMAGE_FIRE = 16.0,
	DAMAGE_OTHER = -1.0,
	DANGER_OTHER = 8.0,
	DOOR_IRON_CLOSED = -1.0,
	DOOR_WOOD_CLOSED = -1.0,
	FENCE = -1.0,
	LAVA = -1.0,
}

local gwp_classify_node_1_scratch = vector.zero ()

local function gwp_classify_node_1 (self, context, pos)
	local class_1 = self:gwp_basic_classify (context, pos)

	-- If this block (the block in which the mob stands) is air,
	-- evaluate the node below.
	if class_1 == "OPEN" then
		local pos_2 = pos

		-- Don't cons a new vector.
		local pos_2 = gwp_classify_node_1_scratch
		pos_2.x = pos.x
		pos_2.y = pos.y - 1
		pos_2.z = pos.z
		local class_2 = self:gwp_basic_classify (context, pos_2)

		if class_2 == "OPEN" or class_2 == "WATER" or class_2 == "LAVA" then
			return "OPEN"
		elseif class_2 == "DAMAGE_FIRE"
			or class_2 == "DAMAGE_OTHER"
			or class_2 == "IGNORE" then
			return class_2
		elseif class_2 == "TRAPDOOR" then
			return "OPEN"
		else
			-- Otherwise, this is walkable.  Adjust its
			-- class according to its surroundings.
			return self:gwp_classify_surroundings (context, pos)
		end
	end
	return class_1
end

-- Evaluate the approximate traversability of nodes that would contact
-- this mob at POS, examining them, and if open, the node(s) beneath
-- them.

local gwp_classify_node_scratch = vector.zero ()

function mob_class:gwp_classify_node (context, pos)
	local hash = hashpos (context, pos.x, pos.y, pos.z)
	local cache = context.class_cache[hash]

	-- This is very expensive, as minetest.get_node conses too
	-- much.
	if cache then
		return cache
	end

	local collisionbox = self.collisionbox
	local width = math.max (0, collisionbox[4] - collisionbox[1] - 1)
	local height = math.max (0, collisionbox[5] - collisionbox[2] - 1)
	local length = math.max (0, collisionbox[6] - collisionbox[3] - 1)
	local sx, sy, sz = pos.x, pos.y, pos.z
	local worst = nil
	local vector = gwp_classify_node_scratch

	width = math.ceil (math.max (width, length) / 2)
	height = math.ceil (height)
	length = math.ceil (math.max (width, length) / 2)
	for x = sx - width, sx + width do
		for y = sy, sy + height do
			for z = sz - length, sz + length do
				local v = vector
				v.x = x
				v.y = y
				v.z = z
				local class = gwp_classify_node_1 (self, context, v)
				-- If a fence is encountered, return
				-- this class.
				if class == "FENCE" then
					return class
				end
				-- Report impassible nodes
				-- immediately.
				if self.gwp_penalties[class] < 0.0 then
					return class
				end
				-- Otherwise select the worst class possible.
				if not worst
				-- Any non-open node should replace OPEN.
					or worst == "OPEN"
					or self.gwp_penalties[worst] < self.gwp_penalties[class] then
					worst = class
				end
			end
		end
	end
	cache = worst or "BLOCKED"
	context.class_cache[hash] = cache
	return cache
end

local gwp_classify_surroundings_scratch = vector.zero ()

function mob_class:gwp_classify_surroundings (context, pos)
	local x, y, z = pos.x, pos.y, pos.z

	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				if dx ~= 0 or dy ~= 0 then
					local new, v = nil, gwp_classify_surroundings_scratch

					v.x = x + dx
					v.y = y + dy
					v.z = z + dz
					new = self:gwp_basic_classify (context, v)
					if new == "DAMAGE_FIRE" or new == "LAVA" then
						return "DANGER_FIRE"
					elseif new == "DAMAGE_OTHER" then
						return "DANGER_OTHER"
					end
				end
			end
		end
	end

	-- Otherwise the node is walkable.
	return "WALKABLE"
end

local function is_partial (nodedef, pos)
	if nodedef.groups.partial == 2 then
		return false
	elseif nodedef.groups.partial == 1 then
		return true
	end

	local boxes = minetest.get_node_boxes ("collision_box", pos)

	-- Return whether the node is the default cube.
	if not (#boxes == 1
		and boxes[1][1] <= -0.5
		and boxes[1][2] <= -0.5
		and boxes[1][3] <= -0.5
		and boxes[1][4] >= 0.5
		and boxes[1][5] >= 0.5
		and boxes[1][6] >= 0.5) then
		nodedef.groups.partial = 1
		return true
	end
	nodedef.groups.partial = 2
	return false
end

function mob_class:gwp_basic_classify (context, pos)
	local node = minetest.get_node (pos)
	local nodename = node.name
	-- Minecraft assigns blocks to one of these classes:
	-- (See: https://nekoyue.github.io/ForgeJavaDocs-NG/javadoc/1.12.2/net/minecraft/pathfinding/PathNodeType.html)
	-- BLOCKED
	-- DAMAGE_CACTUS (not necessary in Mineclonia)
	-- DAMAGE_FIRE
	-- DAMAGE_OTHER
	-- DANGER_CACTUS (not necessary in Mineclonia)
	-- DANGER_FIRE
	-- DANGER_OTHER
	-- DOOR_IRON_CLOSED
	-- DOOR_OPEN
	-- DOOR_WOOD_CLOSED
	-- FENCE
	-- LAVA
	-- OPEN
	-- RAIL (not necessary in Mineclonia)
	-- TRAPDOOR
	-- WALKABLE
	-- WATER
	--
	-- Danger-inflicting nodes are penalized in the pathfinding
	-- process but not categorically avoided.
	-- Damage-inflicting nodes are penalized more, and
	-- encompass LAVA and the like.
	-- If a hazardous node adjoins a node, the latter will be
	-- classified as damage-inflicting.

	if nodename == "air" then
		return "OPEN"
	elseif nodename == "mcl_powder_snow:powder_snow" then
		-- Nonexistent in MC?
		return "DAMAGE_POWDER_SNOW"
	elseif nodename == "mcl_flowers:waterlily" then
		return "TRAPDOOR"
	else
		local def = minetest.registered_nodes[nodename]
		if not def then -- Probably `ignore'.
			return "IGNORE"
		end
		-- TODO: dripstone.
		if def.groups.lava or def.groups.fire then
			return "DAMAGE_FIRE"
		elseif def.damage_per_second ~= 0 then
			return "DAMAGE_OTHER"
		elseif def.groups.water then
			return "WATER"
		elseif def.groups.fence_gate_open then
			return "OPEN"
		elseif def.groups.fence or def.groups.fence_gate or def.groups.wall then
			return "FENCE"
		elseif def.groups.door then
			if mcl_doors.is_open (pos) then
				return "DOOR_OPEN"
			end
			if string.find (nodename, ":iron") then
				return "DOOR_IRON_CLOSED"
			else
				return "DOOR_WOOD_CLOSED"
			end
		elseif def.groups.trapdoor then
			return "TRAPDOOR"
			-- def.groups.partial should be set on
			-- partial-height nodes which mobs should
			-- travel from the inside, such as slabs.
		elseif def.groups.slab or def.groups.stair or def.groups.bed then
			return "BLOCKED"
		elseif not def.walkable or is_partial (def, pos) then
			return "OPEN"
		end
	end
	return "BLOCKED"
end

function mob_class:gwp_check_diagonal (node, flanking1, flanking2)
	-- flanking1 and flanking2 are to be the two nodes flanking
	-- the path from NODE to the target.

	-- Reject movements over nonexistent flanking nodes or those
	-- taller than the origin.
	if not flanking1 or not flanking2
		or flanking1.y > node.y or flanking2.y > node.y then
		return false
	-- Reject open doors, which obstruct diagonal movement.
	elseif flanking2.class == "DOOR_OPEN"
		or flanking1.class == "DOOR_OPEN" then
		return false
	-- Special treatment for movements flanked by fences on both
	-- sides being performed by mobs smaller than half a block in
	-- width.
	elseif flanking2.class == "FENCE" and flanking1.class == "FENCE"
		and self.collisionbox[4] - self.collisionbox[1] <= 0.6 then
		return true
	end
	local f1_valid = flanking1.penalty >= 0 or flanking1.y < node.y
	local f2_valid = flanking2.penalty >= 0 or flanking2.y < node.y
	return f1_valid and f2_valid
end

local function insert_edge (list, edge)
	if edge.penalty >= 0.0 then
		table.insert (list, edge)
	end
end

local gwp_edges_scratch = vector.zero ()

function mob_class:gwp_edges (context, node)
	local array, candidate = {}, {}
	local floor = ground_height (context, node)

	-- Classify the block above this mob's position.
	gwp_edges_scratch.x = node.x
	gwp_edges_scratch.y = node.y + 1
	gwp_edges_scratch.z = node.z
	local jump = self:gwp_classify_node (context, gwp_edges_scratch)
	local permit_jumping = self.gwp_penalties[jump] >= 0.0

	-- Consider neighbors in the four cardinal directions.
	candidate[1] = gwp_edges_1 (self, context, node, floor, 1, 0, 0, permit_jumping)
	if candidate[1] then insert_edge (array, candidate[1]) end
	candidate[2] = gwp_edges_1 (self, context, node, floor, 0, 0, 1, permit_jumping)
	if candidate[2] then insert_edge (array, candidate[2]) end
	candidate[3] = gwp_edges_1 (self, context, node, floor, -1, 0, 0, permit_jumping)
	if candidate[3] then insert_edge (array, candidate[3]) end
	candidate[4] = gwp_edges_1 (self, context, node, floor, 0, 0, -1, permit_jumping)
	if candidate[4] then insert_edge (array, candidate[4]) end
	-- Consider diagonal neighbors at an angle.
	if self:gwp_check_diagonal (node, candidate[1], candidate[2]) then
		candidate[5] = gwp_edges_1 (self, context, node, floor, 1, 0, 1, permit_jumping)
		if candidate[5] then insert_edge (array, candidate[5]) end
	end
	if self:gwp_check_diagonal (node, candidate[1], candidate[4]) then
		candidate[6] = gwp_edges_1 (self, context, node, floor, 1, 0, -1, permit_jumping)
		if candidate[6] then insert_edge (array, candidate[6]) end
	end
	if self:gwp_check_diagonal (node, candidate[3], candidate[2]) then
		candidate[7] = gwp_edges_1 (self, context, node, floor, -1, 0, 1, permit_jumping)
		if candidate[7] then insert_edge (array, candidate[7]) end
	end
	if self:gwp_check_diagonal (node, candidate[3], candidate[4]) then
		candidate[8] = gwp_edges_1 (self, context, node, floor, -1, 0, -1, permit_jumping)
		if candidate[8] then insert_edge (array, candidate[8]) end
	end
	return array
end

----------------------------------------------------------------------------------
-- Pathfinder testing commands, e.g.
-- /mobpathfind
--
-- Some code adopted from the devtest mod `testpathfinder', which is
-- Copyright (C) 2020 Wuzzy <Wuzzy@disroot.org>
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
----------------------------------------------------------------------------------

mcl_mobs.mobs_being_tested = {}
mcl_mobs.players_selecting_mob = {}

local blurb = "Right-click to select a mob, move to the target position, and type /mobpathfind start"
local DTIME_LIMIT = 0.15

local function create_path_particles (path, playername)
	for s=1, #path do
		local t
		if s == #path then
			t = "testpathfinder_waypoint_end.png"
		elseif s == 1 then
			t = "testpathfinder_waypoint_start.png"
		else
			local c = math.floor(((#path-s)/#path)*255)
			t = string.format("testpathfinder_waypoint.png^[multiply:#%02x%02x00", 0xFF-c, c)
		end
		minetest.add_particle({
				pos = path[s],
				expirationtime = 5 + 0.2 * s,
				playername = playername,
				glow = minetest.LIGHT_MAX,
				texture = t,
				size = 3,
		})
	end
end

local function cancel_test (mob, complete)
	if complete then
		local player = minetest.get_player_by_name (complete)
		if not player then
			mob.pathfinding_context = nil
			mob.on_step = mob._old_onstep
			return
		end
		local msg = "Pathfinding completed in "
			.. (string.format ("%.2f", 1000 * mob.pathfinding_duration)) .. " ms"
		minetest.chat_send_player (complete, msg)

		local path = mob:gwp_reconstruct (mob.pathfinding_context)
		create_path_particles (path, complete)
	end
	mob.pathfinding_context = nil
	mob.on_step = mob._old_onstep
end

function mcl_mobs.maybe_test_pathfinding (mob, clicker)
	local name = clicker:get_player_name ()
	if mcl_mobs.players_selecting_mob[name] then
		mcl_mobs.players_selecting_mob[name] = mob.object
		minetest.chat_send_player (name, "Mob selected")
		mob.stupefied = true
	end
end

local cdef = {
	privs = { server = true, },
	params = "[ cancel | start | choose ]",
	func = function (playername, param)
		local player = minetest.get_player_by_name (playername)
		local mobs = mcl_mobs.mobs_being_tested

		if param == "cancel" then
			if mobs[playername] then
				cancel_test (mobs[playername])
				mobs[playername] = nil
			end
			if mcl_mobs.players_selecting_mob[playername] then
				mcl_mobs.players_selecting_mob[playername] = nil
			end
			minetest.chat_send_player (playername, "Canceled")
		elseif param == "choose" then
			if mobs[playername] then
				cancel_test (mobs[playername])
				mobs[playername] = nil
			end
			minetest.chat_send_player (playername, blurb)
			mcl_mobs.players_selecting_mob[playername] = true
		elseif param == "start" then
			local mob = mcl_mobs.players_selecting_mob[playername]
			if mob == true or not mob or not mob:is_valid () then
				local blurb = "You must select a valid mob"
				minetest.chat_send_player (playername, blurb)
				return
			end
			local position = player:get_pos ()
			position = vector.apply (position, math.round)
			local start = mob:get_pos ()
			start = vector.apply (start, math.round)

			local msg = "Pathfinding from mob at "
				.. start.x .. ", " .. start.y .. ", " .. start.z .. " "
				.. "to player, at " .. position.x .. ", "
				.. position.y .. ", " .. position.z .. "..."
			minetest.chat_send_player (playername, msg)

			local entity = mob:get_luaentity ()
			entity.pathfinding_context = entity:gwp_initialize ({position}, 128)
			entity.pathfinding_duration = 0
			local old_step = entity.on_step
			entity._old_onstep = old_step
			entity.on_step = function (self, moveresult)
				if entity.pathfinding_context then
					local context = self.pathfinding_context
					local complete, dtime = self:gwp_cycle (context, DTIME_LIMIT)

					self.pathfinding_duration
						= self.pathfinding_duration + dtime
					if complete then
						mobs[playername] = nil
						cancel_test (self, playername)
					end
					return
				end
				return old_step (self, moveresult)
			end
		end
	end
}

minetest.register_on_leaveplayer (function (object, timed_out)
		local playername = object:get_player_name ()
		local mobs = mcl_mobs.mobs_being_tested
		if mobs[playername] then
			cancel_test (mobs[playername])
			mobs[playername] = nil
		end
end)
minetest.register_chatcommand ("mobpathfind", cdef)

local function print_node_classification (itemstack, user, pointed_thing)
	if not (user and user:is_player ()) then
		return
	end
	local playername = user:get_player_name ()
	if pointed_thing.type == "node" then
		local mob = mcl_mobs.players_selecting_mob[playername]
		if not mob or mob == true then
			minetest.chat_send_player (playername,
						   "Run `/mobpathfind choose' to select a mob to"
						   .. " impersonate before using this tool.")
			return
		end
		local entity = mob:get_luaentity ()
		if not entity then
			return
		end
		-- Target position is immaterial here.
		local context = entity:gwp_initialize ({user:get_pos ()})
		local class1 = entity:gwp_classify_node (context, pointed_thing.under)
		local class2 = entity:gwp_classify_node (context, pointed_thing.above)
		local class3 = entity:gwp_basic_classify (context, pointed_thing.under)
		local class4 = entity:gwp_basic_classify (context, pointed_thing.above)
		minetest.chat_send_player (playername,
					   "ABOVE: " .. class2 .. "\nUNDER: "
					   .. class1 .. "\nABOVE (basic): "
					   .. class4 .. "\nUNDER (basic): "
					   .. class3)

		local collisionbox = entity.collisionbox
		local width = math.max (0, collisionbox[4] - collisionbox[1] - 1)
		local height = math.max (0, collisionbox[5] - collisionbox[2] - 1)
		local length = math.max (0, collisionbox[6] - collisionbox[3] - 1)
		width = math.ceil (math.max (width, length) / 2)
		height = math.ceil (height)
		length = math.ceil (math.max (width, length) / 2)
		minetest.chat_send_player (playername, "WIDTH, HEIGHT, LENGTH: "
					   .. width .. " " .. height .. " " .. length)
	elseif pointed_thing.type == "object" then
		local mob = pointed_thing.ref
		local entity = mob:get_luaentity ()
		if entity and entity.is_mob then
			mcl_mobs.players_selecting_mob[playername] = mob
			minetest.chat_send_player (playername, "Mob selected")
			entity.stupefied = true
		end
	end
end

local function print_node_neighbors (itemstack, user, pointed_thing)
	if not (user and user:is_player ()) then
		return
	end
	local playername = user:get_player_name ()
	if pointed_thing.type == "node" then
		local mob = mcl_mobs.players_selecting_mob[playername]
		if not mob or mob == true then
			minetest.chat_send_player (playername,
						   "Run `/mobpathfind choose' to select a mob to"
						   .. " impersonate before using this tool.")
			return
		end
		local entity = mob:get_luaentity ()
		if not entity then
			return
		end
		-- Target position is immaterial here.
		local context = entity:gwp_initialize ({user:get_pos ()})
		local edges_under = entity:gwp_edges (context, pointed_thing.under)
		local edges_above = entity:gwp_edges (context, pointed_thing.above)
		dbg.pp (edges_under)
		dbg.pp (edges_above)
	end
end

local function pathfind_selected_mob (itemstack, user, pointed_thing)
	if not (user and user:is_player ()) or pointed_thing.type ~= "node" then
		return
	end
	local mobs = mcl_mobs.mobs_being_tested
	local playername = user:get_player_name ()
	local mob = mcl_mobs.players_selecting_mob[playername]
	if not mob or mob == true then
		minetest.chat_send_player (playername,
					   "Run `/mobpathfind choose' to select a mob to"
					   .. " impersonate before using this tool.")
		return
	end
	local entity = mob:get_luaentity ()
	if not entity then
		return
	end
	local position = pointed_thing.above
	position = vector.apply (position, math.round)
	local start = mob:get_pos ()
	start = vector.apply (start, math.round)

	local msg = "Pathfinding from mob at "
		.. start.x .. ", " .. start.y .. ", " .. start.z .. " "
		.. "to node, at " .. position.x .. ", "
		.. position.y .. ", " .. position.z .. "..."
	minetest.chat_send_player (playername, msg)

	local entity = mob:get_luaentity ()
	entity.pathfinding_context = entity:gwp_initialize ({position})
	entity.pathfinding_duration = 0
	local old_step = entity.on_step
	entity._old_onstep = old_step
	entity.on_step = function (self, moveresult)
		if entity.pathfinding_context then
			local context = self.pathfinding_context
			local complete, dtime = self:gwp_cycle (context, DTIME_LIMIT)

			self.pathfinding_duration
				= self.pathfinding_duration + dtime
			if complete then
				mobs[playername] = nil
				cancel_test (self, playername)
			end
			return
		end
		return old_step (self, moveresult)
	end
end

minetest.register_tool ("mcl_mobs:pathfinder_stick", {
	description = "Classify blocks",
	inventory_image = "default_stick.png",
	groups = { testtool = 1, disable_repair = 1,
		   not_in_creative_inventory = 1, },
	on_use = print_node_classification,
	on_place = pathfind_selected_mob,
})

minetest.register_tool ("mcl_mobs:pathfinder_liquid_stick", {
	description = "Classify liquids",
	inventory_image = "default_stick.png",
	groups = { testtool = 1, disable_repair = 1,
		   not_in_creative_inventory = 1, },
	liquids_pointable = true,
	on_use = print_node_classification,
	on_place = pathfind_selected_mob,
})

minetest.register_tool ("mcl_mobs:pathfinder_edge_stick", {
	description = "Print neighbors of blocks",
	inventory_image = "default_stick.png",
	groups = { testtool = 1, disable_repair = 1,
		   not_in_creative_inventory = 1, },
	liquids_pointable = true,
	on_use = print_node_neighbors,
})

-- Number of seconds per step permissible for pathfinding.
local PATHFIND_PER_STEP = 0.200

-- Number of seconds spent pathfinding during this step.
local pathfinding_quota = PATHFIND_PER_STEP
local record_pathfinding_latency = true
local pathfinding_history = {  }

minetest.register_globalstep (function (dtime)
		if pathfinding_quota < 0.0 then
			minetest.log ("warning", "Global pathfinding quota exceeded...")
		end
		if record_pathfinding_latency then
			if #pathfinding_history >= 10 then
				local total = 0
				for _, item in ipairs (pathfinding_history) do
					total = total + item
				end
				minetest.log ("action", "During the previous 10 steps, an average"
					      .. " of " .. total / 10 * 1000
					      .. " ms was spent pathfinding")
				pathfinding_history = { }
			end
			table.insert (pathfinding_history, PATHFIND_PER_STEP - pathfinding_quota)
		end
		pathfinding_quota = PATHFIND_PER_STEP
end)

------------------------------------------------------------------------
-- External interface.
------------------------------------------------------------------------

function mob_class:gopath(target, callback_arrived, prioritised, velocity, animation)
	self:cancel_navigation ()
	self.order = nil
	self.gowp_velocity = velocity
	self.gowp_animation = animation
	self.pathfinding_context = self:gwp_initialize ({target})
	self.callback_arrived = callback_arrived
	return self.pathfinding_context
end

function mob_class:interact_with_door(action, target)
end

function mob_class:do_pathfind_action(action)
end

function mob_class:next_waypoint ()
	-- Pathfind for at most half the remaining quota.
	if self.pathfinding_context then
		-- Continue pathfinding till either the process times
		-- out, or os.clock - time expires.
		local quota = pathfinding_quota
		if quota < 0 then
			return
		end
		local ctx = self.pathfinding_context
		local result, elapsed
			= self:gwp_cycle (ctx, quota)
		pathfinding_quota = pathfinding_quota - elapsed

		if result then
			local waypoints, partial
			waypoints, partial = self:gwp_reconstruct (ctx)

			-- TODO: some criteria for rejecting partial
			-- destinations that are too distant.
			if waypoints then
				self.waypoints = waypoints
			end
			self.pathfinding_context = nil
		end
	elseif self.waypoints then
		local waypoints = self.waypoints
		if #waypoints < 1 then
			self:cancel_navigation ()
			self.movement_goal = nil
			self:halt_in_tracks ()
			if self.callback_arrived then
				self:callback_arrived ()
			end
			return
		end
		local next_wp = waypoints[#waypoints]
		local self_pos = self.object:get_pos ()
		local distance = vector.distance (self_pos, next_wp)

		if distance < 1.0 then
			waypoints[#waypoints] = nil			
		else
			self:go_to_pos (next_wp, self.gowp_velocity,
					self.gowp_animation)
		end
	end
end
