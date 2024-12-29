

local liquid = {
	registered_liquids = {},
	-- A list of registered liquids

	running = true,
	-- This is the initial state of the liquid transformation mod.
	-- If set to false, liquids do not flow until they activated.

	tick = 1.0
	-- The main tick speed. Changing that tick affects all liquids
	-- proportionally.
}

-- This counter is used generate unique names
local resume_counter = 1


function liquid.register_liquid(def)
	-- This function generates a new liquid transformation.

	local def_flowing = def.ndef_flowing
	local def_source = def.ndef_source

	local wait_count = 0

	local modname = minetest.get_current_modname()

	local NAME_SOURCE  = def.name_source
	assert(NAME_SOURCE, '"name_source" was nil')

	local NAME_FLOWING = def.name_flowing
	assert(NAME_FLOWING, '"name_flowing" was nil ')

	local FLOW_DISTANCE = def.liquid_range or 7
	assert(FLOW_DISTANCE >= 0 and FLOW_DISTANCE < 8,
		'The liquid_range must be in range [0 <= x < 8]')

	local RENEWABLE = def.liquid_renewable or false
	local TICKS			= (def.liquid_tick or 0.5) * liquid.tick


	-- This table is a function that calculates then next lower liquid level.
	local level_tb = {}
	for i = 0, 9 do
		level_tb[i+1] = math.round(math.floor(i * (FLOW_DISTANCE+1) /  8) * 8 / (FLOW_DISTANCE+1))
	end

	local update_next_set = {}

	local changed_nodes = {}
	local read_nodes = {}


	local function update_next(item)
		local h = core.hash_node_position(item.pos)
		if update_next_set[h] == nil then
			update_next_set[h] = item
		end
	end


	local function get_liquid_level(node)
		-- This function returns the level of a liquid node or nil if it isn't a
		-- liquid node

		if node.name == NAME_SOURCE then
			return 8
		elseif node.name == NAME_FLOWING then
			if bit.band(node.param2, 0x08) ~= 0 then
				return 8
			else 
				return bit.band(node.param2, 0x07)
			end
		else
			return nil
		end 
	end


	local function set_node(pos, node)
		-- This function puts the new node into a map.
		-- If there is already a node in that map at the same location, the one
		-- with the larger level wins. This is important do ensure symmetric flow
		-- if the underlying structure is symmetric as well. It also prevents weird
		-- things from happening like half level liquids lingering around.


		local h = core.hash_node_position(pos)
		local other = changed_nodes[h]

		if not other then
			changed_nodes[h] = node
		else
			local ln = get_liquid_level(node)  or 0
			local lo = get_liquid_level(other) or 0

			if ln > lo then
				changed_nodes[h] = node
			end
		end
	end

	local function get_node(pos)
		-- This function is the just the cached version of the `core.get_node()`

		local h = core.hash_node_position(pos)
		local node = read_nodes[h]

		if node then
			return node
		else
			node = core.get_node(pos)
			read_nodes[h] = node
			return node
		end
	end



	local function is_liquid(node)
		return node.name == NAME_SOURCE or node.name == NAME_FLOWING
	end


	local function make_liquid(level)
		-- This function creates a new liquid node

		if level == 8 or level == 'down' then
			return {
				name = NAME_FLOWING,
				param2 = 8,
			}

		elseif level == 'source' then
			return {
				name = NAME_SOURCE,
			}

		elseif level <= 0 then
			return {
				name = 'air'
			}

		else
			return {
				name = NAME_FLOWING,
				param2 = bit.band(level, 0x07),
			}

		end
	end


	local function is_floodable(n)
		-- This function tests if the node is floodable in theory. For the final
		-- decisions, other factors are in play as well.

		if n.name == 'air' or n.name == NAME_SOURCE or n.name == NAME_FLOWING then
			return 1
		elseif n.name == 'ignore' then
			return nil
		else
			local ndef = core.registered_nodes[n.name]
			if ndef and ndef.floodable then
				return 1
			end
		end
		return 0
	end


	local function path_find(pos, slope_dist)
		-- This function searches the nearest slopes within a maximum path distance
		-- of 5 nodes. 

		-- The list of nodes to be updated next.
		local list = {}

		-- The map of potential liquid levels.
		local pmap = {}

		-- An array with nodes that hit a slope.
		local found = {}

		-- The map containing the real paths (decreasing liquid levels from origin
		-- to slope) (the result)
		local rmap = {}

		local function step(pos, level)
			-- This function checks if the current position has an obstacle or a
			-- slope.

			local h = core.hash_node_position(pos)
			if pmap[h] == nil then
				local n1 = get_node(pos)
				local n2= get_node(vector.offset(pos,  0,-1, 0))

				local l1 = n1 and get_liquid_level(n1)

				local f1 = n1 and is_floodable(n1)
				local f2 = n2 and is_floodable(n2)

				if f1 == 1 and f2 == 1 then 
					found[#found+1] = pos
					list[#list+1] = pos
					pmap[h] = level
				elseif f1 == 1 and (l1 or 0) <= level then
					list[#list+1] = pos
					pmap[h] = level
				end
			end
		end

		local orig_level = get_liquid_level(get_node(pos))

		pmap[core.hash_node_position(pos)] = orig_level

		local level = orig_level
		if level <= 1 then
			-- If level of the origin is too small we return a dummy map. 
			return function (pos) return nil end
		end

		list[#list+1] = pos

		for i = 1, 5 do

			local l = list
			list = {}

			-- Decrease the liquid level.
			level = level_tb[level]

			if level == 0 or #found > 0 then
				-- condition for ending the loop earlier.
				break
			end

			for i, p in ipairs(l) do
				-- Step into all 4 directions
				step(vector.offset(p, -1, 0, 0), level)
				step(vector.offset(p,  1, 0, 0), level)
				step(vector.offset(p,  0, 0,-1), level)
				step(vector.offset(p,  0, 0, 1), level)
			end
		end 

		if #found == 0 then
			-- If we hit the minimum level without finding a slope. The liquid shall
			-- flow in all directions where there is no obstacle. The potential map
			-- becomes the real map.
			rmap = pmap
		else 
			-- If a slope within range was found we need to remove all levels that
			-- are not part of the shortest path to those slopes.

			list = found

			while #list > 0 do
			--for nlevel = level, orig_level do
				local l = list
				list = {}
				for i, p in ipairs(l) do
					local h = core.hash_node_position(p)
					local level = pmap[h]
					rmap[h] = level

					local function back_trace(p)
						local h = core.hash_node_position(p)
						local m = pmap[h]
						if m and m > level then
							list[#list+1] = p
						end
					end

					-- Search the origin.
					back_trace(vector.offset(p, -1, 0, 0))
					back_trace(vector.offset(p,  1, 0, 0))
					back_trace(vector.offset(p,  0, 0,-1))
					back_trace(vector.offset(p,  0, 0, 1))
				end
			end
		end

		--core.log('--------------------------')
		--for x = -8,8 do
		--	line = '| '
		--	for z = -8,8 do
		--		local h = core.hash_node_position(pos + vector.new(x, 0, z))
		--		local level = rmap[h]
		--		if level then
		--			line = line..level..' '
		--		elseif pmap[h] then
		--			line = line..'. '
		--		else
		--			line = line..'	'
		--		end
		--	end
		--	line = line..' |'
		--	core.log(line)
		--end


		return function (pos)
			return rmap[core.hash_node_position(pos)]
		end
	end


	local function flow_iteration(item)

		local pos = item.pos
		local map = item.map
		local is_sinking = item.is_sinking

		local p111 = pos
		local n111 = get_node(p111)
		if n111.name == 'ignore' then
			return
		end

		local p011 = vector.offset(pos, -1,  0,  0)
		local p211 = vector.offset(pos,  1,  0,  0)
		local p101 = vector.offset(pos,  0, -1,  0)
		local p121 = vector.offset(pos,  0,  1,  0)
		local p110 = vector.offset(pos,  0,  0, -1)
		local p112 = vector.offset(pos,  0,  0,  1)

		local n011 = get_node(p011)
		local n211 = get_node(p211)
		local n110 = get_node(p110)
		local n112 = get_node(p112)
		local n101 = get_node(p101)
		local n121 = get_node(p121)


		if n011.name == 'ignore' or
			 n211.name == 'ignore' or
			 n110.name == 'ignore' or
			 n112.name == 'ignore' or
			 n101.name == 'ignore' or
			 n121.name == 'ignore' then


			 if is_liquid(n111) then
				 -- TODO how to handle that?
			 end
			 return
		 end


		if RENEWABLE then
			local count_sources = 0
			if n011.name == NAME_SOURCE then count_sources = count_sources + 1 end
			if n211.name == NAME_SOURCE then count_sources = count_sources + 1 end
			if n110.name == NAME_SOURCE then count_sources = count_sources + 1 end
			if n112.name == NAME_SOURCE then count_sources = count_sources + 1 end

			if (n111.name == NAME_FLOWING or n111.name == 'air') and count_sources >= 2 then 
				-- Renew liquid
				update_next({pos=pos})
				set_node(pos, { name=NAME_SOURCE })
				if n011.name ~= NAME_SOURCE then update_next({pos=p011}) end
				if n211.name ~= NAME_SOURCE then update_next({pos=p211}) end
				if n110.name ~= NAME_SOURCE then update_next({pos=p110}) end
				if n112.name ~= NAME_SOURCE then update_next({pos=p112}) end
				return
			end
		end

		-- These variables store the level or nil if the node isn't a liquid.
		local l111 = get_liquid_level(n111)
		local l011 = get_liquid_level(n011)
		local l211 = get_liquid_level(n211)
		local l110 = get_liquid_level(n110)
		local l112 = get_liquid_level(n112)
		local l101 = get_liquid_level(n101)
		local l121 = get_liquid_level(n121)

		-- calculate the liquid level that is supported here.
		local support_level = 1

		if l121 ~= nil then 
			-- node above is a liquid
			support_level = 9
		elseif n111.name == NAME_SOURCE then
			-- the current node is a source
			support_level = 9
		else
			-- the neighboring node on the same Y-plan with the highest level counts
			if l011 ~= nil and support_level < l011 then
				support_level = l011
			end
			if l211 ~= nil and support_level < l211 then
				support_level = l211
			end
			if l110 ~= nil and support_level < l110 then
				support_level = l110
			end
			if l112 ~= nil and support_level < l112 then
				support_level = l112
			end
		end


		-- subtract 1 so that the level reaches from 0 to 8
		-- This variable tells us what level the current node should have.
		-- If it is higher we will reduce it and if it is lower we increase it.
		support_level = level_tb[support_level]


		if l111 ~= nil then
			-- The current node is already a liquid

			if l111 == support_level and not is_sinking then
				-- The current node is on its terminal level
				-- This means it is ready to spread.

				-- Get the next level from a table
				local new_level = level_tb[support_level]

				local d101 = core.registered_nodes[n101.name]

				if n101.name == NAME_SOURCE and n111.name ~= NAME_SOURCE then
					-- the current node is on top of a source node. No more flowing here.
					-- With the exception that when the current node is a source node as
					-- well.
				elseif
						n101.name == 'air'        or
						n101.name == NAME_FLOWING or
						(d101 and d101.floodable) then

					if not l101 or l101 < 8 then
						-- turn the liquid below into down-flowing
						update_next({pos=p101})
						set_node(p101, make_liquid('down'))
					else
						-- The liquid already flows down
					end
				elseif new_level > 0 and
						-- Liquids must not spread if they already have a way to flow
						-- further. This could happen when a liquid node gets updated
						-- manually. This is always the case when a node gets loaded from
						-- the disk.
						(not l011 or l011 > new_level) and
						(not l211 or l211 > new_level) and
						(not l110 or l110 > new_level) and
						(not l112 or l112 > new_level) then

					local is_new_map = false
					if not map then
						-- Make a new map if there is none.
						map = path_find(p111)
						is_new_map = true
					end


					local function push()
						-- This function pushes the liquid in all four directions if the
						-- map wants that and the real node there is actually floodable.
						-- The number of *potential* floods are counted. If the count
						-- remains 0, the map is no longer suitable.
						local cnt_flood = 0
						local new_liquid = make_liquid(new_level)

						local function flood(p, l)
							local m = map(p)
							if m and m == new_level then
								if new_level > (l or 0) and is_floodable(p) then
									update_next({pos=p, map=map})
									set_node(p, new_liquid)
								end
								cnt_flood = cnt_flood + 1
							end
						end

						flood(p011, l011)
						flood(p211, l211)
						flood(p110, l110)
						flood(p112, l112)
						return cnt_flood

					end

					if push() == 0 and not is_new_map then
						-- The map might be outdated, try once more with a new map
						map = path_find(p111)
						push()
					end
				end

			elseif l111 > support_level then
				-- The liquid level is too high here we need to reduce it.

				if support_level > 0 then
					update_next({pos=p111, is_sinking=true})
				end
				set_node(p111, make_liquid(support_level))

				-- Neighboring nodes might need to be reduced as well
				if l011 ~= nil then update_next({pos=p011, is_sinking=true}) end
				if l211 ~= nil then update_next({pos=p211, is_sinking=true}) end
				if l110 ~= nil then update_next({pos=p110, is_sinking=true}) end
				if l112 ~= nil then update_next({pos=p112, is_sinking=true}) end

				-- the node below might need an update as well, but only if the liquid
				-- has completely gone
				if support_level == 0 and l101 ~= nil then
					update_next({pos=p101, is_sinking=true})
				end
			end
		else
			-- It seams that the current node is not a liquid at all.
			-- We update the neighbors because it might have been a liquid
			-- previously.
			if l011 ~= nil then update_next({pos=p011}) end
			if l211 ~= nil then update_next({pos=p211}) end
			if l110 ~= nil then update_next({pos=p110}) end
			if l112 ~= nil then update_next({pos=p112}) end
			if l101 ~= nil then update_next({pos=p101}) end
			if l121 ~= nil then update_next({pos=p121}) end
		end
	end

	local function liquid_update(pos)
		-- pos might not be a vector
		local p = vector.copy(pos)
		update_next({pos = p})
	end

	core.register_on_placenode(liquid_update)
	core.register_on_dignode(liquid_update)


	local function set_common_defs(ndef)

		if ndef.on_construct ~= nil then
			local on_construct = ndef.on_construct
			ndef.on_construct = function(pos)
				liquid_update(pos)
				on_construct(pos)
			end
		else
			ndef.on_construct = liquid_update
		end

		if ndef.after_destruct ~= nil then
			local after_destruct = ndef.after_destruct
			ndef.after_destruct = function(pos)
				liquid_update(pos)
				after_destruct(pos)
			end
		else
			ndef.after_destruct = liquid_update
		end


		-- remove attributes that might interfere.
		ndef.liquidtype = nil


		ndef.liquid_alternative_source	= NAME_SOURCE
		ndef.liquid_alternative_flowing = NAME_FLOWING
		ndef.paramtype					 = "light"
		ndef.paramtype2					 = "flowingliquid"

		if ndef.liquid_move_physics == nil then
			ndef.liquid_move_physics = true
		end


		if not ndef.groups then
			ndef.groups = { }
		end

	end


	set_common_defs(def_source)
	def_source.drawtype								= "liquid"
	def_source.groups.liquid_source		= 1
	core.register_node(NAME_SOURCE, def_source)


	set_common_defs(def_flowing)
	def_flowing.drawtype							= "flowingliquid"
	def_flowing.groups.liquid_flowing = 1
	core.register_node(NAME_FLOWING, def_flowing)


	core.register_on_mods_loaded(function()
		-- Luanti activates the builtin liquid transformation based on the
		-- `liquidtype`. Therefor we need to set it's value to 'none'.
		-- BUT many mods also read that value to check if this node is a liquid.
		-- This hack sets the value to the respective liquid type after Luanti red
		-- its value.
		-- This way mods see what they need, at least their callbacks do.

		local function set_liquidtype(name, liquidtype)
			local mt = getmetatable(core.registered_nodes[name])
			local oldidx = mt.__index
			mt.__index = function(tbl, k)
				if k == "liquidtype" then
					return liquidtype
				end
				if type(oldidx) == "function" then return oldidx(tbl, k) end
				if type(oldidx) == "table" and not rawget(tbl, k) then return oldidx[k] end
				return tbl[k]
			end
			setmetatable(core.registered_nodes[name], mt)
		end

		set_liquidtype(NAME_SOURCE, 'source')
		set_liquidtype(NAME_FLOWING, 'flowing')

		assert(core.registered_nodes[NAME_SOURCE].liquidtype == 'source',
			'This hack does no longer work')
		assert(core.registered_nodes[NAME_FLOWING].liquidtype == 'flowing',
			'This hack does no longer work')

	end)


	core.register_lbm({
		label = "Continue the liquids",

		name = modname..":resume_liquid_"..resume_counter,

		nodenames = {NAME_SOURCE, NAME_FLOWING},

		run_at_every_load = true,

		action = function(pos, node, dtime_s)
			local n111 =	node
			local n011 =	core.get_node(vector.offset(pos, -1, 0, 0))
			local n211 =	core.get_node(vector.offset(pos,  1, 0, 0))
			local n110 =	core.get_node(vector.offset(pos,  0, 0,-1))
			local n112 =	core.get_node(vector.offset(pos,  0, 0, 1))
			local n101 =	core.get_node(vector.offset(pos,  0,-1, 0))

			if n101.name ~= NAME_SOURCE or 
				n111.name ~= NAME_SOURCE or 
				n011.name ~= NAME_SOURCE or 
				n211.name ~= NAME_SOURCE or 
				n110.name ~= NAME_SOURCE or 
				n112.name ~= NAME_SOURCE then 

				core.after(5, function()
					liquid_update(pos)
				end)
			end
		 end,
	})

	resume_counter = resume_counter + 1


	local function run()
		core.after(TICKS, function()
			local q = update_next_set

			-- Reset the containers for reuse
			update_next_set = {}
			read_nodes = {}
			changed_nodes = {}

			for _, item in pairs(q) do
				-- Do the flow magic
				flow_iteration(item)
			end

			for h, node in pairs(changed_nodes) do
				local pos = core.get_position_from_hash(h)

				local old = read_nodes[h]
				local old_ndef = core.registered_nodes[old.name]
				if old_ndef.on_flood then
					if not old_ndef.on_flood(pos, old, node) then
						core.set_node(pos, node)
					end
				else
					core.set_node(pos, node)
				end
			end

			if liquid.running then
				run()
			end
		end)
	end

	liquid.registered_liquids[#liquid.registered_liquids+1] = {
		run = run,
		update = liquid_update,
	}

	if liquid.running then
		run()
	end
end

function liquid.run()
	for i, o in ipairs(liquid.registered_liquids) do
		o.run()
	end
end

function liquid.update(pos)
	for i, o in ipairs(liquid.registered_liquids) do
		o.update(pos)
	end
end

core.register_chatcommand('liquid', {
	func = function(name, param)
		if param == 'step' then
			liquid.running = false
			liquid.run()
		elseif param == 'run' then
			liquid.running = true
			liquid.run()
		elseif param == 'stop' then
			liquid.running = false
		end
	end
})

return liquid

