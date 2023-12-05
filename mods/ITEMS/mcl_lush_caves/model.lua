-- Return a vegetation type with the following chances
--   Tall Grass: 52%
--   Moss Carpet: 26%
--   Double Grass: 10%
--   Azalea: 8%
--   Flowering Azalea: 4%
local function choose_moss_vegetation(next_integer)
	local x = next_integer(1, 100)
	if x <= 52 then
		return "mcl_flowers:tallgrass"
	elseif x <= 78 then
		return "mcl_lush_caves:moss_carpet"
	elseif x <= 88 then
		return "mcl_flowers:double_grass"
	elseif x <= 96 then
		return "mcl_lush_caves:azalea"
	else
		return "mcl_lush_caves:azalea_flowering"
	end
end

local function get_moss_vegetation(next_integer, can_build_double_grass)
	-- Return a vegetation only 60% of the time
	if next_integer(1, 5) < 3 then return end
	local retval = {}
	local vegetation = choose_moss_vegetation(next_integer)
	if vegetation == "mcl_flowers:double_grass" then
		if can_build_double_grass() then
			table.insert(retval, vegetation)
			table.insert(retval, "mcl_flowers:double_grass_top")
		else
			table.insert(retval, "mcl_flowers:tallgrass")
		end
	else
		table.insert(retval, vegetation)
	end
	return retval
end

-- Calls `set_node` with moss and vegetation where nodes from `positions` are
-- converted. Randomization comes from `next_integer`.
--
-- `pos` is the position of the original moss node
-- `max` is a table `{x=maximum_x, z=maximum_z}` that describes the maxium x and z distances from pos
-- `positions` is an array of vectors of nodes that all must be convertible to moss and be under air
-- `set_node(v, n)` must accept a position vector `v` and node value `n`
-- `can_build_double_grass(v)` returns true if Double Grass is allowed in the two nodes above the position given by vector `v`
-- `next_integer(a, b)` must generate an integer in the range [a, b]
function mcl_lush_caves.bone_meal_moss(pos, max, positions, set_node, can_build_double_grass, next_integer)

	local set = function(pos)
		set_node(pos, { name="mcl_lush_caves:moss" })
		local v = get_moss_vegetation(next_integer, can_build_double_grass(pos))
		if v ~= nil then
			set_node(vector.offset(pos, 0, 1, 0), { name=v[1] })
			if #v > 1 then
				set_node(vector.offset(pos, 0, 2, 0), { name=v[2] })
			end
		end
	end

	for _, conversion_pos in pairs(positions) do
		local x_distance = math.abs(pos.x - conversion_pos.x)
		local z_distance = math.abs(pos.z - conversion_pos.z)

		-- Corner positions do not get moss
		if not ( x_distance == max.x and z_distance == max.z ) then
			if x_distance == max.x or z_distance == max.z then
				-- 75% chance of sides getting moss
				if next_integer(1, 4) ~= 1 then
					set(conversion_pos)
				end
			else
				-- Other positions always get moss
				set(conversion_pos)
			end
		end
	end
	return true
end
