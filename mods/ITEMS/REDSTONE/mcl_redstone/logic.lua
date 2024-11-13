local wireflag_tab = mcl_redstone._wireflag_tab
local opaque_tab = mcl_redstone._solid_opaque_tab

-- get_power, update and init callbacks by name
local get_power_tab = {}
local update_tab = {}
local init_tab = {}

-- 0-3 correspond to the direction bits in wireflags.
local sixdirs = {
	[0] = vector.new(0, 0, 1),
	[1] = vector.new(1, 0, 0),
	[2] = vector.new(0, 0, -1),
	[3] = vector.new(-1, 0, 0),
	[4] = vector.new(0, -1, 0),
	[5] = vector.new(0, 1, 0),
}

local wiredirs = {
	[0x1] = {wire = vector.new(0, 0, -1)},
	[0x2] = {wire = vector.new(-1, 0, 0)},
	[0x4] = {wire = vector.new(0, 0, 1)},
	[0x8] = {wire = vector.new(1, 0, 0)},
}

local wiredirs_up = {
	[0x1] = {wire = vector.new(0, 1, -1), obstruct = vector.new(0, 1, 0)},
	[0x2] = {wire = vector.new(-1, 1, 0), obstruct = vector.new(0, 1, 0)},
	[0x4] = {wire = vector.new(0, 1, 1), obstruct = vector.new(0, 1, 0)},
	[0x8] = {wire = vector.new(1, 1, 0), obstruct = vector.new(0, 1, 0)},
}

local wiredirs_down = {
	[0x1] = {wire = vector.new(0, -1, -1), obstruct = vector.new(0, 0, -1)},
	[0x2] = {wire = vector.new(-1, -1, 0), obstruct = vector.new(-1, 0, 0)},
	[0x4] = {wire = vector.new(0, -1, 1), obstruct = vector.new(0, 0, 1)},
	[0x8] = {wire = vector.new(1, -1, 0), obstruct = vector.new(1, 0, 0)},
}

local function iterate_wire_neighbours(wireflags)
	local i = 1
	local state = 0
	-- core.debug("IMPORTANT!", wireflags)
	-- `state` is a special variable that meansL
	-- 0: now returning entry from the block to the side
	-- 1: now returning entry from the block to the side and up
	-- 2: now returning entry from the block to the side and down
	return function(wireflags)
		-- core.debug("ITER!", wireflags, i, state)
		if state == 0 then
			while i <= 8 do
				local val = bit.band(wireflags, bit.bor(i, bit.lshift(i, 4)))
				local tmp = wiredirs[i]
				-- core.debug("pop", val)
				if val == i then
					-- if goes to the side of that block
					state = 2
					return tmp
				elseif val ~= 0 then
					-- if goes up a block
					state = 1
					return tmp
				end
				i = i * 2
			end
			-- core.debug("terminate")
			return
		elseif state == 1 then
			state = 2
			return wiredirs_up[i]
		else
			local tmp = wiredirs_down[i]
			i = i * 2
			state = 0
			return tmp
		end
	end, wireflags
end

-- pre calculated table for the get_node_power_2 function
-- each element corresponds to a direction
-- dir - the direction
-- always_check - the offset position of node to always check for power
-- conditional_checks - offset positions of nodes to check only if they weren't checked already:
-- * the keys are indexes in get_node_power_2_tab table
-- * the values are the offset positions to check
-- * if the direction specified by the key was already checked then the position wont be checked again
local get_node_power_2_tab =
{
	{dir = vector.new(0, 0, 1), always_check = vector.new(0, 0, 2), conditional_checks =
	{
		[5] = vector.new(0, 1, 1),
		[6] = vector.new(0, -1, 1),
		[3] = vector.new(1, 0, 1),
		[4] = vector.new(-1, 0, 1),
	}},
	{dir = vector.new(0, 0, -1), always_check = vector.new(0, 0, -2), conditional_checks =
	{
		[5] = vector.new(0, 1, -1),
		[6] = vector.new(0, -1, -1),
		[3] = vector.new(1, 0, -1),
		[4] = vector.new(-1, 0, -1),
	}},
	{dir = vector.new(1, 0, 0), always_check = vector.new(2, 0, 0), conditional_checks =
	{
		[1] = vector.new(1, 0, 1),
		[2] = vector.new(1, 0, -1),
		[5] = vector.new(1, 1, 0),
		[6] = vector.new(1, -1, 0),
	}},
	{dir = vector.new(-1, 0, 0), always_check = vector.new(-2, 0, 0), conditional_checks =
	{
		[1] = vector.new(-1, 0, 1),
		[2] = vector.new(-1, 0, -1),
		[5] = vector.new(-1, 1, 0),
		[6] = vector.new(-1, -1, 0),
	}},
	{dir = vector.new(0, 1, 0), always_check = vector.new(0, 2, 0), conditional_checks =
	{
		[1] = vector.new(0, 1, 1),
		[2] = vector.new(0, 1, -1),
		[3] = vector.new(1, 1, 0),
		[4] = vector.new(-1, 1, 0),
	}},
	{dir = vector.new(0, -1, 0), always_check = vector.new(0, -2, 0), conditional_checks =
	{
		[1] = vector.new(0, -1, 1),
		[2] = vector.new(0, -1, -1),
		[3] = vector.new(1, -1, 0),
		[4] = vector.new(-1, -1, 0),
	}},
}

-- Get strong power from neighbours (including opaque nodes) at pos.
local function get_node_power_2(pos)
	-- core.debug("INVOKED!", dump(pos))
	local power = 0
	-- all these false values correspond to each index in get_node_power_2_tab table
	local checked_directions = {}

	local function get_node_power(node, dir, include_weak)
		local power2, is_strong = get_power_tab[node.name](node, -dir)

		-- core.debug("GOT POWER", power2)

		if (is_strong or include_weak) and power2 > power then
			power = power2
		end

		return power2
	end

	for i, entry in pairs(get_node_power_2_tab) do
		checked_directions[i] = false
		local pos2 = pos:add(entry.dir)
		local node2 = minetest.get_node(pos2)

		-- core.debug("DIR", tostring(entry.dir))
		if get_power_tab[node2.name] then
				-- core.debug("DIRECT", dump(node2), dump(entry.dir))
				get_node_power(node2, entry.dir, true)
				if power == 15 then
					return power
				end
		elseif opaque_tab[node2.name] then
			-- core.debug("OPAQUE")
			checked_directions[i] = true
			local always_check_node = minetest.get_node(pos + entry.always_check)

			-- core.debug("ALWAYS CHECK", dump(always_check_node), entry.always_check, tostring(entry.dir))
			if get_power_tab[always_check_node.name] then
				get_node_power(always_check_node, entry.dir)

				if power == 15 then
					return power
				end
			end

			for key, offset_pos in pairs(entry.conditional_checks) do
				if not checked_directions[key] then
					-- if not already checked
					local node3 = minetest.get_node(offset_pos + pos)
					-- core.debug(tostring(offset_pos), get_node_power_2_tab[key].dir, dump(node3))

					if get_power_tab[node3.name] then
						local power3 = get_node_power(node3, get_node_power_2_tab[key].dir)

						if power3 == 15 then
							return power
						else
							-- hack
							checked_directions[i] = false
						end
					end
				end
			end

		end
	end

	-- core.debug("END", power)
	return power
end

-- Propagate redstone power through wires. 'clear_queue' is a queue of events
-- were power which is lowered/removed. 'fill_queue' is a queue of events were
-- power is added/raised. 'update' is a table which gets populated with
-- positions that should get redstone update events.
local function propagate_wire(clear_queue, fill_queue, updates)
	-- core.debug("propagating: ", dump(fill_queue), dump(clear_queue), debug.traceback())
	local count = 0
	local nodecache = {}

	local function get_node(pos, hash)
		hash = hash or core.hash_node_position(pos)
		if not nodecache[hash] then
			nodecache[hash] = minetest.get_node(pos)
		end
		return nodecache[hash]
	end

	local function get_power(node)
		return lwireflag_tab[node.name] and node.param2 or 0
	end

	local function update_opaque_node(pos)
		for _, dir in pairs(sixdirs) do
			local pos2 = pos:add(dir)
			local hash = core.hash_node_position(pos2)

			mcl_redstone._pending_updates[hash] = update_tab[get_node(pos2, hash).name] and pos2 or nil
		end
	end

	for v in clear_queue:iterate() do
		local hash = core.hash_node_position(v.pos)
		nodecache[hash] = {name = get_node(v.pos, hash).name, param2 = 0}
	end

	for v in clear_queue:iterate() do
		swap_node(v.pos, {name = minetest.get_node(v.pos).name, param2 = 0})
	end

	while clear_queue:size() > 0 do
		local entry = clear_queue:dequeue()
		local pos = entry.pos
		local power = entry.power
		local node = get_node(pos, core.hash_node_position(pos))

		for dir in iterate_wire_neighbours(lwireflag_tab[node.name] or 0xFF) do
			count = count + 1
			local pos2 = pos:add(dir.wire)
			local hash2 = core.hash_node_position(pos2)
			local node2 = get_node(pos2, hash2)

			-- when wire pointing towards a redstone component. update it
			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
			-- core.debug(tostring(pos2))

			-- when wire pointing towards an opaque node. update it
			if opaque_tab[node2.name] then
				update_opaque_node(pos2)
			end

			-- when wire pointing another wire. propagate it further
			local obstruct_pos = dir.obstruct and pos:add(dir.obstruct)
			-- core.debug(dump(dir), dump(obstruct_pos))
			if not dir.obstruct or not opaque_tab[get_node(obstruct_pos, core.hash_node_position(obstruct_pos)).name] then
				local power2 = get_power(node2)

				if power2 > 0 then
					if power2 < power then
						nodecache[hash2] = {name = node2.name, param2 = 0}
						clear_queue:enqueue({pos = pos2, power = power2})
					else
						-- core.debug("adding to fill queue")
						nodecache[hash2] = {name = node2.name, param2 = power2}
						fill_queue:enqueue({pos = pos2, power = power2})
					end
				end
			-- else
			-- 	core.debug("wasted check:", tostring(pos2))
			end
		end
	end

	-- core.debug("fill queue:", dump(fill_queue))
	for v in fill_queue:iterate() do
		-- core.debug("ITER", dump(v), dump(minetest.get_node(v.pos)))
		local hash = core.hash_node_position(v.pos)
		nodecache[hash] = {name = get_node(v.pos, hash).name, param2 = v.power}
	end

	while fill_queue:size() > 0 do
		local entry = fill_queue:dequeue()
		local pos = entry.pos
		local power = entry.power
		local power2 = power - 1

		for dir in iterate_wire_neighbours(lwireflag_tab[get_node(pos, core.hash_node_position(pos)).name]) do
			-- count = count + 1
			local pos2 = pos:add(dir.wire)
			local hash2 = core.hash_node_position(pos2)
			local node2 = get_node(pos2, hash2)

			-- when wire pointing towards a redstone component. update it
			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil

			-- when wire pointing towards an opaque node. update it
			if opaque_tab[node2.name] then
				update_opaque_node(pos2)
			end

			local obstruct_pos = dir.obstruct and pos:add(dir.obstruct)
			if not dir.obstruct or not opaque_tab[get_node(obstruct_pos, core.hash_node_position(obstruct_pos)).name] then
				if lwireflag_tab[node2.name] and get_power(node2) < power2 then
					nodecache[hash2] = {name = node2.name, param2 = power2}
					fill_queue:enqueue({pos = pos2, power = power2})
				end
			-- else
			-- 	core.debug("wasted check:", tostring(pos2))
			end
		end
	end

	-- local nodes_changed = 0
	for hash, node in pairs(nodecache) do
		-- nodes_changed = nodes_changed + 1
		minetest.swap_node(minetest.get_position_from_hash(hash), node)
	end
end

function mcl_redstone.get_power(pos, dir)
	if not dir then
		return get_node_power_2(pos)
	end

	local pos2 = pos:add(dir)
	local node2 = minetest.get_node(pos2)

	if get_power_tab[node2.name] then
		local power2 = get_power_tab[node2.name](node2, -dir)
		return power2
	elseif lwireflag_tab[node2.name] then
		for wire_dir in iterate_wire_neighbours(lwireflag_tab[node2.name]) do
			if dir == -wire_dir.wire then
				return node2.param2
			end
		end
	elseif opaque_tab[node2.name] then
		local entry
		local max_power = 0
		for _, v in pairs(get_node_power_2_tab) do
			if v.dir == dir then
				entry = v
				break
			end
		end

		local always_check_node = minetest.get_node(pos + entry.always_check)

		if get_power_tab[always_check_node.name] then
			max_power = get_power_tab[always_check_node.name](always_check_node, -entry.dir)

			if max_power == 15 then
				return max_power
			end
		end

		for key, offset_pos in pairs(entry.conditional_checks) do
			local node3 = minetest.get_node(offset_pos + pos)

			if get_power_tab[node3.name] then
				local power2 = get_power_tab[node3.name](node3, -get_node_power_2_tab[key].dir)

				if power2 == 15 then
					return 15
				elseif power2 > max_power then
					max_power = power2
				end
			end
		end
		return max_power
	end

	return 0
end

local function schedule_update(pos, update)
	local delay = update.delay or 1
	local priority = update.priority or 1000
	local oldnode = minetest.get_node(pos)
	mcl_redstone._schedule_update(delay, priority, pos, update, oldnode)
end

local function call_init(pos)
	local node = minetest.get_node(pos)
	if init_tab[node.name] then
		local ret = init_tab[node.name](pos, node)
		if ret then
			schedule_update(pos, ret)
		end
	end
end

function mcl_redstone._call_update(pos)
	local node = minetest.get_node(pos)
	if update_tab[node.name] then
		local ret = update_tab[node.name](pos, node)
		if ret then
			schedule_update(pos, ret)
		end
	end
end

-- TODO: A bit ugly, could be refactored.
function mcl_redstone.update_node(pos)
	mcl_redstone._pending_updates[minetest.hash_node_position(pos)] = pos
end

-- Piston pusher nodes calls this during init to avoid circuits stopping if a
-- piston was extended just before a server restart. It is not a clean solution
-- but it works.
function mcl_redstone._update_neighbours(pos, oldnode)
	update_neighbours(pos, oldnode)
end

function mcl_redstone.swap_node(pos, node)
	local oldnode = minetest.get_node(pos)
	minetest.swap_node(pos, node)
	mcl_redstone._update_neighbours(pos, oldnode)
end

-- Update neighbouring wires and components at pos. Oldnode is the previous
-- node at the position.
function update_neighbours(pos, oldnode)
	local fill_queue
	local clear_queue
	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	local oldndef = oldnode and minetest.registered_nodes[oldnode.name]
	local get_power = ndef and ndef._mcl_redstone and ndef._mcl_redstone.get_power
	local old_get_power = oldndef and oldndef._mcl_redstone and oldndef._mcl_redstone.get_power

	local function update_wire(pos, oldpower)
		fill_queue = fill_queue or mcl_util.queue()
		clear_queue = clear_queue or mcl_util.queue()
		if oldpower then
			clear_queue:enqueue({pos = pos, power = oldpower})
		end
		local power = get_node_power_2(pos)

		fill_queue:enqueue({pos = pos, power = power})
	end

	local hash = minetest.hash_node_position(pos)
	mcl_redstone._pending_updates[hash] = update_tab[node.name] and pos or nil

	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = minetest.get_node(pos2)

		if opaque_tab[node2.name] or lwireflag_tab[node.name] or update_tab[node.name] or get_power_tab[node.name] then
			local power2 = get_power and get_power(node, dir) or 0
			local oldpower2 = old_get_power and old_get_power(oldnode, dir) or 0

			if power2 ~= oldpower2 then
				local hash2 = minetest.hash_node_position(pos2)

				mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
				if lwireflag_tab[node2.name] then
					update_wire(pos2, oldpower2)
				elseif opaque_tab[node2.name] then
					for i, dir in pairs(sixdirs) do
						local pos3 = pos2:add(dir)
						local node3 = minetest.get_node(pos3)
						local hash3 = minetest.hash_node_position(pos3)

						mcl_redstone._pending_updates[hash3] = update_tab[node3.name] and pos3 or nil
						if lwireflag_tab[node3.name] then
							update_wire(pos3, math.max(oldpower2, 0))
						end
					end
				end
			end
		end
	end

	if fill_queue then
		propagate_wire(clear_queue, fill_queue)
	end
end

local function opaque_update_neighbours(pos, added)
	local fill_queue
	local clear_queue

	local function update_wire(pos)
		fill_queue = fill_queue or mcl_util.queue()
		clear_queue = clear_queue or mcl_util.queue()

		local oldpower = minetest.get_node(pos).param2
		local power = get_node_power_2(pos)

		clear_queue:enqueue({pos = pos, power = oldpower})
		fill_queue:enqueue({pos = pos, power = power})
	end

	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = minetest.get_node(pos2)
		if wireflag_tab[node2.name] then
			update_wire(pos2)
		elseif update_tab[node2.name] then
			local hash2 = minetest.hash_node_position(pos2)
			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
		end
	end

	if fill_queue then
		propagate_wire(clear_queue, fill_queue)
	end
end

local function update_wire(pos, oldnode)
	local fill_queue = mcl_util.queue()
	local clear_queue = mcl_util.queue()
	local node = minetest.get_node(pos)
	local power = get_node_power_2(pos)

	clear_queue:enqueue({pos = pos, power = oldnode and oldnode.param2 or 0})
	if lwireflag_tab[node.name] then
		fill_queue:enqueue({pos = pos, power = power})
	end

	propagate_wire(clear_queue, fill_queue)
end

-- Override nodes to perform redstone updates on changes.
minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		local old_construct = ndef.on_construct
		local old_destruct = ndef.after_destruct
		if minetest.get_item_group(name, "opaque") ~= 0 and minetest.get_item_group(name, "solid") ~= 0 then
			minetest.override_item(name, {
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					mcl_redstone._update_opaque_connections(pos)
					mcl_redstone.after(0, function()
						opaque_update_neighbours(pos)
					end)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					mcl_redstone._update_opaque_connections(pos)
					mcl_redstone.after(0, function()
						opaque_update_neighbours(pos)
					end)
				end,
			})
		end

		if minetest.get_item_group(name, "redstone_wire") ~= 0 then
			local old_construct = ndef.on_construct
			local old_destruct = ndef.after_destruct
			minetest.override_item(name, {
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					update_wire(pos)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					update_wire(pos, oldnode)
				end,
			})
		end

		if ndef._mcl_redstone then
			local init = ndef._mcl_redstone.init or ndef._mcl_redstone.update
			get_power_tab[name] = ndef._mcl_redstone.get_power
			init_tab[name] = init
			update_tab[name] = ndef._mcl_redstone.update

			local old_construct = ndef.on_construct
			local old_destruct = ndef.after_destruct
			minetest.override_item(name, {
				groups = table.merge(ndef.groups, {
					redstone_init = init and 1,
					redstone_get_power = ndef._mcl_redstone.get_power and 1,
				}),
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					if ndef._mcl_redstone.connects_to then
						mcl_redstone._connect_with_wires(pos)
					end
					mcl_redstone._abort_pending_update(pos)
					mcl_redstone.after(0, function()
						if init then
							call_init(pos)
						end
						if ndef._mcl_redstone.get_power then
							update_neighbours(pos)
						end
					end)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					if ndef._mcl_redstone.connects_to then
						mcl_redstone._connect_with_wires(pos)
					end
					if ndef._mcl_redstone.get_power then
						mcl_redstone._abort_pending_update(pos)
						mcl_redstone.after(0, function()
							update_neighbours(pos, oldnode)
						end)
					end
				end,
			})
		end
	end
end)

minetest.register_lbm({
	label = "Perform redstone node initialization",
	name = "mcl_redstone:update",
	nodenames = {"group:redstone_init"},
	run_at_every_load = true,
	action = function(pos, node, dtime)
		call_init(pos)
	end,
})

minetest.register_lbm({
	label = "Perform redstone updates to neighbouring nodes",
	name = "mcl_redstone:update_neighbours",
	nodenames = {"group:redstone_get_power"},
	run_at_every_load = true,
	action = function(pos, node, dtime)
		update_neighbours(pos)
	end,
})
