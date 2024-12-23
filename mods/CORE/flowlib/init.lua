flowlib = {}

--sum of direction vectors must match an array index

--(sum,root)
--(0,1), (1,1+0=1), (2,1+1=2), (3,1+2^2=5), (4,2^2+2^2=8)

local inv_roots = {
	[0] = 1,
	[1] = 1,
	[2] = 0.70710678118655,
	[4] = 0.5,
	[5] = 0.44721359549996,
	[8] = 0.35355339059327,
}

local function to_unit_vector(dir_vector)
	local sum = dir_vector.x * dir_vector.x + dir_vector.z * dir_vector.z
	local ir_sum = inv_roots[sum]
	return dir_vector:copy():schur(vector.new(ir_sum, 0, ir_sum))
end

local function is_touching(realpos,nodepos,radius)
	local boarder = 0.5 - radius
	return math.abs(realpos - nodepos) > (boarder)
end

flowlib.is_touching = is_touching

local function is_water(pos)
	return minetest.get_item_group(minetest.get_node(pos).name, "water") ~= 0
end

flowlib.is_water = is_water

local function node_is_water(node)
	return minetest.get_item_group(node.name, "water") ~= 0
end

flowlib.node_is_water = node_is_water

local function is_lava(pos)
	return minetest.get_item_group(minetest.get_node(pos).name, "lava") ~= 0
end

flowlib.is_lava = is_lava

local function node_is_lava(node)
	return minetest.get_item_group(node.name, "lava") ~= 0
end

flowlib.node_is_lava = node_is_lava

local function is_liquid(pos)
	return minetest.get_item_group(minetest.get_node(pos).name, "liquid") ~= 0
end

flowlib.is_liquid = is_liquid

local function node_is_liquid(node)
	return minetest.get_item_group(node.name, "liquid") ~= 0
end

flowlib.node_is_liquid = node_is_liquid

--This code is more efficient
local function quick_flow_logic(node, pos_testing, direction)
	local name = node.name
	if not minetest.registered_nodes[name] then
		return 0
	end
	if minetest.registered_nodes[name].liquidtype == "source" then
		local node_testing = minetest.get_node(pos_testing)
		if not minetest.registered_nodes[node_testing.name] then
			return 0
		end
		if minetest.registered_nodes[node_testing.name].liquidtype ~= "flowing" then
			return 0
		else
			return direction
		end
	elseif minetest.registered_nodes[name].liquidtype == "flowing" then
		local node_testing = minetest.get_node(pos_testing)
		local param2_testing = node_testing.param2
		if not minetest.registered_nodes[node_testing.name] then
			return 0
		end
		if minetest.registered_nodes[node_testing.name].liquidtype == "source" then
			return -direction
		elseif minetest.registered_nodes[node_testing.name].liquidtype == "flowing" then
			if param2_testing < node.param2 then
				if (node.param2 - param2_testing) > 6 then
					return -direction
				else
					return direction
				end
			elseif param2_testing > node.param2 then
				if (param2_testing - node.param2) > 6 then
					return direction
				else
					return -direction
				end
			end
		end
	end
	return 0
end

local function quick_flow(pos, node)
	if not node_is_liquid(node)  then
		return vector.zero()
	end
	local x = quick_flow_logic(node, pos:copy():subtract(vector.new(1, 0, 0)), -1) + quick_flow_logic(node, pos:copy():add(vector.new(1, 0,0 )), 1)
	local z = quick_flow_logic(node, pos:copy():subtract(vector.new(0, 0, 1)), -1) + quick_flow_logic(node, pos:copy():add(vector.new(0, 0, 1)), 1)
	return to_unit_vector(vector.new(x, 0, z))
end

flowlib.quick_flow = quick_flow

--if not in water but touching, move centre to touching block
--x has higher precedence than z
--if pos changes with x, it affects z

local function move_centre(pos, realpos, node, radius)
	if is_touching(realpos.x, pos.x, radius) then
		local pl = pos:copy():subtract(vector.new(1, 0, 0))
		local pp = pos:copy():add(vector.new(1, 0, 0))
		if is_liquid(pl) then
			node = minetest.get_node(pl)
			pos = pl
		elseif is_liquid(pp) then
			node = minetest.get_node(pp)
			pos = pp
		end
	end
	if is_touching(realpos.z, pos.z, radius) then
		local pl = pos:copy():subtract(vector.new(0, 0, 1))
		local pp = pos:copy():add(vector.new(0, 0, 1))
		if is_liquid(pl) then
			node = minetest.get_node(pl)
			pos = pl
		elseif is_liquid(pp) then
			node = minetest.get_node(pp)
			pos = pp
		end
	end
	return pos, node
end

flowlib.move_centre = move_centre
