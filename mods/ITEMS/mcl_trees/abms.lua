-- Leaf Decay
local function leafdecay_particles(pos, node)
	minetest.add_particlespawner({
		amount = math.random(10, 20),
		time = 0.1,
		minpos = vector.add(pos, {x=-0.4, y=-0.4, z=-0.4}),
		maxpos = vector.add(pos, {x=0.4, y=0.4, z=0.4}),
		minvel = {x=-0.2, y=-0.2, z=-0.2},
		maxvel = {x=0.2, y=0.1, z=0.2},
		minacc = {x=0, y=-9.81, z=0},
		maxacc = {x=0, y=-9.81, z=0},
		minexptime = 0.1,
		maxexptime = 0.5,
		minsize = 0.5,
		maxsize = 1.5,
		collisiondetection = true,
		vertical = false,
		node = node,
	})
end

-- Whenever a tree trunk node is removed, all `group:leaves` nodes in a radius
-- of 6 blocks are checked from the trunk node's `after_destruct` handler.
-- Any such nodes within that radius that has no trunk node present within a
-- distance of 6 blocks is replaced with a `group:orphan_leaves` node.
--
-- The `group:orphan_leaves` nodes are gradually decayed in this ABM.
minetest.register_abm({
	label = "Leaf decay",
	nodenames = {"group:orphan_leaves"},
	interval = 5,
	chance = 10,
		action = function(pos, node)
		-- Spawn item entities for any of the leaf's drops
		local itemstacks = minetest.get_node_drops(node.name)
		for _, itemname in pairs(itemstacks) do
			local p_drop = vector.offset(pos, math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
			minetest.add_item(p_drop, itemname)
		end
		-- Remove the decayed node
		minetest.remove_node(pos)
		leafdecay_particles(pos, node)
		minetest.check_for_falling(pos)
	end
})

minetest.register_abm({
	label = "Tree growth",
	nodenames = {"group:sapling"},
	neighbors = {"group:soil_sapling","group:soil_propagule"},
	interval = 35,
	chance = 5,
	action = mcl_trees.grow_tree,
})

minetest.register_lbm({
	label = "Set old leaves param2",
	name = "mcl_trees:leaves_param2_update",
	nodenames = {"group:leaves"},
	run_at_every_load = false,
	action = function(pos, n)
		if minetest.get_item_group(n.name,"biomecolor") == 0 then return end
		local p2 = mcl_util.get_pos_p2(pos)
		if n.param2 ~= p2 then
			n.param2 = p2
			minetest.swap_node(pos, n)
		end
	end,
})
