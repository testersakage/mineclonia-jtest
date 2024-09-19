local function queue()
	return {
		front = 1,
		back = 1,
		queue = {},
		enqueue = function(self, value)
			self.queue[self.back] = value
			self.back = self.back + 1
		end,
		dequeue = function(self) local value = self.queue[self.front]
			if not value then
				return
			end
			self.queue[self.front] = nil
			self.front = self.front + 1
			return value
		end,
		size = function(self)
			return self.back - self.front
		end,
	}
end

local wiredir_tab = {}
local wire_fourdir_tab = {}
local wireflag_tab = {}
local opaque_tab = {}
local get_power_tab = {}
local update_tab = {}
local init_tab = {}

local function check_bit(n, b)
	return bit.band(n, bit.lshift(1, b)) ~= 0
end

local wireflag_dirs = {
	[0] = vector.new(0, 0, -1),
	[1] = vector.new(-1, 0, 0),
	[2] = vector.new(0, 0, 1),
	[3] = vector.new(1, 0, 0),
}

local function wireflags_to_fourdirs(wireflags)
	local dirs = {}
	for i = 0, 3 do
		if check_bit(wireflags, i) then
			table.insert(dirs, wireflag_dirs[i])
		end
	end

	return dirs
end

local function wireflags_to_dirs(wireflags)
	local dirs = {}
	for i = 0, 3 do
		if check_bit(wireflags, i) then
			local dir = wireflag_dirs[i]

			table.insert(dirs, {wire = dir})
			if check_bit(wireflags, i + 4) then -- wire going up
				table.insert(dirs, {
					wire = dir:offset(0, 1, 0),
					obstruct = vector.new(0, 1, 0),
				})
			else
				table.insert(dirs, {
					wire = dir:offset(0, -1, 0),
					obstruct = dir,
				})
			end
		end
	end

	return dirs
end

-- 0-3 correspond to the direction bits in wireflags.
local sixdirs = {
	[0] = vector.new(0, 0, 1),
	[1] = vector.new(1, 0, 0),
	[2] = vector.new(0, 0, -1),
	[3] = vector.new(-1, 0, 0),
	[4] = vector.new(0, -1, 0),
	[5] = vector.new(0, 1, 0),
}

local function get_node_power(pos, include_wire)
	local weak = 0
	local strong = 0
	for i, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)

		if get_power_tab[node2.name] then
			local power, is_strong = get_power_tab[node2.name](node2, -dir)

			weak = math.max(weak, power)
			if is_strong then
				strong = math.max(strong, power)
			end
		elseif include_wire and wireflag_tab[node2.name] and (i == 5 or check_bit(wireflag_tab[node2.name], i)) then
			-- Wire is above or pointing towards this node.
			weak = math.max(weak, node2.param2)
		end
	end

	return weak, strong
end

local function get_node_power_2(pos)
	local max = get_node_power(pos)
	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)

		if opaque_tab[node2.name] then
			-- Only strong power will go through opaque nodes.
			local _, power2 = get_node_power(pos2)
			max = math.max(max, power2 - 1)
		end
	end

	return max
end

-- Propagate redstone power through wires. 'clear_queue' is a queue of events
-- were power which is lowered/removed. 'fill_queue' is a queue of events were
-- power is added/raised. 'update' is a table which gets populated with
-- positions that should get redstone update events.
local function propagate_wire(clear_queue, fill_queue, updates)
	local updates_ = {}

	local function get_power(node)
		return wiredir_tab[node.name] and node.param2 or 0
	end

	while clear_queue:size() > 0 do
		local entry = clear_queue:dequeue()
		local pos = entry.pos
		local power = entry.power

		mcl_redstone._mapcache:set_param2(pos, 0)
		updates_[minetest.hash_node_position(pos)] = pos

		for _, dir in pairs(entry.dirs) do
			if not dir.obstruct or not opaque_tab[mcl_redstone._mapcache:get_node(pos:add(dir.obstruct)).name] then
				local pos2 = pos:add(dir.wire)
				local node2 = mcl_redstone._mapcache:get_node(pos2)
				local power2 = get_power(node2)

				if power2 > 0 then
					local dirs2 = wiredir_tab[node2.name]
					if power2 < power then
						clear_queue:enqueue({pos = pos2, power = power2, dirs = dirs2})
					else
						fill_queue:enqueue({pos = pos2, power = power2, dirs = dirs2})
					end
				end
			end
		end
	end

	while fill_queue:size() > 0 do
		local entry = fill_queue:dequeue()
		local pos = entry.pos
		local power = entry.power
		local power2 = power - 1

		mcl_redstone._mapcache:set_param2(pos, power)
		updates_[minetest.hash_node_position(pos)] = pos

		for _, dir in pairs(entry.dirs) do
			if not dir.obstruct or not opaque_tab[mcl_redstone._mapcache:get_node(pos:add(dir.obstruct)).name] then
				local pos2 = pos:add(dir.wire)
				local node2 = mcl_redstone._mapcache:get_node(pos2)
				local dirs2 = wiredir_tab[node2.name]

				if dirs2 and get_power(node2) < power2 then
					fill_queue:enqueue({pos = pos2, power = power2, dirs = dirs2})
				end
			end
		end
	end

	for _, pos in pairs(updates_) do
		for _, dir in pairs(sixdirs) do
			local pos2 = pos:add(dir)
			local node2 = mcl_redstone._mapcache:get_node(pos2)
			local hash2 = minetest.hash_node_position(pos2)

			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
			if opaque_tab[node2.name] then
				for _, dir in pairs(sixdirs) do
					local pos3 = pos2:add(dir)
					local node3 = mcl_redstone._mapcache:get_node(pos3)
					local hash3 = minetest.hash_node_position(pos3)

					mcl_redstone._pending_updates[hash3] = update_tab[node3.name] and pos3 or nil
				end
			end
		end
	end
end

function mcl_redstone.get_power(pos, dir)
	assert(mcl_redstone._mapcache, "mcl_redstone.get_power is only valid to call during redstone updates")

	local dirs = dir and {dir} or sixdirs
	local power = 0
	for _, dir in pairs(dirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)

		if get_power_tab[node2.name] then
			local power2 = get_power_tab[node2.name](node2, -dir)
			power = math.max(power, power2)
		elseif wiredir_tab[node2.name] then
			power = math.max(power, node2.param2)
		elseif opaque_tab[node2.name] then
			-- Only strong power goes through opaque nodes.
			power = math.max(power, get_node_power(pos2, true) - 1)
		end
	end

	return power
end

local function schedule_update(pos, update)
	local delay = update.delay or 1
	local priority = update.priority or 1000
	local oldnode = mcl_redstone._mapcache:get_node(pos)
	local param2 = update.param2 or 0

	mcl_redstone._schedule_event(delay, priority, pos, function()
		local node = mcl_redstone._mapcache:get_node(pos)
		if update.name == node.name and param2 == node.param2 then
			return
		end

		mcl_redstone._mapcache:set_node(pos, {
			name = update.name,
			param2 = update.param2,
		})
		update_neighbours(pos, oldnode)
	end)
end

function mcl_redstone.after(delay, func)
	mcl_redstone._schedule_event(delay, nil, nil, func)
end

local function call_init(pos)
	local node = mcl_redstone._mapcache:get_node(pos)
	if init_tab[node.name] then
		local ret = init_tab[node.name](pos, node)
		if ret then
			schedule_update(pos, ret)
		end
	end
end

function mcl_redstone._call_update(pos)
	local node = mcl_redstone._mapcache:get_node(pos)
	if update_tab[node.name] then
		local ret = update_tab[node.name](pos, node)
		if ret then
			schedule_update(pos, ret)
		end
	end
end

-- Piston pusher nodes calls this during init to avoid circuits stopping if a
-- piston was extended just before a server restart. It is not a clean solution
-- but it works.
function mcl_redstone._update_neighbours(pos, oldnode)
	mcl_redstone._schedule_event(0, -1, pos, function()
		update_neighbours(pos, oldnode)
	end)
end

function mcl_redstone.swap_node(pos, node)
	minetest.swap_node(pos, node)
	mcl_redstone._update_neighbours(pos, node)
end

local function get_wire_power(pos)
	local max = get_node_power(pos)
	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)

		if opaque_tab[node2.name] then
			local _, power2 = get_node_power(pos2)
			max = math.max(max, power2 - 1)
		end
	end

	return max
end

function update_neighbours(pos, oldnode)
	local fill_queue = queue()
	local clear_queue = queue()
	local node = mcl_redstone._mapcache:get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	local oldndef = oldnode and minetest.registered_nodes[oldnode.name]
	local get_power = ndef and ndef._redstone and ndef._redstone.get_power
	local old_get_power = oldndef and oldndef._redstone and oldndef._redstone.get_power

	local function update_wire(pos, oldpower, dirs)
		if oldpower then clear_queue:enqueue({pos = pos, power = oldpower, dirs = dirs}) end
		fill_queue:enqueue({pos = pos, power = get_wire_power(pos), dirs = dirs})
	end

	local hash = minetest.hash_node_position(pos)
	mcl_redstone._pending_updates[hash] = update_tab[node.name] and pos or nil

	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local power2 = get_power and get_power(node, dir) or 0
		local oldpower2 = old_get_power and old_get_power(oldnode, dir) or 0

		if power2 ~= oldpower2 then
			local node2 = mcl_redstone._mapcache:get_node(pos2)
			local hash2 = minetest.hash_node_position(pos2)

			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
			if wiredir_tab[node2.name] then
				update_wire(pos2, oldpower2, wiredir_tab[node2.name])
			elseif opaque_tab[node2.name] then
				for i, dir in pairs(sixdirs) do
					local pos3 = pos2:add(dir)
					local node3 = mcl_redstone._mapcache:get_node(pos3)
					local hash3 = minetest.hash_node_position(pos3)

					mcl_redstone._pending_updates[hash3] = update_tab[node3.name] and pos3 or nil
					if wiredir_tab[node3.name] then
						update_wire(pos3, math.max(oldpower2 - 1, 0), wiredir_tab[node3.name])
					end
				end
			end
		end
	end

	propagate_wire(clear_queue, fill_queue)
end

local function opaque_update_neighbours(pos, added)
	local fill_queue = queue()
	local clear_queue = queue()

	local function update_wire(pos, oldpower, dirs)
		if oldpower then clear_queue:enqueue({pos = pos, power = oldpower, dirs = dirs}) end
		fill_queue:enqueue({pos = pos, power = get_node_power_2(pos), dirs = dirs})
	end

	local power = 0
	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)
		if get_power_tab[node2.name] then
			local power2 = get_power_tab[node2.name](node2, -dir)
			power = math.max(power, power2)
		end
	end
	if power == 0 then
		return
	end

	for _, dir in pairs(sixdirs) do
		local pos2 = pos:add(dir)
		local node2 = mcl_redstone._mapcache:get_node(pos2)
		if wiredir_tab[node2.name] then
			update_wire(pos2, not added and power or nil, wiredir_tab[node2.name])
		elseif update_tab[node2.name] then
			local hash2 = minetest.hash_node_position(pos2)
			mcl_redstone._pending_updates[hash2] = update_tab[node2.name] and pos2 or nil
		end
	end

	propagate_wire(clear_queue, fill_queue)
end

local function update_wire(pos, oldnode)
	local fill_queue = queue()
	local clear_queue = queue()
	local node = mcl_redstone._mapcache:get_node(pos)
	local dirs = wiredir_tab[node.name]
	local olddirs = oldnode and wiredir_tab[oldnode.name] or dirs

	clear_queue:enqueue({pos = pos, power = oldnode and oldnode.param2 or 0, dirs = olddirs})
	if dirs then
		local fourdirs = wire_fourdir_tab[node.name]
		fill_queue:enqueue({pos = pos, power = get_wire_power(pos, fourdirs), dirs = dirs})
	end

	propagate_wire(clear_queue, fill_queue)
end

-- Override nodes to perform redstone updates on changes.
minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		local old_construct = ndef.on_construct
		local old_destruct = ndef.on_destruct
		if minetest.get_item_group(name, "opaque") ~= 0 and minetest.get_item_group(name, "solid") ~= 0 then
			opaque_tab[name] = true
			minetest.override_item(name, {
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					mcl_redstone._schedule_event(0, -1, pos, function()
						opaque_update_neighbours(pos)
					end)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					mcl_redstone._schedule_event(0, -1, pos, function()
						opaque_update_neighbours(pos)
					end)
				end,
			})
		end

		if minetest.get_item_group(name, "redstone_wire") ~= 0 then
			wireflag_tab[name] = ndef._logical_wireflags
			wiredir_tab[name] = wireflags_to_dirs(ndef._logical_wireflags)
			wire_fourdir_tab[name] = wireflags_to_fourdirs(ndef._logical_wireflags)

			local old_construct = ndef.on_construct
			local old_destruct = ndef.after_destruct
			minetest.override_item(name, {
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					mcl_redstone._schedule_event(0, -1, pos, function()
						update_wire(pos)
					end)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					mcl_redstone._schedule_event(0, -1, pos, function()
						update_wire(pos, oldnode)
					end)
				end,
			})
		end

		if ndef._redstone then
			local init = ndef._redstone.init or ndef._redstone.update
			get_power_tab[name] = ndef._redstone.get_power
			init_tab[name] = init
			update_tab[name] = ndef._redstone.update

			local old_construct = ndef.on_construct
			local old_destruct = ndef.after_destruct
			minetest.override_item(name, {
				groups = table.merge(ndef.groups, {
					redstone_init = init and 1,
					redstone_get_power = ndef._redstone.get_power and 1,
				}),
				on_construct = function(pos)
					if old_construct then
						old_construct(pos)
					end
					mcl_redstone._schedule_event(0, -1, pos, function()
						if init then
							call_init(pos)
						end
						if ndef._redstone.get_power then
							update_neighbours(pos)
						end
					end)
				end,
				after_destruct = function(pos, oldnode)
					if old_destruct then
						old_destruct(pos, oldnode)
					end
					if ndef._redstone.get_power then
						mcl_redstone._schedule_event(0, -1, pos, function()
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
		mcl_redstone._schedule_event(0, -1, pos, function()
			call_init(pos)
		end)
	end,
})

minetest.register_lbm({
	label = "Perform redstone updates to neighbouring nodes",
	name = "mcl_redstone:update_neighbours",
	nodenames = {"group:redstone_get_power"},
	run_at_every_load = true,
	action = function(pos, node, dtime)
		mcl_redstone._schedule_event(0, -1, pos, function()
			update_neighbours(pos)
		end)
	end,
})
