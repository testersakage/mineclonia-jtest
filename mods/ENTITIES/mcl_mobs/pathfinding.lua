local mob_class = mcl_mobs.mob_class
local floor = math.floor

local function shift_up (self, node, idx)
	local priority = node.priority
	local heap = self.heap
	while idx > 1 do
		local parent = floor (idx / 2)
		local n = heap[parent]

		if n.priority < priority then
			break
		end

		-- Swap node positions.
		heap[idx] = n
		n.idx = idx
		idx = parent
	end

	-- idx is now the proper depth of this node in the tree.
	self.heap[idx] = node
	node.idx = idx
end

local function shift_down (self, node, idx)
	local priority = node.priority
	local heap = self.heap
	local size = self.size

	while true do
		local left = idx * 2
		local right = left + 1

		-- Break early if it is known that no nodes exist
		-- greater than this.
		if left > size then
			break
		end
		local leftnode = heap[left]
		local rightnode = heap[right]
		local lp, rp = leftnode.priority
		rp = rightnode and rightnode.priority or math.huge

		if lp < rp then
			if lp >= priority then
				break
			end
			heap[idx] = leftnode
			leftnode.idx = idx
			idx = left
		else
			if rp >= priority then
				break
			end
			heap[idx] = rightnode
			rightnode.idx = idx
			idx = right
		end
	end

	heap[idx] = node
	node.idx = idx
end

local function mintree_enqueue (self, item, priority)
	assert (not item.idx)
	local i = self.size + 1
	self.size = i
	self.heap[i] = item
	item.idx = i
	item.priority = priority
	shift_up (self, item, i)
end

local function mintree_dequeue (self, item, prfiority)
	local heap = self.heap
	local n, size = heap[1], self.size
	heap[1], heap[size] = heap[size], nil
	self.size = size - 1
	if size > 0 then
		shift_down (self, heap[1], 1)
	end
	heap.idx = nil
	return n
end

local function mintree_update (self, item, priority)
	local f_old = item.priority
	item.priority = priority

	if priority < f_old then
		shift_up (self, item, item.idx)
	elseif priority > f_old then
		shift_down (self, item, item.idx)
	end
end

local function mintree_empty (self)
	return self.size == 0
end

local function mintree_contains (self, item)
	return item.idx ~= nil
end

local function new_mintree ()
	return {
		heap = { },
		size = 0,
		enqueue = mintree_enqueue,
		dequeue = mintree_dequeue,
		update = mintree_update,
		empty = mintree_empty,
		contains = mintree_contains,
	}
end

-- Extensible A* pathfinder.
--
-- Notably, it is capable of moving diagonally, assigning deterrence
-- values to blocks, navigating to multiple targets, and returning
-- incomplete paths.

function mob_class:new_gwp_context ()
	return {
		open_set = new_mintree (),
		targets = {},
		arrivals = {},
		nodes = {},
		class_cache = {},
		tolerance = 1,
		time_elapsed = 0,
		total_nodes = 0,
	}
end

local function hashpos (context, x, y, z)
	local x1, y1, z1
	x1 = x - context.minpos.x
	y1 = y - context.minpos.y
	z1 = z - context.minpos.z

	return x1 * 256*256 + y1 * 256 + z1
end

local function longhash (x, y, z)
	return (32767 + x) * 65536 * 65536 + (32767 + y) * 65536
		+ (32767 + z)
end

function mob_class:get_gwp_node (context, x, y, z, g, h)
	local hash = hashpos (context, x, y, z)
	if context.nodes[hash] then
		return context.nodes[hash]
	end
	local obj = {
		x = x, y = y, z = z,
		g = g, h = h, penalty = 0,
		f = 0, total_d = 0,
	}
	context.nodes[hash] = obj
	return obj
end

function mob_class:gwp_target_pos (context, pos)
	local n = mob_class:get_gwp_node (context, floor (pos.x + 0.5),
					  floor (pos.y + 0.5),
					  floor (pos.z + 0.5))
	-- 3d Manhattan distance of closest_node.
	n.closest = -1
	-- Visited node nearest to the target.
	n.closest_node = nil
	-- Class and penalty of this node.
	n.class = self:gwp_classify_node (context, n)
	n.penalty = self.gwp_penalties[n.class]
	return n
end

local function round_trunc (n)
	return floor (n + 0.5)
end

function mob_class:gwp_start_1 (context)
	-- If standing in water...
	local pos = self.object:get_pos ()
	pos.x = floor (pos.x + 0.5)
	pos.y = floor (pos.y + 1.0) -- Deal with soul sand and slabs.
	pos.z = floor (pos.z + 0.5)
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


function mob_class:gwp_start (context)
	local pos = self:gwp_start_1 (context)
	if pos then
		-- If this mob is wider than 1 block, check for valid
		-- start positions at every block on which it is
		-- standing.
		if self:gwp_classify_node (context, pos) == "BLOCKED" then
			local c1, c2, c3, c4
			local cbox = self.collisionbox
			c1 = vector.new (pos.x + cbox[1], pos.y, pos.z + cbox[3])
			c1 = vector.apply (c1, round_trunc)
			c2 = vector.new (pos.x + cbox[1], pos.y, pos.z + cbox[6])
			c2 = vector.apply (c2, round_trunc)
			c3 = vector.new (pos.x + cbox[4], pos.y, pos.z + cbox[3])
			c3 = vector.apply (c3, round_trunc)
			c4 = vector.new (pos.x + cbox[4], pos.y, pos.z + cbox[6])
			c4 = vector.apply (c4, round_trunc)
			if self:gwp_classify_node (context, c1) ~= "BLOCKED" then
				return c1
			end
			if self:gwp_classify_node (context, c2) ~= "BLOCKED" then
				return c2
			end
			if self:gwp_classify_node (context, c3) ~= "BLOCKED" then
				return c3
			end
			if self:gwp_classify_node (context, c4) ~= "BLOCKED" then
				return c4
			end
		else
			return pos
		end
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
	local pos = vector.apply (self.object:get_pos (), round_trunc)
	-- This limit is decided by the values `hashpos' is capable of
	-- handling.
	range = range or self.tracking_distance
	context.range = math.min (range, 127)
	context.minpos = vector.new (pos.x - range, pos.y - range,
				     pos.z - range)
	context.maxpos = vector.new (pos.x + range, pos.y + range,
				     pos.z + range)

	-- Establish a limit on the distance of routes and on the
	-- number of nodes examined.
	context.maxdist = range
	context.maxnodes = floor (range * 16)

	-- If a mob is being attacked, tolerance is the reach
	-- distance.
	if self.attacking then
		context.tolerance = self.reach * 0.65
	end

	-- Calculate entity dimensions.
	local collisionbox = self.collisionbox
	local width = math.max (0, collisionbox[4] - collisionbox[1])
	local height = math.max (0, collisionbox[5] - collisionbox[2])
	local length = math.max (0, collisionbox[6] - collisionbox[3])
	context.mob_width = floor (math.max (width, length) + 1.0)
	context.mob_height = math.ceil (height)

	-- Map target positions to acceptable nodes.
	for _, pos in ipairs (targets) do
		local t = self:gwp_target_pos (context, pos)
		if t then
			table.insert (context.targets, t)
		end
	end

	-- Derive a valid start position if suspended in water or the
	-- like.
	local start = self:gwp_start (context)
	if not start or not vector.in_area (start, context.minpos,
					context.maxpos) then
		return nil
	end

	-- Construct initial open set and initialize context for first
	-- cycle.
	start.g = 0
	start.h = self:h_to_nearest_target (start, context)
	start.total_d = 0
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
	local n_total = context.total_nodes
	local maxnodes = context.maxnodes
	context.stepheight = self.object:get_properties ().stepheight
	context.fall_distance = self:gwp_safe_fall_distance ()
	repeat
		if set:empty () then
			local time = os.clock () - time
			context.time_elapsed = context.time_elapsed + time
			context.total_nodes = n_total
			return true, time
		end

		if n_total + 1 > maxnodes then
			local time = os.clock () - time
			context.time_elapsed = context.time_elapsed + time
			context.total_nodes = n_total
			return true, time
		end

		local node = set:dequeue ()
		node.covered = true
		n_total = n_total + 1

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
			context.total_nodes = n_total
			return true, time
		end

		-- Enter each neighbor into the queue.
		local neighbors = self:gwp_edges (context, node)
		for _, neighbor in ipairs (neighbors) do
			-- What is the distance from hence to this
			-- neighbor?
			local dist = d (node, neighbor)
			neighbor.total_d = node.total_d + dist
			if dist <= context.range
				and neighbor.total_d < context.maxdist then
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
	context.total_nodes = n_total
	return false, clock - time
end

function mob_class:gwp_reconstruct_path (context, arrival)
	local list = {arrival}
	while arrival.referrer ~= nil do
		table.insert (list, arrival.referrer)

		-- Adjust waypoint position so as to center the mob on
		-- the path.
		arrival.x = arrival.x + context.mob_width * 0.5 - 0.5
		arrival.z = arrival.z + context.mob_width * 0.5 - 0.5
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

local ground_height_scratch = vector.zero ()
local ground_height_this_step = {}

local function ground_height (context, node)
	local hash = longhash (node.x, node.y, node.z)
	local cache = ground_height_this_step[hash]

	if cache then
		return cache
	end

	local below = ground_height_scratch
	below.x = node.x
	below.y = node.y - 1
	below.z = node.z
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
	ground_height_this_step[hash] = below.y + y
	return below.y + y
end

local gwp_ej_scratch = vector.zero ()
local gwp_parent_penalty = nil

function mob_class:gwp_essay_jump (context, target, parent)
	local class = self:gwp_classify_node (context, target)
	local penalty = self.gwp_penalties[class]

	-- Classify the block above the parent's position, unless
	-- already classified.
	if gwp_parent_penalty == nil then
		gwp_ej_scratch.x = parent.x
		gwp_ej_scratch.y = parent.y + 1
		gwp_ej_scratch.z = parent.z
		local jump = self:gwp_classify_node (context, gwp_ej_scratch)
		local penalty = self.gwp_penalties[jump]
		gwp_parent_penalty = penalty
	end

	-- And make sure it both the target and the parent are
	-- navigable.
	if penalty < 0.0 or gwp_parent_penalty < 0.0 then
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

local gwp_edges_1_scratch = vector.zero ()

local function gwp_edges_1 (self, context, parent, floor, xoff, zoff, jump)
	local node = gwp_edges_1_scratch
	node.x = parent.x + xoff
	node.y = parent.y
	node.z = parent.z + zoff
	if not vector.in_area (node, context.minpos, context.maxpos) then
		return nil
	end
	local ground = ground_height (context, node)

	-- Can this mob climb from PARENT to this node on the same
	-- level without jumping?
	if ground - floor > context.stepheight then
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
				node.y = node.y + 1
				object = self:gwp_essay_jump (context, node, parent)
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

local gwp_floortypes = {
	OPEN = "OPEN",
	WATER = "OPEN",
	LAVA = "OPEN",
	DAMAGE_FIRE = "DAMAGE_FIRE",
	DAMAGE_OTHER = "DAMAGE_OTHER",
	IGNORE = "IGNORE",
}

local function is_partial (nodedef, pos)
	if nodedef.groups._mcl_partial == 2 then
		return false
	elseif nodedef.groups._mcl_partial == 1 then
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
		nodedef.groups._mcl_partial = 1
		return true
	end
	nodedef.groups._mcl_partial = 2
	return false
end

local nodes_this_step = {}

local function gwp_get_node (pos)
	local hash = longhash (pos.x, pos.y, pos.z)
	local map = nodes_this_step
	local cache = map[hash]

	if cache then
		return cache
	end

	cache = minetest.get_node (pos).name
	map[hash] = cache
	return cache
end

-- local record_pathfinding_stats = false
-- local bc_stats = { }

local function gwp_basic_classify (pos)
	local nodename, value = gwp_get_node (pos), "OPEN"

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

	if nodename ~= "air" then
		local def = minetest.registered_nodes[nodename]
		if not def then
			value = "IGNORE"
		elseif def._pathfinding_class then
			value = def._pathfinding_class
		-- TODO: dripstone.
		elseif def.damage_per_second ~= 0 then
			value = "DAMAGE_OTHER"
		elseif def.groups.door then
			if mcl_doors.is_open (pos) then
				value = "DOOR_OPEN"
			elseif def.groups.door_iron then
				value = "DOOR_IRON_CLOSED"
			else
				value = "DOOR_WOOD_CLOSED"
			end
			-- def.groups.partial should be set to 2 on
			-- partial-height nodes which mobs should
			-- travel from the inside, such as slabs.
		elseif def.walkable and not is_partial (def, pos) then
			value = "BLOCKED"
		end
	end
	-- if record_pathfinding_stats then
	-- 	bc_stats[value] = (bc_stats[value] or 0) + 1
	-- end
	return value
end

local gwp_classify_node_1_scratch = vector.zero ()

local function gwp_classify_node_1 (self, pos)
	local class_1 = gwp_basic_classify (pos)

	-- If this block (the block in which the mob stands) is air,
	-- evaluate the node below.
	if class_1 == "OPEN" then
		-- Don't cons a new vector.
		local pos_2 = gwp_classify_node_1_scratch
		pos_2.x = pos.x
		pos_2.y = pos.y - 1
		pos_2.z = pos.z
		local class_2 = gwp_basic_classify (pos_2)
		local floortype = gwp_floortypes[class_2]

		-- Otherwise, this is walkable.  Adjust its
		-- class according to its surroundings.
		return floortype or self:gwp_classify_surroundings (pos)

	end
	return class_1
end

-- Evaluate the approximate traversability of nodes that would contact
-- this mob at POS, examining them, and if open, the node(s) beneath
-- them.

local gwp_classify_node_scratch = vector.zero ()
-- local gwp_cc_hits, gwp_cc_misses = 0, 0

function mob_class:gwp_classify_node (context, pos)
	local hash = hashpos (context, pos.x, pos.y, pos.z)
	local cache = context.class_cache[hash]

	-- This is very expensive, as minetest.get_node conses too
	-- much.
	if cache then
		-- if record_pathfinding_stats then
		-- 	gwp_cc_hits = gwp_cc_hits + 1
		-- end
		return cache
	end
	-- if record_pathfinding_stats then
	-- 	gwp_cc_misses = gwp_cc_misses + 1
	-- end

	local sx, sy, sz = pos.x, pos.y, pos.z
	local worst, penalty = "OPEN", 0.0
	local vector = gwp_classify_node_scratch
	local b_width, b_height
	local penalties = self.gwp_penalties

	b_width = context.mob_width - 1
	b_height = context.mob_height - 1

	for x = sx, sx + b_width do
		for y = sy, sy + b_height do
			for z = sz, sz + b_width do
				vector.x = x
				vector.y = y
				vector.z = z
				local class = gwp_classify_node_1 (self, vector)
				-- Report impassible nodes
				-- immediately.
				if penalties[class] < 0.0 then
					return class
				-- Otherwise select the worst class possible.
				elseif worst == "OPEN" or penalty < penalties[class] then
					penalty = penalties[class]
					worst = class
				end
			end
		end
	end
	cache = worst
	context.class_cache[hash] = cache
	return cache
end

function mob_class:gwp_classify_for_movement (pos)
	local sx, sy, sz = pos.x, pos.y, pos.z
	local worst, penalty = "OPEN", 0.0
	local vector = gwp_classify_node_scratch
	local b_width, b_height
	local penalties = self.gwp_penalties
	local collisionbox = self.collisionbox
	local width = math.max (0, collisionbox[4] - collisionbox[1])
	local height = math.max (0, collisionbox[5] - collisionbox[2])
	local length = math.max (0, collisionbox[6] - collisionbox[3])

	b_width = floor (math.max (width, length) + 1.0) - 1
	b_height = math.ceil (height) - 1

	for x = sx, sx + b_width do
		for y = sy, sy + b_height do
			for z = sz, sz + b_width do
				vector.x = x
				vector.y = y
				vector.z = z
				local class = gwp_classify_node_1 (self, vector)
				-- Report impassible nodes
				-- immediately.
				if penalties[class] < 0.0 then
					return class
				-- Otherwise select the worst class possible.
				elseif worst == "OPEN" or penalty < penalties[class] then
					penalty = penalties[class]
					worst = class
				end
			end
		end
	end
	return worst
end

local gwp_classify_surroundings_scratch = vector.zero ()

local gwp_influence_by_type = {
	DAMAGE_FIRE = "DANGER_FIRE",
	LAVA = "DANGER_FIRE",
	DAMAGE_OTHER = "DANGER_OTHER",
}

function mob_class:gwp_classify_surroundings (pos)
	local x, y, z = pos.x, pos.y, pos.z
	local v = gwp_classify_surroundings_scratch
	local influences = gwp_influence_by_type

	v.x = x + -1
	v.y = y + -1
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 1
	v.z = z + 1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 1
	v.z = z + 0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 1
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 0
	v.z = z + 1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 0
	v.z = z + 0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + 0
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + -1
	v.z = z + 1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + -1
	v.z = z + 0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 1
	v.y = y + -1
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y + 1
	v.z = z + 1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y + 1
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y + 0
	v.z = z + 1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y + 0
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y +  -1
	v.z = z +  1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + 0
	v.y = y +  -1
	v.z = z +  -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  1
	v.z = z +  1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  1
	v.z = z +  0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  1
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  0
	v.z = z +  1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  0
	v.z = z +  0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  0
	v.z = z + -1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y +  -1
	v.z = z +  1
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	v.x = x + -1
	v.y = y + -1
	v.z = z + 0
	local new = gwp_basic_classify (v)
	local influence = influences[new]
	if influence then
		return influence
	end

	-- Otherwise the node is walkable.
	return "WALKABLE"
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

local gwp_edges_scratch = {}

function mob_class:gwp_edges (context, node)
	local array, c1, c2, c3, c4 = gwp_edges_scratch
	local floor = ground_height (context, node)
	local n = 0
	gwp_parent_penalty = nil

	-- Consider neighbors in the four cardinal directions.
	c1 = gwp_edges_1 (self, context, node, floor, 1, 0)
	if c1 and c1.penalty >= 0.0 then n = n + 1; array[n] = c1 end
	c2 = gwp_edges_1 (self, context, node, floor, 0, 1)
	if c2 and c2.penalty >= 0.0 then n = n + 1; array[n] = c2 end
	c3 = gwp_edges_1 (self, context, node, floor, -1, 0)
	if c3 and c3.penalty >= 0.0 then n = n + 1; array[n] = c3 end
	c4 = gwp_edges_1 (self, context, node, floor, 0, -1)
	if c4 and c4.penalty >= 0.0 then n = n + 1; array[n] = c4 end
	-- Consider diagonal neighbors at an angle.
	if self:gwp_check_diagonal (node, c1, c2) then
		local d = gwp_edges_1 (self, context, node, floor, 1, 1)
		if d then n = n + 1; array[n] = d end
	end
	if self:gwp_check_diagonal (node, c1, c4) then
		local d = gwp_edges_1 (self, context, node, floor, 1, -1)
		if d then n = n + 1; array[n] = d end
	end
	if self:gwp_check_diagonal (node, c3, c2) then
		local d = gwp_edges_1 (self, context, node, floor, -1, 1)
		if d then n = n + 1; array[n] = d end
	end
	if self:gwp_check_diagonal (node, c3, c4) then
		local d = gwp_edges_1 (self, context, node, floor, -1, -1)
		if d then n = n + 1; array[n] = d end
	end
	array[n + 1] = nil
	return array
end

if minetest.global_exists ("jit") then
	jit.off (mob_class.gwp_cycle, true)
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
			local c = floor (((#path-s)/#path)*255)
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
			position = vector.apply (position, round_trunc)
			local start = mob:get_pos ()
			start = vector.apply (start, round_trunc)

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
		local class3 = gwp_basic_classify (pointed_thing.under)
		local class4 = gwp_basic_classify (pointed_thing.above)
		minetest.chat_send_player (playername,
					   "ABOVE: " .. class2 .. "\nUNDER: "
					   .. class1 .. "\nABOVE (basic): "
					   .. class4 .. "\nUNDER (basic): "
					   .. class3)

		local width = context.mob_width
		local height = context.mob_height
		minetest.chat_send_player (playername, "WIDTH (& LENGTH), HEIGHT: "
					   .. width .. " " .. height)
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
	position = vector.apply (position, round_trunc)
	local start = mob:get_pos ()
	start = vector.apply (start, round_trunc)

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
local PATHFIND_PER_STEP = 0.035
local PATHFIND_TIMEOUT  = 10.0 / 1000

-- Number of seconds spent pathfinding during this step.
local pathfinding_quota = PATHFIND_PER_STEP
local mobs_this_step = 0
-- local pathfinding_history = {  }

minetest.register_globalstep (function (dtime)
		ground_height_this_step = {}
		nodes_this_step = {}
		if pathfinding_quota <= 0.0 then
			minetest.log ("warning", "Global pathfinding quota exceeded...")
		end
		-- if record_pathfinding_stats then
		-- 	if #pathfinding_history >= 20 then
		-- 		local total, max = 0, 0
		-- 		for _, item in ipairs (pathfinding_history) do
		-- 			total = total + item
		-- 			if item > max then
		-- 				max = item
		-- 			end
		-- 		end
		-- 		minetest.log ("action", "During the previous 20 steps, an average"
		-- 			      .. " of " .. string.format ("%.2f", total / 10 * 1000)
		-- 			      .. " ms, and a maximum of "
		-- 			      .. string.format ("%.2f", max * 1000)
		-- 			      .. " ms, were spent pathfinding on behalf of ~"
		-- 			      .. mobs_this_step .. " mobs (amounting to "
		-- 			      .. string.format ("%.2f", max * 1000 / mobs_this_step)
		-- 			      .. "/mob).")
		-- 		total = 0
		-- 		for nodetype, n in pairs (bc_stats) do
		-- 			total = total + n
		-- 		end
		-- 		minetest.log ("action", "In the process, " .. total .. " nodes were examined,"
		-- 			      .. " distributed between: ")
		-- 		local t = {}
		-- 		for nodetype, n in pairs (bc_stats) do
		-- 			table.insert (t, { n, nodetype, })
		-- 		end
		-- 		table.sort (t, function (a, b) return a[1] < b[1] end)
		-- 		for _, item in ipairs (t) do
		-- 			minetest.log ("action", string.format ("   %s: %d nodes (%.2f %%)",
		-- 							       item[2], item[1],
		-- 							       item[1] / total * 100))
		-- 		end
		-- 		minetest.log ("action", string.format ("%.2f%% of classification attempts registered cache hits", (gwp_cc_hits / (gwp_cc_hits + gwp_cc_misses)) * 100))
		-- 		bc_stats = {}
		-- 		pathfinding_history = { }
		-- 		mobs_this_step = 0
		-- 	end
		-- 	table.insert (pathfinding_history, PATHFIND_PER_STEP - pathfinding_quota)
		-- end
		pathfinding_quota = PATHFIND_PER_STEP
end)

------------------------------------------------------------------------
-- External interface.
------------------------------------------------------------------------

function mob_class:gopath (target, callback_arrived, prioritised, velocity, animation)
	self:cancel_navigation ()
	self.order = nil
	self.gowp_velocity = velocity
	self.gowp_animation = animation or "walk"
	self.pathfinding_context = self:gwp_initialize ({target})
	self.callback_arrived = callback_arrived
	return self.pathfinding_context
end

function mob_class:interact_with_door(action, target)
end

function mob_class:do_pathfind_action(action)
end

local GWP_TIMEOUT_TICKS = 100
local GWP_TIMEOUT	= 100 / 20

function mob_class:gwp_position_on_path ()
	return self.object:get_pos ()
end

function mob_class:gwp_timeout (dtime)
	local timeout = self._gwp_timeout
	local previous_pos = self._gwp_previous_pos
	timeout = timeout - dtime

	if timeout <= 0 then
		local expected_speed

		if self.movement_speed >= 1.0 then
			-- The speed won't be scaled by itself.
			expected_speed = self.movement_speed
		else
			expected_speed
				= self.movement_speed * self.movement_speed
		end
		local pos = self:gwp_position_on_path ()
		if previous_pos then
			local mindist = expected_speed * GWP_TIMEOUT_TICKS * 0.25
			if mindist > vector.distance (pos, previous_pos) then
				self.waypoints = nil
				self:halt_in_tracks ()
				return
			end
		end

		self._gwp_previous_pos = pos
		self._gwp_timeout = GWP_TIMEOUT
	end
	self._gwp_timeout = math.max (0, timeout)
end

function mob_class:next_waypoint (dtime)
	-- Pathfind for at most half the remaining quota.
	if self.pathfinding_context then
		-- Continue pathfinding till either the process times
		-- out, or os.clock - time expires.
		mobs_this_step = mobs_this_step + 1
		local quota = pathfinding_quota
		if quota < 0 then
			return
		end
		local ctx = self.pathfinding_context
		local timeout = math.min (PATHFIND_TIMEOUT - ctx.time_elapsed,
					  quota)
		local result, elapsed
			= self:gwp_cycle (ctx, math.max (0, timeout))
		if ctx.time_elapsed > PATHFIND_TIMEOUT then
			result = true
		end
		pathfinding_quota = pathfinding_quota - elapsed
		self._gwp_timeout = GWP_TIMEOUT

		if result then
			local waypoints, _
			waypoints, _ = self:gwp_reconstruct (ctx)

			-- TODO: some criteria for rejecting partial
			-- destinations that are too distant.
			if waypoints then
				self.waypoints = waypoints
			end
			self:set_animation (self.gowp_animation)
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
		local dist_to_xcenter = math.abs (next_wp.x - self_pos.x)
		local dist_to_ycenter = math.abs (next_wp.y + 0.5 - self_pos.y)
		local dist_to_zcenter = math.abs (next_wp.z - self_pos.z)
		local cbox = self.collisionbox
		local girth = math.max (cbox[4] - cbox[1], cbox[6] - cbox[3])
		local mindist = girth > 0.75 and girth / 2 or 0.75 - girth / 2

		if dist_to_xcenter < mindist
			and dist_to_zcenter < mindist
			and dist_to_ycenter < 1.5 then
			waypoints[#waypoints] = nil
		else
			-- Is this mob already en route to the next waypoint?
			if #waypoints > 1 then
				local ahead = waypoints[#waypoints - 1]
				self_pos.y = ahead.y
				local dir = vector.direction (self_pos, ahead)
				local dir1 = vector.direction (self_pos, next_wp)
				if vector.dot (dir, dir1) < 0 then
					next_wp = ahead
					waypoints[#waypoints] = nil
				end
			end

			-- Head to the center of the waypoint.
			self.movement_goal = "go_pos"
			self.movement_target = next_wp
			self.movement_velocity = self.gowp_velocity or self.movement_speed
		end

		self:gwp_timeout (dtime)
	end
end

