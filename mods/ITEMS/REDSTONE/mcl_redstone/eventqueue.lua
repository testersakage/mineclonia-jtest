mcl_redstone.tick_speed = tonumber(minetest.settings:get("mcl_redstone_update_tick")) or 0.1
local UPDATE_RANGE = (tonumber(minetest.settings:get("mcl_redstone_update_range")) or 8) * 16
local MAX_EVENTS = tonumber(minetest.settings:get("mcl_redstone_max_events")) or 65535
local TIME_BUDGET = math.max(0.01, mcl_redstone.tick_speed * (tonumber(minetest.settings:get("mcl_redstone_time_budget")) or 0.2))

mcl_redstone.is_tick_frozen = false

mcl_redstone._pending_updates = {}

local function priority_queue()
	local priority_queue = {
		heap = {},
	}

	function priority_queue:enqueue(prio, val)
		table.insert(self.heap, { val = val, prio = prio })

		local i = #self.heap
		while i ~= 1 and self.heap[math.floor(i / 2)].prio > self.heap[i].prio do
			local p = math.floor(i / 2)
			self.heap[i], self.heap[p] = self.heap[p], self.heap[i]
			i = p
		end
	end

	local function heapify(heap, i)
		local l = math.floor(2 * i)
		local r = math.floor(2 * i + 1)
		local min = i

		if l <= #heap and heap[l].prio < heap[i].prio then
			min = l
		end
		if r <= #heap and heap[r].prio < heap[min].prio then
			min = r
		end
		if min ~= i then
			heap[i], heap[min] = heap[min], heap[i]
			heapify(heap, min)
		end
	end

	function priority_queue:dequeue()
		if #self.heap == 0 then
			return nil
		end

		local root = self.heap[1]
		self.heap[1] = self.heap[#self.heap]
		self.heap[#self.heap] = nil
		heapify(self.heap, 1)

		return root.val
	end

	function priority_queue:peek()
		return #self.heap ~= 0 and self.heap[1].val or nil
	end

	function priority_queue:size()
		return #self.heap
	end

	return priority_queue
end

local eventqueue = priority_queue()
local current_tick = 0

-- Table containing the highest priority event for each node position.
local node_event_tab = {}

function mcl_redstone._schedule_event(delay, priority, pos, func)
	local tick = current_tick + delay
	local event = {
		pos = pos,
		tick = tick,
		priority = priority,
		func = func,
	}

	if priority then
		local h = minetest.hash_node_position(pos)

		-- Priority -1 is hardcoded to allow multiple pending events. This is
		-- because it is used for by con/destruct callbacks which require that
		-- construct events happen after destruct events.
		if node_event_tab[h] and (priority ~= -1 and node_event_tab[h].priority <= priority) then
			return
		end
		node_event_tab[h] = event
	end
	eventqueue:enqueue(tick, event)
end

local function clear_event(event)
	if not event.pos then
		return
	end
	local hash = minetest.hash_node_position(event.pos)
	if node_event_tab[hash] == event then
		node_event_tab[hash] = nil
	end
end

local function clear_all_pending_events()
	node_event_tab = {}
	while eventqueue:size() > 0 do
		eventqueue:dequeue()
	end
end

local function is_prioritized(event)
	if not event.pos then
		return true
	end
	local hash = minetest.hash_node_position(event.pos)
	return event.priority == -1 or event == node_event_tab[hash]
end

local function get_time()
	return minetest.get_us_time() / 1e6
end

local function debug_log(tick, nevents, nupdates, nfaraway, npending, time, aborted)
	if not minetest.settings:get_bool("mcl_redstone_debug_eventqueue", false)
			or (nevents == 0 and nupdates == 0) then
		return
	end

	local saborted = aborted and ", was aborted" or ""
	local sfaraway = nfaraway ~= 0 and string.format(", %d far away events", nfaraway) or ""
	minetest.log(string.format(
		"[mcl_redstone] tick %d, %d events and %d updates processed%s, %d pending events, took %f ms%s",
		tick,
		nevents,
		nupdates,
		sfaraway,
		npending,
		time / 1000,
		saborted
	))
end

function mcl_redstone.tick_step()
	local player_poses = {}
	for _, player in pairs(minetest.get_connected_players()) do
		table.insert(player_poses, player:get_pos())
	end

	local function too_far_away(event)
		local distance = 0
		for _, player_pos in pairs(player_poses) do
			distance = math.max(distance, vector.distance(event.pos, player_pos))
		end
		return distance > UPDATE_RANGE
	end

	if eventqueue:size() > MAX_EVENTS then
		minetest.log("error", string.format("[mcl_redstone]: Maximum number of queued redstone events (%d) exceeded, deleting all of them.", MAX_EVENTS))
		clear_all_pending_events()
	end

	local starttime = get_time()
	local endtime = starttime + TIME_BUDGET
	local nevents = 0
	local nupdates = 0
	local nfaraway = 0

	local function log_redstone_events(aborted)
		local time = get_time() - starttime
		local npending = eventqueue:size()

		debug_log(current_tick, nevents, nupdates, nfaraway, npending, time, aborted)
	end

	local last_tick = current_tick
	while eventqueue:size() > 0 and eventqueue:peek().tick <= current_tick do
		if get_time() > endtime then
			log_redstone_events(true)
			return
		end

		local event = eventqueue:dequeue()
		if is_prioritized(event) then
			clear_event(event)
			if event.pos and too_far_away(event) then
				nfaraway = nfaraway + 1
			else
				nevents = nevents + 1
				event.func()
			end
		end
		last_tick = event.tick
	end

	for h, pos in pairs(mcl_redstone._pending_updates) do
		if get_time() > endtime then
			log_redstone_events(true)
			return
		end

		nupdates = nupdates + 1
		mcl_redstone.schedule_update(pos)
		mcl_redstone._pending_updates[h] = nil
	end

	log_redstone_events(false)
	current_tick = last_tick + 1
end

minetest.register_chatcommand("tick",
{
	description = "Allows to stop redstone ticking, speed it up, or freezing it. Note that \"ticks\" in this command actually refer to redstone ticks",
	params = "step [ticks] | sprint <ticks> | freeze | unfreeze | rate <seconds per tick> | query",
	privs = {server = true},
	func = function(name, param)
		local _, end_pos, operation = string.find(param, "^%s*(%a+)")
		local _, _, arg = string.find(param, "^%s*([%a%d.]+)", end_pos + 1)

		if operation == "query" then
			return true, mcl_redstone.tick_speed
		elseif operation == "freeze" then
			mcl_redstone.is_tick_frozen = true
			return true
		elseif operation == "unfreeze" then
			mcl_redstone.is_tick_frozen = false
			return true
		elseif operation == "reset" then
			mcl_redstone.tick_speed = tonumber(minetest.settings:get("mcl_redstone_update_tick")) or 0.1
			return true
		elseif operation == "rate" then
			if tonumber(arg) then
				mcl_redstone.tick_speed = tonumber(arg)
				return true
			else
				return false, "second argument must be a number"
			end
		elseif operation == "sprint" then
			if mcl_redstone.is_tick_frozen then
				if tonumber(arg) then
					local timer = minetest.get_us_time()
					for i = 1, tonumber(arg) do
						mcl_redstone.tick_step()
					end
					return true, string.format("sprint finished: took %sms", (minetest.get_us_time() - timer) / 1000)
				else
					return false, "second argument must be a number"
				end
			else
				return false, "tick step can only be used when ticking is frozen"
			end
		elseif operation == "step" then
			if mcl_redstone.is_tick_frozen then
				if tonumber(arg) then
					mcl_redstone.is_tick_frozen = false
					mcl_redstone.after(tonumber(arg), function() mcl_redstone.is_tick_frozen = true end)
					return true
				elseif arg == nil then
					mcl_redstone.tick_step()
					return true
				else
					return false, "second argument must be a number"
				end
			else
				return false, "tick step can only be used when ticking is frozen"
			end
		end

		return false
	end
})

local timer = 0
minetest.register_globalstep(function(dtime)
	if not mcl_redstone.is_tick_frozen then
		timer = timer + dtime
		if timer < mcl_redstone.tick_speed then
			return
		end
		timer = timer - mcl_redstone.tick_speed

		mcl_redstone.tick_step()
	end
end)
