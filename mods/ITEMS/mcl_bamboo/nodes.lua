local S = core.get_translator("mcl_bamboo")
local SCAFFOLD_HEIGHT_LIMIT = 320

function mcl_bamboo.random(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
	return pr:next(1,4)
end

function mcl_bamboo.check_structure(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
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
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_small", param2=basenode.param2})
		else
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_big", param2=basenode.param2})
		end
	end

	-- Update basegroup after size changes
	basenode = core.get_node(bottom)
	basegroup = core.get_item_group(basenode.name, "bamboo_tree")

	-- Check growing in leaf
	if basegroup == 1 then return end
	local size = basegroup == 2 and "small" or "big"
	local leaf_bamboo = "mcl_bamboo:bamboo_"..size.."_leafsmall"
	core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_"..size, param2=basenode.param2})
	if h > 3 then
		core.set_node(top, {name="mcl_bamboo:bamboo_"..size.."_leafbig", param2=basenode.param2})
		core.set_node(vector.offset(top,0,-1,0), {name="mcl_bamboo:bamboo_"..size.."_leafbig", param2=basenode.param2})
		core.set_node(vector.offset(top,0,-2,0), {name=leaf_bamboo, param2=basenode.param2})
	elseif h > 2 then
		core.set_node(top, {name=leaf_bamboo, param2=basenode.param2})
		core.set_node(vector.offset(top,0,-1,0), {name=leaf_bamboo, param2=basenode.param2})
	elseif h > 1 then
		core.set_node(top, {name=leaf_bamboo, param2=basenode.param2})
	end
end

function mcl_bamboo.grow(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
	local max_height = pr:next(12,16)
	local bottom = mcl_util.traverse_tower_group(pos,-1,"bamboo_tree")
	local top,h = mcl_util.traverse_tower_group(bottom,1,"bamboo_tree")

	local light = core.get_node_light(vector.offset(top,0,1,0)) or 0
	if h < max_height and light >= 9 then
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
	paramtype2 = "4dir",
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
	_mcl_hardness = 1,
	node_placement_prediction = "",
	on_place = mcl_util.generate_on_place_plant_function(function(pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		local result = core.get_item_group(node_below.name, "soil_bamboo") > 0 or bamboo_below
		local param2 = bamboo_below and node_below.param2 or mcl_bamboo.random(pos)
		return result, param2
	end),
	after_place_node = function (pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		if bamboo_below then
			core.swap_node(pos, {name=node_below.name})
			mcl_bamboo.check_structure(pos)
		else
			core.set_node(pos, {name="mcl_bamboo:bamboo_shoot", param2=mcl_bamboo.random(pos)})
		end
	end,
	_on_bone_meal = function(_, _, _, pos)
		return mcl_bamboo.grow(pos)
	end,
}

local cbox_small = {
	type = "fixed",
	fixed = {
		{0.1875, -0.5, -0.3125, 0.3125, 0.5, -0.1875}
	}
}
local cbox_big = {
	type = "fixed",
	fixed = {
		{0.1575, -0.5, -0.3425, 0.3425, 0.5, -0.1575}
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
core.register_node("mcl_bamboo:bamboo_small_leafsmall", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_small_leafbig", table.merge_deep(bamboo_def, {
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
core.register_node("mcl_bamboo:bamboo_big_leafsmall", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_node("mcl_bamboo:bamboo_big_leafbig", table.merge_deep(bamboo_def, {
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

mcl_flowerpots.register_potted_cube("mcl_bamboo:bamboo_small", {
	name = "bamboo",
	desc = S("Bamboo Plant"),
	image = "mcl_bamboo_bamboo_fpm.png",
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

-- copy from https://github.com/luanti-org/luanti/blob/5.15.1/builtin/game/falling.lua#L333C1-L352C1
local function convert_to_falling_node(pos, node)
	local obj = core.add_entity(pos, "__builtin:falling_node")
	if not obj then
		return false
	end
	-- remember node level, the entities' set_node() uses this
	node.level = core.get_node_level(pos)
	local meta = core.get_meta(pos)
	local metatable = meta and meta:to_table() or {}

	local def = core.registered_nodes[node.name]
	if def and def.sounds and def.sounds.fall then
		core.sound_play(def.sounds.fall, {pos = pos}, true)
	end

	obj:get_luaentity():set_node(node, metatable)
	core.remove_node(pos)
	return true, obj
end

-- based on https://github.com/luanti-org/luanti/blob/5.15.1/builtin/game/falling.lua#L441 core.check_single_for_falling
local function check_single_for_falling(p)
	local n = core.get_node(p)
	if core.get_item_group(n.name, "scaffolding") ~= 0 then
		local p_bottom = vector.offset(p, 0, -1, 0)
		-- Only spawn falling node if node below is loaded
		local n_bottom = core.get_node_or_nil(p_bottom)
		local d_bottom = n_bottom and core.registered_nodes[n_bottom.name]
		if d_bottom then
			-- Otherwise only if the bottom node is considered "fall through"
			if core.get_item_group(n_bottom.name, "scaffolding") == 0
			and (not d_bottom.walkable or d_bottom.buildable_to)
				then
				local success, _ = convert_to_falling_node(p, n)
				return success
			end
		end
	end

	return false
end

local function after_dig_scaffolding(pos, oldnode, _, digger)
	for _,v in pairs(adjacents) do
		local npos = vector.add(pos,v)
		local nnode = core.get_node(npos)
		if nnode.name == "mcl_bamboo:scaffolding_horizontal" and nnode.param2 > oldnode.param2 then
			if check_single_for_falling(npos) then
				after_dig_scaffolding(npos, nnode, _, digger)
			end
		end
	end
	mcl_util.traverse_tower(vector.offset(pos,0,1,0),1,function(upos, _, unode)
		if unode.name ~= "mcl_bamboo:scaffolding" then return true end
		if check_single_for_falling(upos) then
			after_dig_scaffolding(upos, unode, _, digger)
		end
	end)
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
	groups = { handy=1, axey=1, flammable=3, deco_block=1, material_wood=1, fire_encouragement=5, fire_flammability=60, scaffolding = 1, dig_by_piston = 1, unsticky = 1},
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

		if core.get_item_group(node.name,"scaffolding") > 0 then
			local ppos = ptd.above
			-- count param2 up when placing to the sides. Fall when > 6
			local pp2 = node.param2
			local np2 = pp2 + 1
			local arc = placer:get_look_vertical() * (180 / math.pi)

			if ctrl and ctrl.sneak then
				if core.get_node(vector.offset(ppos,0,-1,0)).name == "air" and core.get_node(ppos).name == "air" then
					itemstack = mcl_util.safe_place(ppos,{name = "mcl_bamboo:scaffolding_horizontal",param2 = np2}, placer, itemstack) or itemstack
					if np2 > 6 and not check_single_for_falling(ppos) then
						mcl_util.safe_place(ppos,{name = "mcl_bamboo:scaffolding"}, placer)
					end
				end
			elseif arc > 45 and arc < 90 then
				local p2 = core.dir_to_facedir(placer:get_look_dir())
				local offset_z = p2 % 2 == 0 and 0 - (p2 -1) or 0
				local offset_x = p2 % 2 ~= 0 and 2 - p2 or 0

				ppos = vector.offset(ppos, offset_x, -1, offset_z)
				node = core.get_node(ppos)
				while np2 <= 6
					and core.get_item_group(node.name,"scaffolding") > 0
					and ( core.get_node(vector.offset(ppos, offset_x, 0, offset_z)).name == "air"
					   or core.get_item_group(core.get_node(vector.offset(ppos, offset_x, 0, offset_z)).name,"scaffolding") > 0
					    )
					do
					np2 = node.param2 + 1
					ppos = vector.offset(ppos, offset_x, 0, offset_z)
					node = core.get_node(ppos)
				end
				if node.name == "air" then
					itemstack = mcl_util.safe_place(ppos,{name = "mcl_bamboo:scaffolding_horizontal",param2 = np2}, placer, itemstack) or itemstack
					if np2 > 6 and not check_single_for_falling(ppos) then
						mcl_util.safe_place(ppos,{name = "mcl_bamboo:scaffolding"}, placer)
					end
				end
			else --tower up
				local function walk_under(bottom)
					local last_under = bottom
					local under = vector.offset(bottom, 0, -1, 0)
					local unode = core.get_node(under)
					while last_under ~= under and unode.name == "mcl_bamboo:scaffolding_horizontal" do
						last_under = under
						for _,v in pairs(adjacents) do
							local npos = vector.add(under,v)
							local nnode = core.get_node(npos)
							if nnode.name == "mcl_bamboo:scaffolding" then
								under = vector.offset(mcl_util.traverse_tower(npos,-1), 0, -1, 0)
								unode = core.get_node(under)
								break
							elseif nnode.name == "mcl_bamboo:scaffolding_horizontal" and nnode.param2 == unode.param2 -1 then
								under = npos
								unode = nnode
								break
							end
						end
					end
					return under
				end

				local h
				if node.name == "mcl_bamboo:scaffolding" then
					local bottom = mcl_util.traverse_tower(ptd.under,-1)
					local top = mcl_util.traverse_tower(bottom,1)
					ppos = vector.offset(top,0,1,0)

					local under = walk_under(bottom)
					h = top.y - under.y
				else
					local under = walk_under(ppos)
					h = ppos.y - under.y
				end
				if h <= SCAFFOLD_HEIGHT_LIMIT and core.get_node(ppos).name == "air" then
					itemstack = mcl_util.safe_place(ppos, {name = "mcl_bamboo:scaffolding",param2 = pp2}, placer, itemstack) or itemstack
				end
			end
		elseif can_place_on(node) and core.get_node(ptd.above).name == "air" then
			itemstack = mcl_util.safe_place(ptd.above, {name = "mcl_bamboo:scaffolding"}, placer, itemstack) or itemstack
			check_single_for_falling(ptd.above)
		end
		return itemstack
	end,
	after_dig_node = function(pos, oldnode, _, digger)
		after_dig_scaffolding(pos, oldnode, _, digger)
	end,
	_mcl_after_falling = function(pos, _)
		mcl_util.safe_place(pos, {name = "air"})
		core.add_item(pos,"mcl_bamboo:scaffolding")
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
	is_ground_content = false,
	walkable = false,
	climbable = true,
	physical = true,
	groups = { handy=1, axey=1, flammable=3, building_block=1, material_wood=1, fire_encouragement=5, fire_flammability=60, not_in_creative_inventory = 1, scaffolding = 1, dig_by_piston = 1, unsticky = 1 },
	after_dig_node = after_dig_scaffolding,
	_mcl_after_falling = function(pos)
		local node = core.get_node(pos)
		if node.name == "mcl_bamboo:scaffolding_horizontal" and node.param2 > 6 then
			mcl_util.safe_place(pos, {name = "mcl_bamboo:scaffolding"})
		else
			mcl_util.safe_place(pos, {name = "air"})
			core.add_item(pos,"mcl_bamboo:scaffolding")
		end
	end
})
