

-- changes wishlist:
-- * make the propagation cache more durable, so when an node in `update_positions` is broken. The whole cache dosent have to
-- be regenerated. And also a way to append `update_positions` to the caches
-- * some kind of heuristic to remeove uneeded caches, or caches that are likely never going to be reused
-- * maybe have different types of caches that are less complex/memory intensive for common use cases. For example
-- a straigh redstone line could just store it's start and end position
-- * propagate_cache_positions can have uncollected caches in it. hmmm, manually resetting the cache is kinda impossible
-- when you take opaque blocks into consideration

local wireflag_tab = mcl_redstone._wireflag_tab

-- True if node is opaque by contentid
local opaque_tab = mcl_redstone._solid_opaque_tab
local update_tab = {}

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

-- cache for wire propagation
-- a table with keys being the wire position hash for the cache's root, and values being a table with format:
-- * wire_positions - list that has positions of each wire
-- * wire_ranges - table where the key is the power level, and the value is an index in the `wire_positions` list.
--   if the key is 15 and value 17, then it means first 17 wires would be affected by that power level
-- * wire_neighbours - list of elements that correspond to the wire_positions table. the elements are lists of indexes in the
--   wire_positions table of neighbouring wires. wire_neighbours may have holes if the wire at that index dosent have any neighbours.
--   Also wires that were already traversed arent in this table. I.e no backtracking
-- * update_positions - list of positions to be updated
-- * update_ranges - analagous to wire_ranges
-- * current_state - current power level
-- * hash - hash position of the root
--
-- notes:
-- Be very careful when copying elements from this table. It might cause problems when the cache gets invalidated
-- If you do copy an element, make sure to not save it anywhere, so it can be turned into garbage and be collected
local propagate_cache = {}

-- table containing positions that make up nodes inside the propagate_cache table
-- its a weak table so if the propagate_cache element is ever invalidated, then the positions will too
local propagate_cache_positions = setmetatable({}, {__mode = "v"})

mcl_redstone.propagate_cache = propagate_cache
mcl_redstone.propagate_cache_positions = propagate_cache_positions

-- list of positions to propagate in the next tick
local propagate_tab = {}

-- instead of clearing the propagate_tab each tick, recycle the table by overriding already existing values and clearing any leftovers
-- this reduces the GC work
local propagate_tab_length = 0

-- Propagate redstone power through wires
function mcl_redstone.propagate_wire(pos, new_power)
	propagate_tab_length = propagate_tab_length + 1
	propagate_tab[propagate_tab_length] = {pos = pos, power = new_power}
end

function mcl_redstone.invalidate_propagation_cache(h)
	if propagate_cache_positions[h] then
		core.debug("cache discarded", tostring(core.get_position_from_hash(propagate_cache_positions[h].hash)))
		propagate_cache[propagate_cache_positions[h].hash] = nil
	end
end

-- traverses redstone the given pos and generates a cache for it
--
-- this function directly modifies propagate_cache and propagate_cache_positions tables. Meaning it has an effect on the map
-- regardless of how you use the returned value
local function generate_propagation_cache(pos, nodecache)
	local hash = core.hash_node_position(pos)
	nodecache = nodecache or {}

	local function get_node(pos, hash)
		hash = hash or core.hash_node_position(pos)
		if not nodecache[hash] then
			nodecache[hash] = minetest.get_node(pos)
		end
		return nodecache[hash]
	end

	local cache =
	{wire_positions = {pos}, wire_ranges = {1}, wire_neighbours = {},
	update_positions = {}, update_ranges = {}, current_state = get_node(pos).param2, hash = hash}

	local idx = 1
	local next_power_idx = 1
	local same_power_count = 0
	local current_power = 15

	-- set of already already traversed redstone dust
	local already_traversed = {}
	already_traversed[hash] = true


	-- traverse all dust until you reach the desired power level
	while(current_power ~= 0 and cache.wire_positions[idx]) do
		local pos2 = cache.wire_positions[idx]
		local hash2 = core.hash_node_position(pos2)
		local node2 = get_node(pos2, hash2)

		propagate_cache_positions[hash2] = cache

		-- core.debug(dump(node2))
		-- core.debug("ITER", tostring(pos2))
		for dir in iterate_wire_neighbours(wireflag_tab[node2.name] or 0xF) do
			local pos3 = pos2:add(dir.wire)
			local hash3 = core.hash_node_position(pos3)
			-- core.debug(tostring(pos3), hash3)
			local node3 = get_node(pos3, hash3)
			if wireflag_tab[node3.name] and not already_traversed[hash3] then
				local obstruct_pos = dir.obstruct and pos2:add(dir.obstruct)
				if not dir.obstruct or not opaque_tab[get_node(obstruct_pos, core.hash_node_position(obstruct_pos))] then
					-- core.debug("CAN POINT")
					same_power_count = same_power_count + 1
					already_traversed[hash3] = true
					cache.wire_positions[#cache.wire_positions + 1] = pos3
					if cache.wire_neighbours[idx] then
						table.insert(cache.wire_neighbours[idx], #cache.wire_positions)
					else
						cache.wire_neighbours[idx] = {#cache.wire_positions}
					end
				end
			elseif opaque_tab[node3.name] then
				for _, dir in pairs(sixdirs) do
					local pos4 = pos3:add(dir)
					local hash4 = core.hash_node_position(pos4)
					local node4 = get_node(pos4, hash4)

					if update_tab[node4.name] and not already_traversed[hash4] then
						cache.update_positions[#cache.update_positions + 1] = pos4
						already_traversed[hash4] = true
						propagate_cache_positions[hash4] = cache
						-- core.debug("update cached: opaque", tostring(pos4))
						-- the opaque block is now considered a part of the cache, so when its removed. the cache will
						-- be invalidated
						propagate_cache_positions[hash3] = cache
					end
				end
			end

			if update_tab[node3.name] and not already_traversed[hash3] then
				-- core.debug("update cached: direct", tostring(pos3))
				cache.update_positions[#cache.update_positions + 1] = pos3
				already_traversed[hash3] = true
				propagate_cache_positions[hash3] = cache
			end

		end
		-- core.debug(idx, next_power_idx, same_power_count, current_power, #cache.wire_positions)
		if next_power_idx == idx then
			if same_power_count ~= 0 then
				-- core.debug("power level dropped", current_power, dump(cache.update_positions))
				-- core.debug("add", same_power_count)
				cache.wire_ranges[#cache.wire_ranges + 1] = #cache.wire_positions
				next_power_idx = next_power_idx + same_power_count
				current_power = current_power - 1
				same_power_count = 0
			end
			cache.update_ranges[#cache.update_ranges + 1] = #cache.update_positions
		end

		idx = idx + 1
	end

	propagate_cache[hash] = cache

	return cache
end

function mcl_redstone.process_wires()
	local nodecache = {}

	local function get_node(pos, hash)
		hash = hash or core.hash_node_position(pos)
		if not nodecache[hash] then
			nodecache[hash] = minetest.get_node(pos)
		end
		return nodecache[hash]
	end

	-- clearing any potential left overs
	for i = propagate_tab_length + 1, #propagate_tab do
		propagate_tab[i] = nil
	end

	local generated_caches = 0
	local total_processed = 0

	for _, entry in pairs(propagate_tab) do
		total_processed = total_processed + 1
		-- core.debug("ITER")
		local hash = core.hash_node_position(entry.pos)
		local cache = propagate_cache[hash]
		if not cache then
			generated_caches = generated_caches + 1
			cache = generate_propagation_cache(entry.pos, nodecache)
		end

		local old_power = cache.current_state

		-- core.debug(entry.power, cache.current_state)
		-- core.debug("HII", dump(cache))

		local current_power = entry.power
		local power_idx = 1
		-- set power level
		-- dbg.pp("cache", cache)
		-- dbg.pp("power", old_power, entry.power)
		if entry.power ~= 0 then
			for idx = 1, cache.wire_ranges[entry.power] or cache.wire_ranges[#cache.wire_ranges] do
				-- dbg.pp("idx", idx)
				core.swap_node(cache.wire_positions[idx], {name = get_node(cache.wire_positions[idx]).name, param2 = current_power})
				if idx == cache.wire_ranges[power_idx] then
					-- dbg.pp("decreasing power", idx)
					current_power = current_power - 1
					power_idx = power_idx + 1
				end
			end

			-- power/update all the nodes
			if #cache.update_positions ~= 0 then
				for i = 1, cache.update_ranges[entry.power] or cache.update_ranges[#cache.update_ranges] do
					mcl_redstone._pending_updates[core.hash_node_position(cache.update_positions[i])] = cache.update_positions[i]
					-- core.debug("AH", cache.update_positions[i], dump(mcl_redstone._pending_updates))
				end
			end
		end

		-- remove old power
		if old_power > entry.power then
			for idx = power_idx, cache.wire_ranges[old_power] or cache.wire_ranges[#cache.wire_ranges] do
				core.swap_node(cache.wire_positions[idx], {name = get_node(cache.wire_positions[idx]).name, param2 = 0})
			end

			-- power/update all the nodes
			if #cache.update_positions ~= 0 then
				for i = power_idx, cache.update_ranges[old_power] or (#cache.update_ranges < old_power and cache.update_ranges[#cache.update_ranges]) do
					mcl_redstone._pending_updates[core.hash_node_position(cache.update_positions[i])] = cache.update_positions[i]
					-- core.debug("removed", cache.update_positions[i], dump(mcl_redstone._pending_updates))
				end
			end
		end

		cache.current_state = entry.power
		-- core.debug("POST", dump(cache.current_state))

	end

	propagate_tab_length = 0

	return total_processed, generated_caches
end

function mcl_redstone.update_wire_power(pos, node)
	local hash = core.hash_node_position(pos)

	local cache = propagate_cache_positions[hash]

	if cache then
		-- this means a wire within the cache got broken

		if cache.hash == hash then
			-- this means the root of the cache got broken
			mcl_redstone.invalidate_propagation_cache(hash)

			for _, clear_pos in pairs(cache.wire_positions) do
				local clear_hash = core.hash_node_position(clear_pos)
				mcl_redstone.propagate_cache_positions[clear_hash] = nil
				core.swap_node(clear_pos, {name = core.get_node(clear_pos).name, param2 = 0})
			end

			for _, update_pos in pairs(cache.update_positions) do
				local update_hash = core.hash_node_position(update_pos)
				mcl_redstone.propagate_cache_positions[update_hash] = nil
				mcl_redstone._pending_updates[hash] = update_pos
			end

			return
		end

		local cache_root = core.get_position_from_hash(cache.hash)

		local old_cache = cache
		mcl_redstone.invalidate_propagation_cache(hash)
		local new_cache = generate_propagation_cache(cache_root)

		-- note: there is a micro optimization to be done below:
		-- start iterating from the earlier redstonee dust that has the same power level as the one you just broke
		-- because wires closer to the root couldnt have been disconnected

		-- clear disconnected wires
		local clear_tab = {}

		for _, v in pairs(old_cache.wire_positions) do
			clear_tab[core.hash_node_position(v)] = v
		end

		for _, v in pairs(new_cache.wire_positions) do
			clear_tab[core.hash_node_position(v)] = nil
		end

		for clear_hash, clear_pos in pairs(clear_tab) do
			mcl_redstone.propagate_cache_positions[clear_hash] = nil
			core.swap_node(clear_pos, {name = core.get_node(clear_pos).name, param2 = 0})
		end

		-- update disconnected components
		local update_tab = {}

		for _, v in pairs(old_cache.update_positions) do
			update_tab[core.hash_node_position(v)] = v
		end

		for _, v in pairs(new_cache.update_positions) do
			update_tab[core.hash_node_position(v)] = nil
		end

		for update_hash, update_pos in pairs(update_tab) do
			mcl_redstone.propagate_cache_positions[update_hash] = nil
			mcl_redstone._pending_updates[update_hash] = update_pos
		end

		return
	end

	for dir in iterate_wire_neighbours(wireflag_tab[node.name] or 0xFF) do
		local pos2 = pos:add(dir.wire)
		-- core.debug(tostring(pos2))
		local hash2 = core.hash_node_position(pos2)
		cache = propagate_cache_positions[hash2]
		if cache then
			local cache_state = cache.current_state
			local cache_root = core.get_position_from_hash(cache.hash)

			-- core.debug("??", tostring(pos2))
			mcl_redstone.invalidate_propagation_cache(hash2)
			-- core.debug("!?!", tostring(cache_root), cache_state)
			mcl_redstone.propagate_wire(cache_root, cache_state)
		end
	end
end

core.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		if ndef._mcl_redstone then
			update_tab[name] = ndef._mcl_redstone.update
		end
	end
end)
