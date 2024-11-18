function mcl_redstone._new_mapcache()
	local mapcache = {}
	local cache = {}

	local function fetch_node(h, pos)
		if cache[h] then
			return
		end
		cache[h] = minetest.get_node(pos)
	end

	function mapcache:get_node(pos)
		local h = minetest.hash_node_position(pos)
		fetch_node(h, pos)

		return cache[h]
	end

	function mapcache:set_node(pos, node)
		cache[minetest.hash_node_position(pos)] = {
			name = node.name,
			param2 = node.param2 or 0,
		}
	end

	function mapcache:set_param2(pos, param2)
		local h = minetest.hash_node_position(pos)
		fetch_node(h, pos)

		cache[h].param2 = param2
	end

	function mapcache:write_to_map()
		for h, _ in pairs(cache) do
			local pos = minetest.get_position_from_hash(h)
			local node = cache[h]
			if node.name ~= "ignore" then
				minetest.swap_node(pos, cache[h])
			end
		end
	end

	return mapcache
end
