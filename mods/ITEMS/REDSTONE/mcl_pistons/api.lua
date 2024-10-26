local GRAVITY = tonumber(minetest.settings:get("movement_gravity"))

local inv_nodes_movable = minetest.settings:get_bool("mcl_inv_nodes_movable", true)

mcl_pistons.registered_on_move = {}

local alldirs = {
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

local sixdirs = {
	vector.new(0, 0, 1),
	vector.new(1, 0, 0),
	vector.new(0, 0, -1),
	vector.new(-1, 0, 0),
	vector.new(0, -1, 0),
	vector.new(0, 1, 0),
}

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

-- -- Unmovable by design: nodes
-- mesecon.register_mvps_stopper("mcl_core:barrier")
-- mesecon.register_mvps_stopper("mcl_core:realm_barrier")
-- mesecon.register_mvps_stopper("mcl_core:void")
-- mesecon.register_mvps_stopper("mcl_core:bedrock")
-- mesecon.register_mvps_stopper("mcl_core:obsidian")
-- mesecon.register_mvps_stopper("mcl_core:crying_obsidian")
-- mesecon.register_mvps_stopper("mcl_chests:ender_chest")
-- mesecon.register_mvps_stopper("mcl_chests:ender_chest_small")
-- mesecon.register_mvps_stopper("mcl_mobspawners:spawner")
-- mesecon.register_mvps_stopper("mesecons_commandblock:commandblock_off")
-- mesecon.register_mvps_stopper("mesecons_commandblock:commandblock_on")
-- mesecon.register_mvps_stopper("mcl_portals:portal")
-- mesecon.register_mvps_stopper("mcl_portals:portal_end")
-- mesecon.register_mvps_stopper("mcl_portals:end_portal_frame")
-- mesecon.register_mvps_stopper("mcl_portals:end_portal_frame_eye")
-- mesecon.register_mvps_stopper("mcl_enchanting:table")
-- mesecon.register_mvps_stopper("mcl_jukebox:jukebox")
-- mesecon.register_mvps_stopper("mesecons_solarpanel:solar_panel_on")
-- mesecon.register_mvps_stopper("mesecons_solarpanel:solar_panel_off")
-- mesecon.register_mvps_stopper("mesecons_solarpanel:solar_panel_inverted_on")
-- mesecon.register_mvps_stopper("mesecons_solarpanel:solar_panel_inverted_off")
-- mesecon.register_mvps_stopper("mcl_banners:hanging_banner")
-- mesecon.register_mvps_stopper("mcl_banners:standing_banner")
-- mesecon.register_mvps_stopper("mcl_beehives:bee_nest")
-- mesecon.register_mvps_stopper("mcl_beehives:beehive")
-- mesecon.register_mvps_stopper("mcl_compass:lodestone")
-- mesecon.register_mvps_stopper("mcl_sculk:sculk")
-- mesecon.register_mvps_stopper("mcl_sculk:catalyst")
--
-- -- Unmovable by technical restrictions.
-- -- Open formspec would screw up if node is destroyed (minor problem)
-- -- Would screw up on/off state of trapped chest (big problem)
-- -- Would duplicate xp when moved
-- mesecon.register_mvps_stopper("mcl_furnaces:furnace")
-- mesecon.register_mvps_stopper("mcl_furnaces:furnace_active")
-- mesecon.register_mvps_stopper("mcl_blast_furnace:blast_furnace")
-- mesecon.register_mvps_stopper("mcl_blast_furnace:blast_furnace_active")
-- mesecon.register_mvps_stopper("mcl_smoker:smoker")
-- mesecon.register_mvps_stopper("mcl_smoker:smoker_active")
--
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
-- mesecon.register_mvps_stopper("mcl_signs:wall_sign")
-- mesecon.register_mvps_stopper("mcl_signs:standing_sign")
-- mesecon.register_mvps_stopper("mcl_signs:standing_sign22_5")
-- mesecon.register_mvps_stopper("mcl_signs:standing_sign45")
-- mesecon.register_mvps_stopper("mcl_signs:standing_sign67_5")
--
-- -- Campfires
-- mesecon.register_mvps_stopper("mcl_campfires:campfire")
-- mesecon.register_mvps_stopper("mcl_campfires:campfire_lit")
-- mesecon.register_mvps_stopper("mcl_campfires:soul_campfire")
-- mesecon.register_mvps_stopper("mcl_campfires:soul_campfire_lit")
--
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
--
--
-- -- Unpullable by design: nodes
-- -- Glazed Terracotta
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_red")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_orange")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_yellow")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_green")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_lime")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_purple")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_magenta")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_blue")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_cyan")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_white")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_grey")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_silver")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_black")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_brown")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_light_blue")
-- mesecon.register_mvps_unsticky("mcl_colorblocks:glazed_terracotta_pink")
--
-- -- Bamboo
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo")
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo_endcap")
--
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo_1")
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo_2")
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo_3")
--
-- mesecon.register_mvps_unsticky("mcl_bamboo:bamboo_door")
-- mesecon.register_mvps_unsticky("mcl_bamboo:scaffolding")
--
-- -- Beds
-- mesecon.register_mvps_unsticky("mcl_beds:bed_black_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_black_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_blue_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_blue_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_brown_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_brown_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_cyan_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_cyan_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_green_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_green_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_grey_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_grey_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_light_blue_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_light_blue_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_lime_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_lime_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_magenta_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_magenta_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_orange_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_orange_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_pink_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_pink_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_purple_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_purple_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_red_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_red_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_silver_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_silver_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_white_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_white_bottom")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_yellow_top")
-- mesecon.register_mvps_unsticky("mcl_beds:bed_yellow_bottom")
-- -- Cactus, Sugarcane & Vines
-- mesecon.register_mvps_unsticky("mcl_core:cactus")
-- mesecon.register_mvps_unsticky("mcl_core:reeds")
-- mesecon.register_mvps_unsticky("mcl_core:vine")
-- -- Cake
-- mesecon.register_mvps_unsticky("mcl_cake:cake_1")
-- mesecon.register_mvps_unsticky("mcl_cake:cake_2")
-- mesecon.register_mvps_unsticky("mcl_cake:cake_3")
-- mesecon.register_mvps_unsticky("mcl_cake:cake_4")
-- mesecon.register_mvps_unsticky("mcl_cake:cake_5")
-- mesecon.register_mvps_unsticky("mcl_cake:cake_6")
-- mesecon.register_mvps_unsticky("mcl_cake:cake")
-- -- Carved & Jack O'Lantern Pumpkins, Pumpkin & Melon
-- mesecon.register_mvps_unsticky("mcl_farming:pumpkin_face")
-- mesecon.register_mvps_unsticky("mcl_farming:pumpkin_face_light")
-- mesecon.register_mvps_unsticky("mcl_farming:pumpkin")
-- mesecon.register_mvps_unsticky("mcl_farming:melon")
-- -- Chorus Plant & Flower
-- mesecon.register_mvps_unsticky("mcl_end:chorus_plant")
-- mesecon.register_mvps_unsticky("mcl_end:chorus_flower")
-- -- Cobweb
-- mesecon.register_mvps_unsticky("mcl_core:cobweb")
-- -- Cocoa
-- mesecon.register_mvps_unsticky("mcl_cocoas:cocoa_1")
-- mesecon.register_mvps_unsticky("mcl_cocoas:cocoa_2")
-- mesecon.register_mvps_unsticky("mcl_cocoas:cocoa_3")
-- -- Doors
-- mesecon.register_mvps_unsticky("mcl_doors:wooden_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:wooden_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:wooden_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:wooden_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:iron_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:iron_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:iron_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:iron_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:acacia_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:acacia_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:acacia_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:acacia_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:birch_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:birch_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:birch_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:birch_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:dark_oak_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:dark_oak_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:dark_oak_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:dark_oak_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:spruce_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:spruce_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:spruce_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:spruce_door_b_2")
-- mesecon.register_mvps_unsticky("mcl_doors:jungle_door_t_1")
-- mesecon.register_mvps_unsticky("mcl_doors:jungle_door_b_1")
-- mesecon.register_mvps_unsticky("mcl_doors:jungle_door_t_2")
-- mesecon.register_mvps_unsticky("mcl_doors:jungle_door_b_2")
-- -- Dragon Egg
-- mesecon.register_mvps_unsticky("mcl_end:dragon_egg")
-- -- Fire
-- mesecon.register_mvps_unsticky("mcl_fire:fire")
-- mesecon.register_mvps_unsticky("mcl_fire:eternal_fire")
-- -- Flower Pots
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_allium")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_azure_bluet")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_blue_orchid")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_dandelion")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_fern")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_oxeye_daisy")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_poppy")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_tulip_orange")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_tulip_pink")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_tulip_red")
-- mesecon.register_mvps_unsticky("mcl_flowerpots:flower_pot_tulip_white")
-- -- Flowers, Lilypad & Dead Bush
-- mesecon.register_mvps_unsticky("mcl_core:deadbush")
-- mesecon.register_mvps_unsticky("mcl_flowers:allium")
-- mesecon.register_mvps_unsticky("mcl_flowers:azure_bluet")
-- mesecon.register_mvps_unsticky("mcl_flowers:blue_orchid")
-- mesecon.register_mvps_unsticky("mcl_flowers:dandelion")
-- mesecon.register_mvps_unsticky("mcl_flowers:double_fern")
-- mesecon.register_mvps_unsticky("mcl_flowers:double_fern_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:fern")
-- mesecon.register_mvps_unsticky("mcl_flowers:lilac")
-- mesecon.register_mvps_unsticky("mcl_flowers:lilac_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:oxeye_daisy")
-- mesecon.register_mvps_unsticky("mcl_flowers:peony")
-- mesecon.register_mvps_unsticky("mcl_flowers:peony_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:poppy")
-- mesecon.register_mvps_unsticky("mcl_flowers:rose_bush")
-- mesecon.register_mvps_unsticky("mcl_flowers:rose_bush_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:sunflower")
-- mesecon.register_mvps_unsticky("mcl_flowers:sunflower_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:tallgrass")
-- mesecon.register_mvps_unsticky("mcl_flowers:double_grass")
-- mesecon.register_mvps_unsticky("mcl_flowers:double_grass_top")
-- mesecon.register_mvps_unsticky("mcl_flowers:tulip_orange")
-- mesecon.register_mvps_unsticky("mcl_flowers:tulip_pink")
-- mesecon.register_mvps_unsticky("mcl_flowers:tulip_red")
-- mesecon.register_mvps_unsticky("mcl_flowers:tulip_white")
-- mesecon.register_mvps_unsticky("mcl_flowers:waterlily")
-- -- Heads
-- mesecon.register_mvps_unsticky("mcl_heads:creeper")
-- mesecon.register_mvps_unsticky("mcl_heads:skeleton")
-- mesecon.register_mvps_unsticky("mcl_heads:steve")
-- mesecon.register_mvps_unsticky("mcl_heads:wither_skeleton")
-- mesecon.register_mvps_unsticky("mcl_heads:zombie")
-- -- Item Frame
-- mesecon.register_mvps_unsticky("mcl_itemframes:frame")
-- mesecon.register_mvps_unsticky("mcl_itemframes:glow_frame")
-- -- Ladder
-- mesecon.register_mvps_unsticky("mcl_core:ladder")
-- -- Lava & Water
-- mesecon.register_mvps_unsticky("mcl_core:lava_source")
-- mesecon.register_mvps_unsticky("mcl_core:lava_flowing")
-- mesecon.register_mvps_unsticky("mcl_core:water_source")
-- mesecon.register_mvps_unsticky("mcl_core:water_flowing")
-- mesecon.register_mvps_unsticky("mclx_core:river_water_source")
-- mesecon.register_mvps_unsticky("mclx_core:river_water_flowing")
-- -- Leaves
-- mesecon.register_mvps_unsticky("mcl_core:leaves")
-- mesecon.register_mvps_unsticky("mcl_core:acacialeaves")
-- mesecon.register_mvps_unsticky("mcl_core:birchleaves")
-- mesecon.register_mvps_unsticky("mcl_core:darkleaves")
-- mesecon.register_mvps_unsticky("mcl_core:spruceleaves")
-- mesecon.register_mvps_unsticky("mcl_core:jungleleaves")
-- -- Lever
-- mesecon.register_mvps_unsticky("mesecons_walllever:wall_lever_off")
-- mesecon.register_mvps_unsticky("mesecons_walllever:wall_lever_on")
-- -- Mushrooms, Nether Wart & Amethyst
-- mesecon.register_mvps_unsticky("mcl_mushroom:mushroom_brown")
-- mesecon.register_mvps_unsticky("mcl_mushroom:mushroom_red")
-- mesecon.register_mvps_unsticky("mcl_nether:nether_wart_0")
-- mesecon.register_mvps_unsticky("mcl_nether:nether_wart_1")
-- mesecon.register_mvps_unsticky("mcl_nether:nether_wart_2")
-- mesecon.register_mvps_unsticky("mcl_nether:nether_wart")
-- mesecon.register_mvps_unsticky("mcl_amethyst:amethyst_cluster")
-- mesecon.register_mvps_unsticky("mcl_amethyst:budding_amethyst_block")
-- -- Pressure Plates
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_wood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_wood_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_stone_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_stone_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_acaciawood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_acaciawoood_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_birchwood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_birchwood_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_darkwood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_darkwood_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_sprucekwood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_sprucewood_off")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_junglewood_on")
-- mesecon.register_mvps_unsticky("mesecons_pressureplates:pressure_plate_junglewood_off")
-- -- Redstone Comparators
-- mesecon.register_mvps_unsticky("mcl_comparators:comparator_on_sub")
-- mesecon.register_mvps_unsticky("mcl_comparators:comparator_off_sub")
-- mesecon.register_mvps_unsticky("mcl_comparators:comparator_on_comp")
-- mesecon.register_mvps_unsticky("mcl_comparators:comparator_off_comp")
-- -- Redstone Dust
-- mesecon.register_mvps_unsticky("mesecons:wire_00000000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00000000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10000000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10000000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01000000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01000000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11000000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11000000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00100000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00100000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10100000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10100000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00010000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00010000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10010000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10010000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10001000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10001000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11001000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11001000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10101000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10101000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10011000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10011000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111000_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111000_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01000100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01000100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11000100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11000100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11001100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11001100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111100_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111100_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00100010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00100010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10100010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10100010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10101010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10101010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111010_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111010_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01100110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11100110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11101110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111110_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111110_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00010001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00010001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10010001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10010001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10011001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10011001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111001_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111001_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01010101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11010101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11011101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111101_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111101_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_00110011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10110011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_10111011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111011_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111011_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110111_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_01110111_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110111_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11110111_off")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111111_on")
-- mesecon.register_mvps_unsticky("mesecons:wire_11111111_off")
-- -- Redstone Repeater
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_off_1")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_off_2")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_off_3")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_off_4")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_on_1")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_on_2")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_on_3")
-- mesecon.register_mvps_unsticky("mesecons_delayer:delayer_on_4")
-- -- Redstone Torch
-- mesecon.register_mvps_unsticky("mesecons_torch:torch_on")
-- mesecon.register_mvps_unsticky("mesecons_torch:torch_off")
-- mesecon.register_mvps_unsticky("mesecons_torch:torch_on_wall")
-- mesecon.register_mvps_unsticky("mesecons_torch:torch_off_wall")
-- -- Sea Pickle
-- mesecon.register_mvps_unsticky("mcl_ocean:sea_pickle_1_dead_brain_coral_block")
-- mesecon.register_mvps_unsticky("mcl_ocean:sea_pickle_2_dead_brain_coral_block")
-- mesecon.register_mvps_unsticky("mcl_ocean:sea_pickle_3_dead_brain_coral_block")
-- mesecon.register_mvps_unsticky("mcl_ocean:sea_pickle_4_dead_brain_coral_block")
-- -- Shulker chests
-- mesecon.register_mvps_unsticky("mcl_chests:black_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:blue_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:brown_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:cyan_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:dark_green_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:dark_grey_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:lightblue_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:green_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:orange_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:magenta_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:pink_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:violet_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:red_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:grey_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:white_shulker_box_small")
-- mesecon.register_mvps_unsticky("mcl_chests:yellow_shulker_box_small")
-- -- Snow
-- mesecon.register_mvps_unsticky("mcl_core:snow")
-- mesecon.register_mvps_unsticky("mcl_core:snow_2")
-- mesecon.register_mvps_unsticky("mcl_core:snow_3")
-- mesecon.register_mvps_unsticky("mcl_core:snow_4")
-- mesecon.register_mvps_unsticky("mcl_core:snow_5")
-- mesecon.register_mvps_unsticky("mcl_core:snow_6")
-- mesecon.register_mvps_unsticky("mcl_core:snow_7")
-- mesecon.register_mvps_unsticky("mcl_core:snow_8")
-- -- Torch
-- mesecon.register_mvps_unsticky("mcl_torches:torch")
-- mesecon.register_mvps_unsticky("mcl_torches:torch_wall")
-- -- Wheat
-- mesecon.register_mvps_unsticky("mcl_farming:wheat")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_2")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_3")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_4")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_5")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_6")
-- mesecon.register_mvps_unsticky("mcl_farming:wheat_7")

-- Includes node heat when moving them

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
