local S = core.get_translator("mcl_bamboo")
local SCAFFOLD_HEIGHT_LIMIT = 320

function mcl_bamboo.check_structure(pos)
	local pr = PseudoRandom(core.hash_node_position(pos))
	local max_height = pr:next(12,16)
	local bottom = mcl_util.traverse_tower_group(pos,-1,"bamboo_tree")
	local top,h = mcl_util.traverse_tower_group(bottom,1,"bamboo_tree")
	local basenode = core.get_node(bottom)
	local basegroup = core.get_item_group(basenode.name, "bamboo_tree")
	local nn = core.find_nodes_in_area(
		bottom,
		vector.offset(bottom,0,max_height,0),
		{"group:bamboo_tree"}
	)

	-- Check growing in size
	if h > 1 and basegroup < 2 then
		if math.random() < 0.5 then
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_small"})
		else
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_big"})
		end
	end

	-- Update basegroup after size changes
	basenode = core.get_node(bottom)
	basegroup = core.get_item_group(basenode.name, "bamboo_tree")

	-- Check growing in leaf
	if basegroup == 1 then return end
	local size = basegroup == 2 and "small" or "big"
	local leaf_bamboo = "mcl_bamboo:bamboo_"..size.."_1"
	core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_"..size})
	if h > 3 then
		core.set_node(top, {name="mcl_bamboo:bamboo_"..size.."_2"})
		core.set_node(vector.offset(top,0,-1,0), {name="mcl_bamboo:bamboo_"..size.."_2"})
		core.set_node(vector.offset(top,0,-2,0), {name=leaf_bamboo})
	elseif h > 2 then
		core.set_node(top, {name=leaf_bamboo})
		core.set_node(vector.offset(top,0,-1,0), {name=leaf_bamboo})
	elseif h > 1 then
		core.set_node(top, {name=leaf_bamboo})
	end
end

function mcl_bamboo.grow(pos)
	local pr = PseudoRandom(core.hash_node_position(pos))
	local max_height = pr:next(12,16)
	local bottom = mcl_util.traverse_tower_group(pos,-1,"bamboo_tree")
	local top,h = mcl_util.traverse_tower_group(bottom,1,"bamboo_tree")

	if h < max_height and core.get_node_light(vector.offset(top,0,1,0)) >= 9 then
		if core.get_node(vector.offset(top,0,1,0)).name ~= "air" then return end
		core.set_node(vector.offset(top,0,1,0), {name=core.get_node(bottom).name})
		mcl_bamboo.check_structure(pos)
	end
end

local bamboo_def = {
	description = S("Bamboo"),
	tiles = {"mcl_bamboo_bamboo.png"},
	drawtype = "mesh",
	mesh = "mcl_bamboo_shoot.obj",
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = {
			{-6.4/16, -0.5, -6.4/16, 6.4/16, 0.25, 6.4/16}
		}
	},
	use_texture_alpha = "clip",
	groups = {
		handy=1, axey=1, swordy_bamboo=1, choppy=1,
		dig_by_piston=1, plant=1, non_mycelium_plant=1, flammable=3,
		bamboo=1, bamboo_tree=1, vinelike_node=1, unsticky=1,
		pathfinder_partial=2
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	drop = "mcl_bamboo:bamboo",
	inventory_image = "mcl_bamboo_bamboo_inv.png",
	wield_image = "mcl_bamboo_bamboo_inv.png",
	_mcl_burntime = 2.5,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1.5,
	node_placement_prediction = "",
	on_place = mcl_util.generate_on_place_plant_function(function(pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		return (core.get_item_group(node_below.name, "soil_bamboo") > 0 or bamboo_below),(bamboo_below and node_below.param2 or math.random(0,3))
	end),
	after_place_node = function (pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		if bamboo_below then
			core.set_node(pos, {name=node_below.name})
			mcl_bamboo.check_structure(pos)
		else
			core.set_node(pos, {name="mcl_bamboo:bamboo_shoot"})
		end
	end,
	_on_bone_meal = function(_, _, _, pos)
		return mcl_bamboo.grow(pos)
	end,
}

local cbox_small = {
	type = "fixed",
	fixed = {
		{-1/16, -0.5, -1/16, 1/16, 0.5, 1/16}
	}
}
local cbox_big = {
	type = "fixed",
	fixed = {
		{-1.5/16, -0.5, -1.5/16, 1.5/16, 0.5, 1.5/16}
	}
}

core.register_node("mcl_bamboo:bamboo_shoot", table.merge_deep(bamboo_def, {
	collision_box = {
		type = "fixed",
		fixed = {{0,0,0,0,0,0}}
	},
	groups = {not_in_creative_inventory=1},
}))
core.register_node("mcl_bamboo:bamboo_small", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "blank.png"},
	groups = {bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_small_1", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_small_2", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_big.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_big", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "blank.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_node("mcl_bamboo:bamboo_big_1", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_node("mcl_bamboo:bamboo_big_2", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_big.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_alias("mcl_bamboo:bamboo", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_1", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_2", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_3", "mcl_bamboo:bamboo_small")

mcl_flowerpots.register_potted_flower("mcl_bamboo:bamboo", {
	name = "bamboo",
	desc = S("Bamboo Plant"),
	image = "mcl_bamboo_flower_pot.png",
})

core.register_node("mcl_bamboo:bamboo_mosaic",  {
	description = S("Bamboo Mosaic Plank"),
	_doc_items_longdesc = S("Bamboo Mosaic Plank"),
	_doc_items_hidden = false,
	tiles = {"mcl_bamboo_bamboo_plank_mosaic.png"},
	is_ground_content = false,
	groups = {handy = 1, axey = 1, building_block = 1, flammable = 3, fire_encouragement = 5, fire_flammability = 20},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
	_mcl_burntime = 15
})

mcl_stairs.register_stair("bamboo_mosaic", {
	baseitem = "mcl_bamboo:bamboo_mosaic",
	description = S("Bamboo Mosaic Stairs"),
	overrides = {_mcl_burntime = 15}
})

mcl_stairs.register_slab("bamboo_mosaic", {
	baseitem = "mcl_bamboo:bamboo_mosaic",
	description = S("Bamboo Mosaic Slab"),
	overrides = {_mcl_burntime = 15}
})

local adjacents = {
	vector.new(0,0,1),
	vector.new(0,0,-1),
	vector.new(1,0,0),
	vector.new(-1,0,0),
}

local allowed_base_groups = { "solid", "slab_top" }

local function can_place_on(node)
	local def = core.registered_nodes[node.name]

	if not def then
		return false
	end

	for _, j in pairs(allowed_base_groups) do
		if core.get_item_group(node.name, j) > 0 then
			return true
		end
	end

	return false
end

core.register_node("mcl_bamboo:scaffolding", {
	description = S("Scaffolding"),
	doc_items_longdesc = S("Scaffolding is a temporary structure to easily climb up while building that is easily removed"),
	doc_items_hidden = false,
	tiles = {"mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_side.png","mcl_bamboo_scaffolding_bottom.png"},
	drawtype = "nodebox",
	paramtype = "light",
	use_texture_alpha = "clip",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, -0.375, 0.5, -0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, -0.375},
			{0.375, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, 0.375, -0.375, 0.5, 0.5},
		}
	},
	is_ground_content = false,
	walkable = false,
	climbable = true,
	physical = true,
	node_placement_prediction = "",
	groups = { handy=1, axey=1, flammable=3, deco_block=1, material_wood=1, fire_encouragement=5, fire_flammability=60, falling_node = 1, stack_falling = 1, scaffolding = 1, dig_by_piston = 1, unsticky = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 0,
	_mcl_burntime = 2.5,
	on_place = function(itemstack, placer, ptd)
		if not placer or not placer:is_player() then
			return itemstack
		end

		local ctrl = placer:get_player_control()
		local rc = mcl_util.call_on_rightclick(itemstack, placer, ptd)
		if rc then return rc end
		if not ptd then return end
		local node = core.get_node(ptd.under)

		if core.get_item_group(node.name,"scaffolding") > 0 and ctrl and ctrl.sneak then -- count param2 up when placing to the sides. Fall when > 6
			local pp2 = node.param2
			local np2 = pp2 + 1
			if core.get_node(vector.offset(ptd.above,0,-1,0)).name == "air" and core.get_node(ptd.above).name == "air" then
				itemstack = mcl_util.safe_place(ptd.above,{name = "mcl_bamboo:scaffolding_horizontal",param2 = np2}, placer, itemstack) or itemstack
			end
			if np2 > 6 then
				core.check_single_for_falling(ptd.above)
			end
		elseif node.name == "mcl_bamboo:scaffolding" then --tower up
			local bottom = mcl_util.traverse_tower(ptd.under,-1)
			local top,h = mcl_util.traverse_tower(bottom,1)
			local ppos = vector.offset(top,0,1,0)
			if h <= SCAFFOLD_HEIGHT_LIMIT and can_place_on(core.get_node(vector.offset(bottom,0,-1,0))) and core.get_node(ppos).name == "air" then
				itemstack = mcl_util.safe_place(ppos, node, placer, itemstack) or itemstack
			end

		elseif can_place_on(node) and core.get_node(ptd.above).name == "air" then
			itemstack = mcl_util.safe_place(ptd.above, {name = "mcl_bamboo:scaffolding"}, placer, itemstack) or itemstack
			core.check_single_for_falling(ptd.above)
		end
		return itemstack
	end,
	after_dig_node = function(pos, _, _, digger)
		mcl_util.traverse_tower(vector.offset(pos,0,1,0),1,function(pos, _, node)
			if node.name ~= "mcl_bamboo:scaffolding" then return true end
			if mcl_util.safe_place(pos, {name = "air"}, digger) then
				local digger_name = digger and digger:get_player_name() or ""
				if not core.is_creative_enabled(digger_name) then
					core.add_item(pos,"mcl_bamboo:scaffolding")
				end
				for _,v in pairs(adjacents) do
					core.check_for_falling(vector.add(pos,v))
				end
			end
		end)
	end,
	_mcl_after_falling = function(pos, _)
		if core.get_node(pos).name == "mcl_bamboo:scaffolding" then
			mcl_util.safe_place(pos,{name = "mcl_bamboo:scaffolding"})
		end
	end,
})

core.register_node("mcl_bamboo:scaffolding_horizontal", {
	description = S("Scaffolding horizontal"),
	doc_items_longdesc = S("Scaffolding block..."),
	doc_items_hidden = false,
	tiles = {"mcl_bamboo_scaffolding_side.png","mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_bottom.png"},
	drawtype = "nodebox",
	paramtype = "light",
	use_texture_alpha = "clip",
	drop = "mcl_bamboo:scaffolding",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, -0.375, 0.5, -0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, -0.375},
			{0.375, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, 0.375, -0.375, 0.5, 0.5},
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
		}
	},
	groups = { handy=1, axey=1, flammable=3, building_block=1, material_wood=1, fire_encouragement=5, fire_flammability=60, not_in_creative_inventory = 1, falling_node = 1, scaffolding = 1 },
	_mcl_after_falling = function(pos)
		if core.get_node(pos).name == "mcl_bamboo:scaffolding_horizontal" then
			local above = vector.offset(pos,0,1,0)
			if core.get_node(pos).name ~= "mcl_bamboo:scaffolding" then
				mcl_util.safe_place(pos, {name = "air"})
				core.add_item(pos,"mcl_bamboo:scaffolding")
			elseif core.get_node(above).name == "air" then
				mcl_util.safe_place(above, {name = "mcl_bamboo:scaffolding"})
			end
		end
	end
})
