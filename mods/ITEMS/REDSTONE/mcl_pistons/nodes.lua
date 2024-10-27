local S = minetest.get_translator(minetest.get_current_modname())

local PISTON_MAXIMUM_PUSH = 12

-- Remove pusher of piston.
-- To be used when piston was destroyed or dug.
local function piston_remove_pusher(pos, oldnode)
	local pistonspec = minetest.registered_nodes[oldnode.name]._piston_spec

	local dir = -minetest.facedir_to_dir(oldnode.param2)
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
	local pistonspec = minetest.registered_nodes[basenodename]._piston_spec

	local dir = -minetest.facedir_to_dir(oldnode.param2)
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
	local pistonspec = minetest.registered_nodes[node.name]._piston_spec

	local dir = -minetest.facedir_to_dir(node.param2)
	local np = vector.add(pos, dir)
	local meta = minetest.get_meta(pos)
	local success = mcl_pistons.push(np, dir, PISTON_MAXIMUM_PUSH, meta:get_string("owner"), pos)
	if success then
		minetest.swap_node(pos, {param2 = node.param2, name = pistonspec.onname})
		minetest.set_node(np, {param2 = node.param2, name = pistonspec.pusher})
		local below = minetest.get_node({x=np.x,y=np.y-1,z=np.z})
		if below.name == "mcl_farming:soil" or below.name == "mcl_farming:soil_wet" then
			minetest.set_node({x=np.x,y=np.y-1,z=np.z}, {name = "mcl_core:dirt"})
		end
		minetest.sound_play("piston_extend", {
			pos = pos,
			max_hear_distance = 31,
			gain = 0.3,
		}, true)
	end
end

local function piston_off(pos, node)
	local pistonspec = minetest.registered_nodes[node.name]._piston_spec
	minetest.swap_node(pos, {param2 = node.param2, name = pistonspec.offname})
	piston_remove_pusher (pos, node)
	if not pistonspec.sticky then
		return
	end

	local dir = -minetest.facedir_to_dir(node.param2)
	local pullpos = vector.add(pos, vector.multiply(dir, 2))
	local meta = minetest.get_meta(pos)
	mcl_pistons.push(pullpos, vector.multiply(dir, -1), PISTON_MAXIMUM_PUSH, meta:get_string("owner"), pos)
end

local function piston_orientate(pos, placer)
	-- not placed by player
	if not placer then return end

	-- placer pitch in degrees
	local pitch = placer:get_look_vertical() * (180 / math.pi)

	local node = minetest.get_node(pos)
	local pistonspec = minetest.registered_nodes[node.name]._piston_spec
	if pitch > 55 then
		minetest.add_node(pos, {name=pistonspec.offname, param2 = minetest.dir_to_facedir(vector.new(0, -1, 0), true)})
	elseif pitch < -55 then
		minetest.add_node(pos, {name=pistonspec.offname, param2 = minetest.dir_to_facedir(vector.new(0, 1, 0), true)})
	end

	-- set owner meta after setting node
	local meta = minetest.get_meta(pos)
	local owner = placer and placer.get_player_name and placer:get_player_name()
	if owner and owner ~= "" then
		meta:set_string("owner", owner)
	else
		meta:set_string("owner", "$unknown")
	end
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
	offname = "mcl_pistons:piston_normal_off",
	onname = "mcl_pistons:piston_normal_on",
	pusher = "mcl_pistons:piston_pusher_normal",
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
			minetest.set_node(pos, {name="mcl_pistons:piston_up_normal_off"})
			return true
		end
	end,
}

local normaldef = table.merge(commdef, {
	description = S("Piston"),
	groups = table.merge(commdef.groups, {piston=1}),
	_piston_spec = pistonspec_normal,
})

local offdef = {
	_redstone = {
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
	groups = {not_in_creative_inventory = 1, unmovable_by_piston = 1},
	_redstone = {
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
	groups = {not_in_creative_inventory = 1, unmovable_by_piston = 1},
	_mcl_blast_resistance = 0.5,
	on_rotate = false,
	_redstone = {
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
minetest.register_node("mcl_pistons:piston_normal_off", table.merge(normaldef, offdef, {
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
minetest.register_node("mcl_pistons:piston_normal_on", table.merge(normaldef, ondef, {
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png"
	},
	groups = table.merge(normaldef.groups, {not_in_creative_inventory=1, unmovable_by_piston = 1}),
	drop = "mcl_pistons:piston_normal_off",
}))

-- pusher
minetest.register_node("mcl_pistons:piston_pusher_normal", table.merge(pusherdef, {
	tiles = {
		"mesecons_piston_pusher_top.png",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_left.png",
		"mesecons_piston_pusher_right.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front.png"
	},
	corresponding_piston = "mcl_pistons:piston_normal_on",
}))

-- Sticky ones

local pistonspec_sticky = {
	offname = "mcl_pistons:piston_sticky_off",
	onname = "mcl_pistons:piston_sticky_on",
	pusher = "mcl_pistons:piston_pusher_sticky",
	sticky = true,
}

local stickydef = table.merge(commdef, {
	description = S("Sticky Piston"),
	groups = table.merge(commdef.groups, {piston=2}),
	_piston_spec = pistonspec_sticky,
})

-- offstate
minetest.register_node("mcl_pistons:piston_sticky_off", table.merge(stickydef, offdef, {
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
minetest.register_node("mcl_pistons:piston_sticky_on", table.merge(stickydef, ondef, {
	tiles = {
		"mesecons_piston_bottom.png^[transformR180",
		"mesecons_piston_bottom.png",
		"mesecons_piston_bottom.png^[transformR90",
		"mesecons_piston_bottom.png^[transformR270",
		"mesecons_piston_back.png",
		"mesecons_piston_on_front.png"
	},
	groups = table.merge(stickydef.groups, {not_in_creative_inventory=1, unmovable_by_piston = 1}),
	drop = "mcl_pistons:piston_sticky_off",
}))

-- pusher
minetest.register_node("mcl_pistons:piston_pusher_sticky", table.merge(pusherdef, {
	tiles = {
		"mesecons_piston_pusher_top.png",
		"mesecons_piston_pusher_bottom.png",
		"mesecons_piston_pusher_left.png",
		"mesecons_piston_pusher_right.png",
		"mesecons_piston_pusher_back.png",
		"mesecons_piston_pusher_front_sticky.png"
	},
	corresponding_piston = "mcl_pistons:piston_sticky_on",
}))

-- Add entry aliases for the Help
doc.add_entry_alias("nodes", "mcl_pistons:piston_normal_off", "nodes", "mcl_pistons:piston_normal_on")
doc.add_entry_alias("nodes", "mcl_pistons:piston_normal_off", "nodes", "mcl_pistons:piston_pusher_normal")
doc.add_entry_alias("nodes", "mcl_pistons:piston_sticky_off", "nodes", "mcl_pistons:piston_sticky_on")
doc.add_entry_alias("nodes", "mcl_pistons:piston_sticky_off", "nodes", "mcl_pistons:piston_pusher_sticky")
