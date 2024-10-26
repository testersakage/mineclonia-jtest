local S = minetest.get_translator(minetest.get_current_modname())

local fourdirs = {
	[0] = vector.new(0, 0, 1),
	[1] = vector.new(1, 0, 0),
	[2] = vector.new(0, 0, -1),
	[3] = vector.new(-1, 0, 0),
}

function mcl_redstone.update_comparators(pos)
	for _, dir in pairs(fourdirs) do
		local pos2 = pos:add(dir)
		local node2 = minetest.get_node(pos2)

		if dir == minetest.fourdir_to_dir(node2.param2) and node2.name:find("mcl_comparators:comparator_") then
			mcl_redstone.update_node(pos2)
		elseif mcl_redstone._solid_opaque_tab[node2.name] then
			local pos3 = pos2:add(dir)
			local node3 = minetest.get_node(pos3)
			if dir == minetest.fourdir_to_dir(node3.param2) and node3.name:find("mcl_comparators:comparator_") then
				mcl_redstone.update_node(pos3)
			end
		end
	end
end

local function check_inventory(pos)
	local invnode = minetest.get_node_or_nil(pos)
	local invnodedef = invnode and minetest.registered_nodes[invnode.name]

	if not invnodedef then return false, false end

	if not invnodedef.groups.container or (invnodedef.groups.container == 0) then
		return false, invnodedef.groups.opaque and (invnodedef.groups.opaque ~= 0)
	end

	return true, minetest.get_inventory({type="node", pos=pos})
end

local function inventory_power(inv)
	if not inv then return 0 end

	local fullness, slots = 0, 0

	for listname, list in pairs(inv:get_lists()) do
		if not inv:is_empty(listname) then
			for _, stack in pairs(list) do
				if stack then
					fullness = fullness + stack:get_count() / stack:get_stack_max()
				end
				slots = slots + 1
			end
		end
	end

	return (slots == 0) and 0 or math.floor(1 + (fullness / slots) * 14)
end

-- compute tile depending on state and mode
local function get_tiles(state, mode)
	local top = "mcl_comparators_"..state..".png^"..
		"mcl_comparators_"..mode..".png"
	local sides = "mcl_comparators_sides_"..state..".png^"..
		"mcl_comparators_sides_"..mode..".png"
	local ends = "mcl_comparators_ends_"..state..".png^"..
		"mcl_comparators_ends_"..mode..".png"
	return {
		top, "mcl_stairs_stone_slab_top.png",
		sides, sides.."^[transformFX",
		ends, ends,
	}
end

local node_boxes = {
	comp = {
		{ -8/16, -8/16, -8/16,
		   8/16, -6/16,  8/16 },	-- the main slab
		{ -1/16, -6/16,  6/16,
		   1/16, -4/16,  4/16 },	-- front torch
		{ -4/16, -6/16, -5/16,
		  -2/16, -1/16, -3/16 },	-- left back torch
		{  2/16, -6/16, -5/16,
		   4/16, -1/16, -3/16 },	-- right back torch
	},
	sub = {
		{ -8/16, -8/16, -8/16,
		   8/16, -6/16,  8/16 },	-- the main slab
		{ -1/16, -6/16,  6/16,
		   1/16, -3/16,  4/16 },	-- front torch (active)
		{ -4/16, -6/16, -5/16,
		  -2/16, -1/16, -3/16 },	-- left back torch
		{  2/16, -6/16, -5/16,
		   4/16, -1/16, -3/16 },	-- right back torch
	},
}

local collision_box = {
	type = "fixed",
	fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
}

local groups = {
	dig_immediate = 3,
	dig_by_water  = 1,
	destroy_by_lava_flow = 1,
	dig_by_piston = 1,
	attached_node = 1,
}

for _, mode in pairs{"comp", "sub"} do
	for _, state in pairs{"on", "off"} do
		local nodename = "mcl_comparators:comparator_"..state.."_"..mode

		local longdesc, usagehelp, use_help
		if state == "off" and mode == "comp" then
			longdesc = S("Redstone comparators are multi-purpose redstone components.").."\n"..
			S("They can transmit a redstone signal, detect whether a block contains any items and compare multiple signals.")

			usagehelp = S("A redstone comparator has 1 main input, 2 side inputs and 1 output. The output is in arrow direction, the main input is in the opposite direction. The other 2 sides are the side inputs.").."\n"..
				S("The main input can powered in 2 ways: First, it can be powered directly by redstone power like any other component. Second, it is powered if, and only if a container (like a chest) is placed in front of it and the container contains at least one item.").."\n"..
				S("The side inputs are only powered by normal redstone power. The redstone comparator can operate in two modes: Transmission mode and subtraction mode. It starts in transmission mode and the mode can be changed by using the block.").."\n\n"..
				S("Transmission mode:\nThe front torch is unlit and lowered. The output is powered if, and only if the main input is powered. The two side inputs are ignored.").."\n"..
				S("Subtraction mode:\nThe front torch is lit. The output is powered if, and only if the main input is powered and none of the side inputs is powered.")
		else
			use_help = false
		end

		local nodedef = {
			description = S("Redstone Comparator"),
			_doc_items_create_entry = use_help,
			_doc_items_longdesc = longdesc,
			_doc_items_usagehelp = usagehelp,
			drawtype = "nodebox",
			tiles = get_tiles(state, mode),
			use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
			walkable = true,
			selection_box = collision_box,
			collision_box = collision_box,
			node_box = {
				type = "fixed",
				fixed = node_boxes[mode],
			},
			groups = groups,
			paramtype = "light",
			paramtype2 = "4dir",
			sunlight_propagates = false,
			is_ground_content = false,
			drop = "mcl_comparators:comparator_off_comp",
			on_rightclick = function (pos, node, clicker)
				local protname = clicker:get_player_name()
				if minetest.is_protected(pos, protname) then
					minetest.record_protection_violation(pos, protname)
					return
				end
				local newmode = mode == "comp" and "sub" or "comp"
				minetest.set_node(pos, {
					name = "mcl_comparators:comparator_"..state.."_"..newmode,
					param2 = node.param2,
				})
			end,
			_redstone_comparator_mode = mode,
			sounds = mcl_sounds.node_sound_stone_defaults(),
			on_rotate = screwdriver.disallow,
			_mcl_redstone = {
				connects_to = function(node, dir)
					return true
				end,
				get_power = function(node, dir)
					local fourdir = minetest.dir_to_fourdir(dir)
					if not fourdir or dir.y ~= 0 then
						return 0
					end
					return node.param2 % 4 == fourdir and math.floor(node.param2 / 4) or 0, true
				end,
				update = function(pos, node)
					-- TODO: should not accept side power from opaque blocks
					local back = -minetest.fourdir_to_dir(node.param2)
					local left = minetest.fourdir_to_dir((node.param2 - 1) % 4)
					local right = minetest.fourdir_to_dir((node.param2 + 1) % 4)
					local side_power = math.max(
						mcl_redstone.get_power(pos, left),
						mcl_redstone.get_power(pos, right)
					)
					local back_pos = vector.add(pos, back)
					local rear_power
					local has_inv, o = check_inventory(back_pos)
					if has_inv then
						rear_power = inventory_power(o)
					elseif o then
						back_pos = vector.add(back_pos, back)
						has_inv, o = check_inventory(back_pos)
						if has_inv then
							rear_power = inventory_power(o)
						else
							rear_power = mcl_redstone.get_power(pos, back)
						end
					else
						rear_power = mcl_redstone.get_power(pos, back)
					end
					local output
					if mode == "comp" then
						output = rear_power >= side_power and rear_power or 0
					else
						output = math.max(rear_power - side_power, 0)
					end

					local newstate = output > 0 and "on" or "off"
					return {
						name = "mcl_comparators:comparator_"..newstate.."_"..mode,
						param2 = 4 * output + node.param2 % 4,
					}
				end,
			},
		}

		if mode == "comp" and state == "off" then
			nodedef._doc_items_create_entry = true
			nodedef.inventory_image = "mcl_comparators_item.png"
			nodedef.wield_image = "mcl_comparators_item.png"
		else
			nodedef.groups = table.copy(nodedef.groups)
			nodedef.groups.not_in_creative_inventory = 1
			if mode == "sub" or state == "on" then
				nodedef.inventory_image = nil
			end
			local desc = nodedef.description
			if mode ~= "sub" and state == "on" then
				desc = S("Redstone Comparator (Powered)")
			elseif mode == "sub" and state ~= "on" then
				desc = S("Redstone Comparator (Subtract)")
			elseif mode == "sub" and state == "on" then
				desc = S("Redstone Comparator (Subtract, Powered)")
			end
			nodedef.description = desc

			doc.add_entry_alias("nodes", "mcl_comparators:comparator_"..state.."_"..mode, "nodes", nodename)
		end

		minetest.register_node(nodename, nodedef)
	end
end
