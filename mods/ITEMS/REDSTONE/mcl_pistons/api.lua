local GRAVITY = tonumber(minetest.settings:get("movement_gravity"))

-- local inv_nodes_movable = minetest.settings:get_bool("mcl_inv_nodes_movable", true)

mcl_pistons.registered_on_move = {}

local sixdirs = {
	vector.new(1,  0, 0),
	vector.new(-1,  0, 0),
	vector.new(0,  1, 0),
	vector.new(0, -1, 0),
	vector.new(0,  0, 1),
	vector.new(0,  0, -1)
}

-- Functions to be called on piston movement
-- See also the callback
function mcl_pistons.register_on_move(callback)
	table.insert(mcl_pistons.registered_on_move, callback)
end

local function run_on_mcl_piston_move(moved_nodes)
	for _, callback in ipairs(mcl_pistons.registered_on_move) do
		callback(moved_nodes)
	end
end

-- pos: pos of mvps;
-- movedir: direction of actual movement
-- maximum: maximum nodes to be pushed
function mcl_pistons.push(pos, movedir, maximum, player_name, piston_pos)
	-- table containing nodes to be moved, has the following format:
	-- pos: position after being moved
	-- old_pos: position before being moved
	-- node: node information, courtesy of minetest.get_node
	-- meta: node metadata, nil if dosent have it
	-- timer: node timer, nil if dosent have it
	local nodes = {}

	-- table containing nodes to be dug by the piston. Same format nodes
	local dig_nodes = {}
	local frontiers = {pos}

	while #frontiers > 0 do
		local np = frontiers[1]
		local nn = minetest.get_node(np)
		if nn.name == "ignore" then
			minetest.get_voxel_manip():read_from_map(np, np)
			nn = minetest.get_node(np)
		end

		if minetest.get_item_group(nn.name, "unmovable_by_piston") == 1 then
			return
		end

		if minetest.is_protected(np, player_name) then
			return
		end

		if minetest.get_item_group(nn.name, "dig_by_piston") == 1 then
			-- if we want the node to drop, e.g. sugar cane, do not count towards push limit
			table.insert(dig_nodes, {node = nn, pos = vector.add(np, movedir), old_pos = vector.copy(np)})
		else
			if not minetest.registered_nodes[nn.name].buildable_to then
				table.insert(nodes, {node = nn, pos = vector.add(np, movedir), old_pos = vector.copy(np)})
				if #nodes > maximum then return end

				-- add connected nodes to frontiers, connected is a vector list
				-- the vectors must be absolute positions
				local connected= {}
				local is_connected, offset_node, offset_pos
				if minetest.registered_nodes[nn.name]._mcl_pistons_sticky then
					-- when pushing a sticky block, push all applicable blocks with it
					for _, dir in pairs(sixdirs) do
						offset_pos = np:add(dir:multiply(-1))
						offset_node = minetest.get_node(offset_pos)
						is_connected = minetest.registered_nodes[nn.name]._mcl_pistons_sticky(offset_node, dir)

						if is_connected and minetest.get_item_group(offset_node.name, "unsticky") == 0
							and minetest.get_item_group(offset_node.name, "unmovable_by_piston") == 0 then
							if piston_pos:equals(offset_pos) then
								return
							end

							table.insert(connected, offset_pos)
						end
					end
				else
					if minetest.get_item_group(nn.name, "unsticky") == 0 then
						-- when pushing a non sticky block, check for sticky blocks around it, and if they exist, push them aswell
						for _, dir in pairs(sixdirs) do
							offset_pos = np:add(dir)
							offset_node = minetest.get_node(offset_pos)
							is_connected = minetest.registered_nodes[offset_node.name] and minetest.registered_nodes[offset_node.name]._mcl_pistons_sticky
							and minetest.registered_nodes[offset_node.name]._mcl_pistons_sticky(nn, dir:multiply(-1))

							if is_connected then
								if piston_pos:equals(offset_pos) then
									return
								end

								table.insert(connected, offset_pos)
							end
						end
					end
				end

				-- add node infront of the current node as connected. Because its being pushed
				table.insert(connected, vector.add(np, movedir))

				-- Make sure there are no duplicates in frontiers / nodes before
				-- adding nodes in "connected" to frontiers
				for _, cp in ipairs(connected) do
					local duplicate = false
					for _, rp in ipairs(nodes) do
						if vector.equals(cp, rp.old_pos) then
							duplicate = true
						end
					end
					if not duplicate then
						for _, rp in ipairs(frontiers) do
							if vector.equals(cp, rp) then
								duplicate = true
							end
						end
					end
					if not duplicate then
						table.insert(frontiers, cp)
					end
				end
			end
		end
		table.remove(frontiers, 1)
	end

	-- dig all nodes
	for id, n in ipairs(dig_nodes) do
		-- if current node has already been destroyed (e.g. chain reaction of sugar cane breaking), skip it
		if minetest.get_node(n.old_pos).name == n.node.name then
			local def = minetest.registered_nodes[n.node.name]
			def.on_dig(n.old_pos, n.node) --no need to check if it exists since all nodes have this via metatable (defaulting to minetest.node_dig which will handle drops)
			minetest.remove_node(n.old_pos)
		end
	end

	-- remove old nodes that are about to be pushed
	for id, n in ipairs(nodes) do
		n.meta = minetest.get_meta(n.old_pos) and minetest.get_meta(n.old_pos):to_table()
		minetest.remove_node(n.old_pos)
		local node_timer = minetest.get_node_timer(n.old_pos)
		if node_timer:is_started() then
			n.node_timer = {node_timer:get_timeout(), node_timer:get_elapsed()}
		end
	end

	-- add nodes after being pushed
	for id, n in ipairs(nodes) do
		-- local np = newpos[id]
		minetest.set_node(n.pos, n.node)
		if n.meta then
			minetest.get_meta(n.pos):from_table(n.meta)
		end
		if n.node_timer then
			minetest.get_node_timer(n.pos):set(unpack(n.node_timer))
		end
		if string.find(n.node.name, "mcl_observers:observer") then
			-- It also counts as a block update when the observer itself is moved by a piston (Wiki):
			mcl_observers.observer_activate(n.pos)
		end
	end

	local function move_object(obj, n)
		local entity = obj:get_luaentity()
		local player = obj:is_player()
		if (entity or player) and not (entity and entity._mcl_pistons_unmovable) then
			obj:move_to(obj:get_pos():add(movedir))
			-- Launch Player, TNT & mobs like in Minecraft
			-- Only doing so if slimeblock is attached.
			if n.node.name == "mcl_core:slimeblock" then
				obj:set_acceleration({x=movedir.x, y=-GRAVITY, z=movedir.z})

				--Need to set velocities differently for players, items & mobs/tnt, and falling anvils.
				if player then
					obj:add_velocity(vector.new(movedir.x * 10, movedir.y * 13, movedir.z * 10))
				elseif entity.name == "__builtin:item" then
					obj:add_velocity(vector.new(movedir.x * 9, movedir.y * 11, movedir.z * 9))
				elseif entity.name == "__builtin:falling_node" then
					obj:add_velocity(vector.new(movedir.x * 43, movedir.y * 72, movedir.z * 43))
				else
					obj:add_velocity(vector.new(movedir.x * 6, movedir.y * 9, movedir.z * 6))
				end
			end
		end
	end

	for id, n in ipairs(nodes) do
		local objects = minetest.get_objects_inside_radius(n.pos, 0.9)
		for _, obj in ipairs(objects) do
			move_object(obj, n)
		end

		-- if moving up, dont push objects already on the block. Because the loop just above does it already
		if movedir.y ~= 1 then
			objects = minetest.get_objects_inside_radius(n.old_pos:offset(0, 1, 0), 0.9)
			for _, obj in ipairs(objects) do
				move_object(obj, n)
			end
		end
	end

	run_on_mcl_piston_move(nodes)

	return true
end

-- -- These are unmovable in java edition due to technical restrictions
-- -- disable the setting mcl_nodes_movable
-- if not inv_nodes_movable then
-- 	mesecon.register_mvps_stopper("mcl_hoppers:hopper")
-- 	mesecon.register_mvps_stopper("mcl_hoppers:hopper_side")
-- 	mesecon.register_mvps_stopper("mcl_droppers:dropper")
-- 	mesecon.register_mvps_stopper("mcl_droppers:dropper_up")
-- 	mesecon.register_mvps_stopper("mcl_droppers:dropper_down")
-- 	mesecon.register_mvps_stopper("mcl_dispensers:dispenser")
-- 	mesecon.register_mvps_stopper("mcl_dispensers:dispenser_up")
-- 	mesecon.register_mvps_stopper("mcl_dispensers:dispenser_down")
-- 	mesecon.register_mvps_stopper("mcl_barrels:barrel_open")
-- 	mesecon.register_mvps_stopper("mcl_barrels:barrel_closed")
-- 	mesecon.register_mvps_stopper("mcl_anvils:anvil")
-- 	mesecon.register_mvps_stopper("mcl_anvils:anvil_damage_1")
-- 	mesecon.register_mvps_stopper("mcl_anvils:anvil_damage_2")
-- end
--
-- mesecon.register_mvps_stopper("mcl_chests:chest")
-- mesecon.register_mvps_stopper("mcl_chests:chest_small")
-- mesecon.register_mvps_stopper("mcl_chests:chest_left")
-- mesecon.register_mvps_stopper("mcl_chests:chest_right")
-- mesecon.register_mvps_stopper("mcl_chests:trapped_chest")
-- mesecon.register_mvps_stopper("mcl_chests:trapped_chest_small")
-- mesecon.register_mvps_stopper("mcl_chests:trapped_chest_left")
-- mesecon.register_mvps_stopper("mcl_chests:trapped_chest_right")
--
-- -- Unmovable by design: objects
-- mesecon.register_mvps_unmov("mcl_enchanting:book")
-- mesecon.register_mvps_unmov("mcl_chests:chest")
-- mesecon.register_mvps_unmov("mcl_banners:hanging_banner")
-- mesecon.register_mvps_unmov("mcl_banners:standing_banner")
-- mesecon.register_mvps_unmov("mcl_signs:text")
-- mesecon.register_mvps_unmov("mcl_mobspawners:doll")
-- mesecon.register_mvps_unmov("mcl_armor_stand:armor_entity")
-- mesecon.register_mvps_unmov("mcl_itemframes:item")
-- mesecon.register_mvps_unmov("mcl_itemframes:map")
-- mesecon.register_mvps_unmov("mcl_paintings:painting")
-- mesecon.register_mvps_unmov("mcl_end:crystal")

mcl_pistons.register_on_move(function(moved_nodes)
	for i = 1, #moved_nodes do
		local moved_node = moved_nodes[i]
		minetest.after(0, function()
			minetest.check_for_falling(moved_node.old_pos)
			minetest.check_for_falling(moved_node.pos)
		end)

		-- Callback for on_move stored in nodedef
		local node_def = minetest.registered_nodes[moved_node.node.name]
		if node_def and node_def._mcl_piston_on_move then
			node_def._mcl_piston_on_move(moved_node)
		end
	end
end)
