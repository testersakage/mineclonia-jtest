-- Compatibility polyfills for legacy minetest
--
-- polyfill for minetest < 5.9
if not vector.random_direction then
	function vector.random_direction()
		-- Generate a random direction of unit length, via rejection sampling
		local x, y, z, l2
		repeat -- expected less than two attempts on average (volume sphere vs. cube)
			x, y, z = math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1
			l2 = x*x + y*y + z*z
		until l2 <= 1 and l2 >= 1e-6
		-- normalize
		local l = math.sqrt(l2)
		return vector.new(x/l, y/l, z/l)
	end
end

local function valid_object_iterator(objects)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		if obj:get_pos() then
			return obj
		end
		return next_valid_object()
	end
	return next_valid_object
end

local function valid_object_iterator_in_radius(objects, center, radius)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		local p = obj:get_pos()
		if p and vector.distance(p, center) <= radius then
			return obj
		end
		return next_valid_object()
	end
	return next_valid_object
end

function mcl_util.connected_players(center, radius)
	local pls = minetest.get_connected_players()
	if not center then return valid_object_iterator(pls) end
	return valid_object_iterator_in_radius(pls, center, radius or 1)
end

if not minetest.objects_inside_radius then --polyfill for pre minetest 5.9
	function core.objects_inside_radius(center, radius)
		return valid_object_iterator(core.get_objects_inside_radius(center, radius))
	end

	function core.objects_in_area(min_pos, max_pos)
		return valid_object_iterator(core.get_objects_in_area(min_pos, max_pos))
	end
end

if not vector.in_area then
	function vector.in_area(pos, min, max)
		return (pos.x >= min.x) and (pos.x <= max.x) and
			(pos.y >= min.y) and (pos.y <= max.y) and
			(pos.z >= min.z) and (pos.z <= max.z)
	end
end
