local S = minetest.get_translator(minetest.get_current_modname())

local PISTON_MAXIMUM_PUSH = 12

local function piston_facedir_direction(node)
	return -minetest.facedir_to_dir(node.param2)
end

local function piston_get_direction(dir, node)
	if type(dir) == "function" then
		return dir(node)
	else
		return dir
	end
end

-- Remove pusher of piston.
-- To be used when piston was destroyed or dug.
local function piston_remove_pusher(pos, oldnode)
	local pistonspec = minetest.registered_nodes[oldnode.name].mesecons_piston

	local dir = piston_get_direction(pistonspec.dir, oldnode)
	local pusherpos = vector.add(pos, dir)
	local pushername = minetest.get_node(pusherpos).name

	if pushername == pistonspec.pusher then -- make sure there actually is a pusher
		minetest.remove_node(pusherpos)
		minetest.check_for_falling(pusherpos)
		minetest.sound_play("piston_retract", {
			pos = pos,
			max_hear_distance = 31,
			gain = 0.3,
		}, true)
	end
end

-- Remove base node of piston.
-- To be used when pusher was destroyed.
local function piston_remove_base(pos, oldnode)
	local basenodename = minetest.registered_nodes[oldnode.name].corresponding_piston
	local pistonspec = minetest.registered_nodes[basenodename].mesecons_piston

	local dir = piston_get_direction(pistonspec.dir, oldnode)
	local basepos = vector.subtract(pos, dir)
	local basename = minetest.get_node(basepos).name

	if basename == pistonspec.onname then -- make sure there actually is a base node
		minetest.remove_node(basepos)
		minetest.check_for_falling(basepos)
		minetest.sound_play("piston_retract", {
			pos = pos,
			max_hear_distance = 31,
			gain = 0.3,
		}, true)
	end
end

local function piston_on(pos, node)
	local pistonspec = minetest.registered_nodes[node.name].mesecons_piston

	local dir = piston_get_direction(pistonspec.dir, node)
	local np = vector.add(pos, dir)
	local meta = minetest.get_meta(pos)
	local success, _, oldstack = mesecon.mvps_push(np, dir, PISTON_MAXIMUM_PUSH, meta:get_string("owner"), pos)
	if success then
		minetest.swap_node(pos, {param2 = node.param2, name = pistonspec.onname})
		minetest.set_node(np, {param2 = node.param2, name = pistonspec.pusher})
		local below = minetest.get_node({x=np.x,y=np.y-1,z=np.z})
		if below.name == "mcl_farming:soil" or below.name == "mcl_farming:soil_wet" then
			minetest.set_node({x=np.x,y=np.y-1,z=np.z}, {name = "mcl_core:dirt"})
		end
		mesecon.mvps_move_objects(np, dir, oldstack)
		minetest.sound_play("piston_extend", {
			pos = pos,
			max_hear_distance = 31,
			gain = 0.3,
		}, true)
	end
end

local function piston_off(pos, node)
	local pistonspec = minetest.registered_nodes[node.name].mesecons_piston
	minetest.swap_node(pos, {param2 = node.param2, name = pistonspec.offname})
	piston_remove_pusher (pos, node)
	if not pistonspec.sticky then
		return
	end

	local dir = piston_get_direction(pistonspec.dir, node)
	local pullpos = vector.add(pos, vector.multiply(dir, 2))
	local meta = minetest.get_meta(pos)
	mesecon.mvps_pull_single(pullpos, vector.multiply(dir, -1), PISTON_MAXIMUM_PUSH, meta:get_string("owner"), pos)
end

local function piston_orientate(pos, placer)
	-- not placed by player
	if not placer then return end

	-- placer pitch in degrees
	local pitch = placer:get_look_vertical() * (180 / math.pi)

	local node = minetest.get_node(pos)
	local pistonspec = minetest.registered_nodes[node.name].mesecons_piston
	if pitch > 55 then
		minetest.add_node(pos, {name=pistonspec.piston_up})
	elseif pitch < -55 then
		minetest.add_node(pos, {name=pistonspec.piston_down})
	end

	-- set owner meta after setting node, or it will not keep
	mesecon.mvps_set_owner(pos, placer)
end


-- Horizontal pistons

local pt = 4/16 -- pusher thickness

local piston_pusher_box = {
	type = "fixed",
	fixed = {
		{-2/16, -2/16, -.5 + pt, 2/16, 2/16,  .5 + pt},
		{-.5  , -.5  , -.5     , .5  , .5  , -.5 + pt},
	},
}

local piston_on_box = {
	type = "fixed",
	fixed = {
		{-.5, -.5, -.5 + pt, .5, .5, .5}
	},
}


-- Normal (non-sticky) ones:

local pistonspec_normal = {
	offname = "mesecons_pistons:piston_normal_off",
	onname = "mesecons_pistons:piston_normal_on",
	dir = piston_facedir_direction,
	pusher = "mesecons_pistons:piston_pusher_normal",
	piston_down = "mesecons_pistons:piston_down_normal_off",
	piston_up   = "mesecons_pistons:piston_up_normal_off",
}

local usagehelp_piston = S("This block can have one of 6 possible orientations.")

local function powered_facing_dir(pos, dir)
	return (dir.x ~= 1 and mcl_redstone.get_power(pos, vector.new(1, 0, 0)) ~= 0) or
		(dir.x ~= -1 and mcl_redstone.get_power(pos, vector.new(-1, 0, 0)) ~= 0) or
		(dir.y ~= 1 and mcl_redstone.get_power(pos, vector.new(0, 1, 0)) ~= 0) or
		(dir.y ~= -1 and mcl_redstone.get_power(pos, vector.new(0, -1, 0)) ~= 0) or
		(dir.z ~= 1 and mcl_redstone.get_power(pos, vector.new(0, 0, 1)) ~= 0) or
		(dir.z ~= -1 and mcl_redstone.get_power(pos, vector.new(0, 0, -1)) ~= 0)
end

local commdef = {
	_doc_items_create_entry = false,
	groups = {handy=1, not_opaque=1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 0.5,
	_mcl_hardness = 0.5,
	on_rotate = function(pos, node, user, mode)
		if mode == screwdriver.ROTATE_AXIS then
			minetest.set_node(pos, {name="mesecons_pistons:piston_up_normal_off"})
			return true
		end
	end,
}

local normaldef = table.merge(commdef, {
	description = S("Piston"),
	groups = table.merge(commdef.groups, {piston=1}),
	mesecons_piston = pistonspec_normal,
})

local offdef = {
	_mcl_redstone = {
		update = function(pos, node)
			local dir = -minetest.facedir_to_dir(node.param2)
			if powered_facing_dir(pos, dir) then
				piston_on(pos, node)
			end
		end,
	},
}

local ondef = {
	drawtype = "nodebox",
	node_box = piston_on_box,
	selection_box = piston_on_box,
	after_destruct = piston_remove_pusher,
	on_rotate = false,
	_mcl_redstone = {
		update = function(pos, node)
			local dir = -minetest.facedir_to_dir(node.param2)
			if not powered_facing_dir(pos, dir) then
				piston_off(pos, node)
			end
		end,
	},
}

local pusherdef = {
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	after_destruct = piston_remove_base,
	diggable = false,
	drop = "",
	selection_box = piston_pusher_box,
	node_box = piston_pusher_box,
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 0.5,
	on_rotate = false,
	_mcl_redstone = {
		-- It is possible for a piston to extend just before server
		-- shutdown. To avoid circuits stopping because of that we
		-- update all neighbouring nodes during loading as if a
		-- redstone block was just removed at the pusher.
		init = function(pos, node)
			mcl_redstone._update_neighbours(pos, {
				name = "mcl_redstone_torch:redstoneblock",
				param2 = 0,
			})
		end,
	},
}

-- offstate
minetest.register_node("mesecons_pistons:piston_normal_off", table.merge(normaldef, offdef, {
	_doc_items_create_entry = true,
	_tt_help = S("Pushes block when powered by redstone power"),
	_doc_items_longdesc = S("A piston is a redstone component with a pusher which pushes the block or blocks in front of it when it is supplied with redstone power. Not all blocks can be pushed, however."),
	_doc_items_usagehelp = usagehelp_piston,
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_pusher_front.png"
	},
	after_place_node = piston_orientate,
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_normal_on", table.merge(normaldef, ondef, {
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png"
	},
	groups = table.merge(normaldef.groups, {not_in_creative_inventory=1}),
	drop = "mesecons_pistons:piston_normal_off",
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_pusher_normal", table.merge(pusherdef, {
	tiles = {
		"mesecons_piston_pusher_top.png",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_left.png",
		"mesecons_piston_pusher_right.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front.png"
	},
	groups = {piston_pusher=1},
	corresponding_piston = "mesecons_pistons:piston_normal_on",
}))

-- Sticky ones

local pistonspec_sticky = {
	offname = "mesecons_pistons:piston_sticky_off",
	onname = "mesecons_pistons:piston_sticky_on",
	dir = piston_facedir_direction,
	pusher = "mesecons_pistons:piston_pusher_sticky",
	sticky = true,
	piston_down = "mesecons_pistons:piston_down_sticky_off",
	piston_up   = "mesecons_pistons:piston_up_sticky_off",
}

local stickydef = table.merge(commdef, {
	description = S("Sticky Piston"),
	groups = table.merge(commdef.groups, {piston=2}),
	mesecons_piston = pistonspec_sticky,
})

-- offstate
minetest.register_node("mesecons_pistons:piston_sticky_off", table.merge(stickydef, offdef, {
	_doc_items_create_entry = true,
	_tt_help = S("Pushes or pulls block when powered by redstone power"),
	_doc_items_longdesc = S("A sticky piston is a redstone component with a sticky pusher which can be extended and retracted. It extends when it is supplied with redstone power. When the pusher extends, it pushes the block or blocks in front of it. When it retracts, it pulls back the single block in front of it. Note that not all blocks can be pushed or pulled."),
	_doc_items_usagehelp = usagehelp_piston,
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_pusher_front_sticky.png"
	},
	after_place_node = piston_orientate,
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_sticky_on", table.merge(stickydef, ondef, {
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png"
	},
	groups = table.merge(stickydef.groups, {not_in_creative_inventory=1}),
	drop = "mesecons_pistons:piston_sticky_off",
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_pusher_sticky", table.merge(pusherdef, {
	tiles = {
		"mesecons_piston_pusher_top.png",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_left.png",
		"mesecons_piston_pusher_right.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front_sticky.png"
	},
	groups = {piston_pusher=2},
	corresponding_piston = "mesecons_pistons:piston_sticky_on",
}))

--
--
-- UP
--
--

local piston_up_pusher_box = {
	type = "fixed",
	fixed = {
		{-2/16, -.5 - pt, -2/16, 2/16, .5 - pt, 2/16},
		{-.5  ,  .5 - pt, -.5  , .5  , .5     ,   .5},
	},
}

local piston_up_on_box = {
	type = "fixed",
	fixed = {
		{-.5, -.5, -.5 , .5, .5-pt, .5}
	},
}

-- Normal

local pistonspec_normal_up = {
	offname = "mesecons_pistons:piston_up_normal_off",
	onname = "mesecons_pistons:piston_up_normal_on",
	dir = {x = 0, y = 1, z = 0},
	pusher = "mesecons_pistons:piston_up_pusher_normal",
}

local offupdef = table.merge(offdef, {
	sounds = mcl_sounds.node_sound_stone_defaults({
		footstep = mcl_sounds.node_sound_wood_defaults().footstep
	}),
	_mcl_redstone = {
		update = function(pos, node)
			if powered_facing_dir(pos, vector.new(0, 1, 0)) then
				piston_on(pos, node)
			end
		end,
	},
})

local onupdef = table.merge(ondef, {
	node_box = piston_up_on_box,
	selection_box = piston_up_on_box,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_redstone = {
		update = function(pos, node)
			if not powered_facing_dir(pos, vector.new(0, 1, 0)) then
				piston_off(pos, node)
			end
		end,
	},
})

local normalupdef = table.merge(normaldef, {
	mesecons_piston = pistonspec_normal_up,
	drop = "mesecons_pistons:piston_normal_off",
	groups = table.merge(normaldef.groups, {not_in_creative_inventory=1}),
})

local pusherupdef = table.merge(pusherdef, {
	selection_box = piston_up_pusher_box,
	node_box = piston_up_pusher_box,
})

-- offstate
minetest.register_node("mesecons_pistons:piston_up_normal_off", table.merge(normalupdef, offupdef, {
	tiles = {
		"mesecons_piston_pusher_front.png",
		"mesecons_piston_back.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
	},
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_up_normal_on", table.merge(normalupdef, onupdef, {
	tiles = {
		"mesecons_piston_on_front.png",
		"mesecons_piston_back.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
	},
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_up_pusher_normal", table.merge(pusherupdef, {
	tiles = {
		"mesecons_piston_pusher_front.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_left.png^[transformR270",
		"mesecons_piston_pusher_right.png^[transformR90",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_top.png^[transformR180",
	},
	groups = {piston_pusher=1},
	is_ground_content = false,
	corresponding_piston = "mesecons_pistons:piston_up_normal_on",
}))

-- Sticky

local pistonspec_sticky_up = {
	offname = "mesecons_pistons:piston_up_sticky_off",
	onname = "mesecons_pistons:piston_up_sticky_on",
	dir = {x = 0, y = 1, z = 0},
	pusher = "mesecons_pistons:piston_up_pusher_sticky",
	sticky = true,
}

local stickyupdef = table.merge(stickydef, {
	mesecons_piston = pistonspec_sticky_up,
	drop = "mesecons_pistons:piston_sticky_off",
	groups = table.merge(stickydef.groups, {not_in_creative_inventory=1}),
})

-- offstate
minetest.register_node("mesecons_pistons:piston_up_sticky_off", table.merge(stickyupdef, offupdef, {
	tiles = {
		"mesecons_piston_pusher_front_sticky.png",
		"mesecons_piston_back.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
	},
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_up_sticky_on", table.merge(stickyupdef, onupdef, {
	tiles = {
		"mesecons_piston_on_front.png",
		"mesecons_piston_back.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png",
	},
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_up_pusher_sticky", table.merge(pusherupdef, {
	tiles = {
		"mesecons_piston_pusher_front_sticky.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_left.png^[transformR270",
		"mesecons_piston_pusher_right.png^[transformR90",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_top.png^[transformR180",
	},
	groups = {piston_pusher=2},
	corresponding_piston = "mesecons_pistons:piston_up_sticky_on",
}))

--
--
-- DOWN
--
--

local piston_down_pusher_box = {
	type = "fixed",
	fixed = {
		{-2/16, -.5 + pt, -2/16, 2/16,  .5 + pt, 2/16},
		{-.5  , -.5     , -.5  , .5  , -.5 + pt,   .5},
	},
}

local piston_down_on_box = {
	type = "fixed",
	fixed = {
		{-.5, -.5+pt, -.5 , .5, .5, .5}
	},
}


-- Normal

local pistonspec_normal_down = {
	offname = "mesecons_pistons:piston_down_normal_off",
	onname = "mesecons_pistons:piston_down_normal_on",
	dir = {x = 0, y = -1, z = 0},
	pusher = "mesecons_pistons:piston_down_pusher_normal",
}

local offdowndef = table.merge(offdef, {
	_mcl_redstone = {
		update = function(pos, node)
			if powered_facing_dir(pos, vector.new(0, -1, 0)) then
				piston_on(pos, node)
			end
		end,
	},
})

local ondowndef = table.merge(ondef, {
	node_box = piston_down_on_box,
	selection_box = piston_down_on_box,
	_mcl_redstone = {
		update = function(pos, node)
			if not powered_facing_dir(pos, vector.new(0, -1, 0)) then
				piston_off(pos, node)
			end
		end,
	},
})

local normaldowndef = table.merge(normalupdef, {
	mesecons_piston = pistonspec_normal_down,
})

local pusherdowndef = table.merge(pusherupdef, {
	selection_box = piston_down_pusher_box,
	node_box = piston_down_pusher_box,
})

-- offstate
minetest.register_node("mesecons_pistons:piston_down_normal_off", table.merge(normaldowndef, offdowndef, {
	tiles = {
		"mesecons_piston_back.png",
		"mesecons_piston_pusher_front.png",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
	},
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_down_normal_on", table.merge(normaldowndef, ondowndef, {
	tiles = {
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
	},
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_down_pusher_normal", table.merge(pusherdowndef, {
	tiles = {
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front.png",
		"mesecons_piston_pusher_left.png^[transformR90",
		"mesecons_piston_pusher_right.png^[transformR270",
		"mesecons_piston_pusher_bottom.png^[transformR180",
		"mesecons_piston_pusher_top.png",
	},
	groups = {piston_pusher=1},
	is_ground_content = false,
	corresponding_piston = "mesecons_pistons:piston_down_normal_on",
}))

-- Sticky

local pistonspec_sticky_down = {
	onname = "mesecons_pistons:piston_down_sticky_on",
	offname = "mesecons_pistons:piston_down_sticky_off",
	dir = {x = 0, y = -1, z = 0},
	pusher = "mesecons_pistons:piston_down_pusher_sticky",
	sticky = true,
}

local stickydowndef = table.merge(stickyupdef, {
	mesecons_piston = pistonspec_sticky_down,
	sounds = mcl_sounds.node_sound_stone_defaults(),
})

-- offstate
minetest.register_node("mesecons_pistons:piston_down_sticky_off", table.merge(stickydowndef, offdowndef, {
	tiles = {
		"mesecons_piston_back.png",
		"mesecons_piston_pusher_front_sticky.png",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
	},
}))

-- onstate
minetest.register_node("mesecons_pistons:piston_down_sticky_on", table.merge(stickydowndef, ondowndef, {
	tiles = {
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png^[transformR180",
	},
}))

-- pusher
minetest.register_node("mesecons_pistons:piston_down_pusher_sticky", table.merge(pusherdowndef, {
	tiles = {
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front_sticky.png",
		"mesecons_piston_pusher_left.png^[transformR90",
		"mesecons_piston_pusher_right.png^[transformR270",
		"mesecons_piston_pusher_bottom.png^[transformR180",
		"mesecons_piston_pusher_top.png",
	},
	groups = {piston_pusher=2},
	corresponding_piston = "mesecons_pistons:piston_down_sticky_on",
}))


mesecon.register_mvps_stopper("mesecons_pistons:piston_pusher_normal")
mesecon.register_mvps_stopper("mesecons_pistons:piston_pusher_sticky")
mesecon.register_mvps_stopper("mesecons_pistons:piston_up_pusher_normal")
mesecon.register_mvps_stopper("mesecons_pistons:piston_up_pusher_sticky")
mesecon.register_mvps_stopper("mesecons_pistons:piston_down_pusher_normal")
mesecon.register_mvps_stopper("mesecons_pistons:piston_down_pusher_sticky")
mesecon.register_mvps_stopper("mesecons_pistons:piston_normal_on")
mesecon.register_mvps_stopper("mesecons_pistons:piston_sticky_on")
mesecon.register_mvps_stopper("mesecons_pistons:piston_up_normal_on")
mesecon.register_mvps_stopper("mesecons_pistons:piston_up_sticky_on")
mesecon.register_mvps_stopper("mesecons_pistons:piston_down_normal_on")
mesecon.register_mvps_stopper("mesecons_pistons:piston_down_sticky_on")

--craft recipes
minetest.register_craft({
	output = "mesecons_pistons:piston_normal_off",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"mcl_core:cobble", "mcl_core:iron_ingot", "mcl_core:cobble"},
		{"mcl_core:cobble", "mcl_redstone:redstone", "mcl_core:cobble"},
	},
})

minetest.register_craft({
	output = "mesecons_pistons:piston_sticky_off",
	recipe = {
		{"mcl_mobitems:slimeball"},
		{"mesecons_pistons:piston_normal_off"},
	},
})

-- Add entry aliases for the Help
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_normal_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_up_normal_off")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_up_normal_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_down_normal_off")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_down_normal_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_pusher_normal")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_up_pusher_normal")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_normal_off", "nodes", "mesecons_pistons:piston_down_pusher_normal")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_sticky_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_up_sticky_off")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_up_sticky_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_down_sticky_off")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_down_sticky_on")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_pusher_sticky")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_up_pusher_sticky")
doc.add_entry_alias("nodes", "mesecons_pistons:piston_sticky_off", "nodes", "mesecons_pistons:piston_down_pusher_sticky")
