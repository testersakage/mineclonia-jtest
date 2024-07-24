local S = minetest.get_translator(minetest.get_current_modname())

local on_rotate
if minetest.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

-- Node box
local p = {-2/16, -0.5, -2/16, 2/16, 0.5, 2/16}
local x1 = {-0.5, 4/16, -1/16, -2/16, 7/16, 1/16}   --oben(quer) -x
local x12 = {-0.5, -2/16, -1/16, -2/16, 1/16, 1/16} --unten(quer) -x
local x2 = {2/16, 4/16, -1/16, 0.5, 7/16, 1/16}   --oben(quer) x
local x22 = {2/16, -2/16, -1/16, 0.5, 1/16, 1/16} --unten(quer) x
local z1 = {-1/16, 4/16, -0.5, 1/16, 7/16, -2/16}   --oben(quer) -z
local z12 = {-1/16, -2/16, -0.5, 1/16, 1/16, -2/16} --unten(quer) -z
local z2 = {-1/16, 4/16, 2/16, 1/16, 7/16, 0.5}   --oben(quer) z
local z22 = {-1/16, -2/16, 2/16, 1/16, 1/16, 0.5} --unten(quer) z

-- Collision box
local cp = {-2/16, -0.5, -2/16, 2/16, 1.01, 2/16}
local cx1 = {-0.5, -0.5, -2/16, -2/16, 1.01, 2/16} --unten(quer) -x
local cx2 = {2/16, -0.5, -2/16, 0.5, 1.01, 2/16} --unten(quer) x
local cz1 = {-2/16, -0.5, -0.5, 2/16, 1.01, -2/16} --unten(quer) -z
local cz2 = {-2/16, -0.5, 2/16, 2/16, 1.01, 0.5} --unten(quer) z

mcl_fences = {}

local function update_gate(pos, node)
	if node.name:sub(-5) == "_open" then
		node.name = node.name:gsub("_open", "")
	else
		node.name = node.name.."_open"
	end
	minetest.set_node(pos, node)
end

local function play_sound(pos, definitions)
	local spec = definitions.spec
	local gain = definitions.gain
	minetest.sound_play(spec, { gain = gain, max_hear_distance = 16, pos = pos }, true)
end

local function punch_gate(pos, node)
	local meta = minetest.get_meta(pos)
	local state = meta:get_int("state")
	-- Needs repair
	--local defs = minetest.registered_nodes[node.name]
	local sounddefs = {}

	if state == 1 then
		state = 0
		sounddefs.spec = "doors_fencegate_close"
		sounddefs.gain = 0.3
		play_sound(pos, sounddefs)
	else
		state = 1
		sounddefs.spec = "doors_fencegate_open"
		sounddefs.gain = 0.3
		play_sound(pos, sounddefs)
	end
	update_gate(pos, node)
	meta:set_int("state", state)
end

local tpl_fence = {
	_doc_items_longdesc = S("Fences are structures which block the way. Fences will connect to each other and solid blocks. They cannot be jumped over with a simple jump."),
	paramtype = "light",
	is_ground_content = false,
	connect_sides = { "front", "back", "left", "right" },
	sunlight_propagates = true,
	drawtype = "nodebox"
}

local tpl_fence_gate_open = {
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -3/16, -1/16, -6/16, 0.5, 1/16},   --links abschluss
			{6/16, -3/16, -1/16, 0.5, 0.5, 1/16},   --rechts abschluss
			{-0.5, 4/16, 1/16, -6/16, 7/16, 6/16},   --oben-links(quer) x
			{-0.5, -2/16, 1/16, -6/16, 1/16, 6/16}, --unten-links(quer) x
			{6/16, 4/16, 1/16, 0.5, 7/16, 0.5},   --oben-rechts(quer) x
			{6/16, -2/16, 1/16, 0.5, 1/16, 0.5}, --unten-rechts(quer) x
			{-0.5, -2/16, 6/16, -6/16, 7/16, 0.5},  --mitte links
			{6/16, 1/16, 0.5, 0.5, 4/16, 6/16},  --mitte rechts
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
				{-0.5, -3/16, -1/16, 0.5, 0.5, 1/16},   --gate
			}
	},
	on_rightclick = function(pos, node, clicker)
		punch_gate(pos, node)
	end,
	mesecons = {effector = {
		action_off = (function(pos, node)
			punch_gate(pos, node)
		end),
	}},
	on_rotate = on_rotate,
	_on_wind_charge_hit = function(pos)
		local node = minetest.get_node(pos)
			punch_gate(pos, node)
		return true
	end
}

local tpl_fence_gate_close = {
	_tt_help = S("Openable by players and redstone power"),
	_doc_items_longdesc = S("Fence gates can be opened or closed and can't be jumped over. Fences will connect nicely to fence gates."),
	_doc_items_usagehelp = S("Right-click the fence gate to open or close it."),
	paramtype = "light",
	is_ground_content = false,
	paramtype2 = "facedir",
	sunlight_propagates = true,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -3/16, -1/16, -6/16, 0.5, 1/16},   --links abschluss
			{6/16, -3/16, -1/16, 0.5, 0.5, 1/16},   --rechts abschluss
			{-2/16, -2/16, -1/16, 0, 7/16, 1/16},  --mitte links
			{0, -2/16, -1/16, 2/16, 7/16, 1/16},  --mitte rechts
			{-0.5, 4/16, -1/16, -2/16, 7/16, 1/16},   --oben(quer) -z
			{-0.5, -2/16, -1/16, -2/16, 1/16, 1/16}, --unten(quer) -z
			{2/16, 4/16, -1/16, 0.5, 7/16, 1/16},   --oben(quer) z
			{2/16, -2/16, -1/16, 0.5, 1/16, 1/16}, --unten(quer) z
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -3/16, -2/16, 0.5, 1, 2/16},   --gate
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -3/16, -1/16, 0.5, 0.5, 1/16},   --gate
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("state", 0)
	end,
	mesecons = {effector = {
		action_on = (function(pos, node)
			punch_gate(pos, node)
		end),
	}},
	on_rotate = on_rotate,
	on_rightclick = function(pos, node, clicker)
		punch_gate(pos, node)
	end,
	_on_wind_charge_hit = function(pos)
		local node = minetest.get_node(pos)
			punch_gate(pos, node)
		return true
	end
}

function mcl_fences.register_fence(name, definitions)
	definitions.groups.deco_block = 1
	definitions.groups.fence = 1

	if definitions.connects_to == nil then
		definitions.connects_to = {}
	else
		definitions.connects_to = table.copy(definitions.connects_to)
	end

	if definitions.tiles and definitions.tiles[1] then
		if not definitions.inventory_image then
			definitions.inventory_image = "mcl_fences_fence_mask.png^"..definitions.tiles[1].."^mcl_fences_fence_mask.png^[makealpha:255,126,126"
		end

		if not definitions.wield_image then
			definitions.wield_image = "mcl_fences_fence_mask.png^"..definitions.tiles[1].."^mcl_fences_fence_mask.png^[makealpha:255,126,126"
		end
	end

	local fence_id = "mcl_fences:"..name
	table.insert(definitions.connects_to, "group:solid")
	table.insert(definitions.connects_to, "group:fence_gate")
	table.insert(definitions.connects_to, fence_id)

	minetest.register_node(":"..fence_id, table.merge(tpl_fence, {
		node_box = {
			type = "connected",
			fixed = {p},
			connect_front = {z1,z12},
			connect_back = {z2,z22,},
			connect_left = {x1,x12},
			connect_right = {x2,x22},
		},
		collision_box = {
			type = "connected",
			fixed = {cp},
			connect_front = {cz1},
			connect_back = {cz2,},
			connect_left = {cx1},
			connect_right = {cx2},
		},
	}, definitions))

	if definitions._mcl_fences_baseitem then
		local stick = "mcl_core:stick"
		local material = definitions._mcl_fences_baseitem
		local amount = definitions._mcl_fences_output_amount or 3

		if definitions._mcl_fences_stickreplacer then
			stick = definitions._mcl_fences_stickreplacer
		end

		minetest.register_craft({
			output = fence_id.." "..tostring(amount),
			recipe = {
				{ material, stick, material },
				{ material, stick, material }
			}
		})
	end

	return fence_id
end

function mcl_fences.register_fence_gate(name, definitions)
	definitions.groups.fence_gate = 1
	definitions.groups.deco_block = 1

	local gate_id = "mcl_fences:"..name.."_gate"
	local open_gate_id = gate_id .. "_open"

	local opendefs = table.copy(definitions)
	local cgroups = table.copy(opendefs.groups)

	opendefs.description = nil
	opendefs.inventory_image = nil
	opendefs.wield_image = nil
	opendefs._mcl_burntime = nil

	cgroups.mesecon_ignore_opaque_dig = 1
	cgroups.mesecon_effector_on = 1
	cgroups.fence_gate = 1
	cgroups.not_in_creative_inventory = 1

	minetest.register_node(":"..open_gate_id, table.merge(tpl_fence_gate_open, {
		groups = cgroups,
		drop = gate_id,
	}, opendefs))

	local cgroups_closed = table.copy(definitions.groups)
	cgroups_closed.mesecon_effector_on = nil
	cgroups_closed.mesecon_effector_off = nil

	if definitions.tiles and definitions.tiles[1] then
		if not definitions.inventory_image then
			definitions.inventory_image = "mcl_fences_fence_gate_mask.png^"..definitions.tiles[1]..
			"^mcl_fences_fence_gate_mask.png^[makealpha:255,126,126"

		end
		if not definitions.wield_image then
			definitions.wield_image = "mcl_fences_fence_gate_mask.png^"..definitions.tiles[1]..
			"^mcl_fences_fence_gate_mask.png^[makealpha:255,126,126"
		end
	end

	minetest.register_node(":"..gate_id, table.merge(tpl_fence_gate_close, {
		groups = cgroups_closed,
	}, definitions))

	if definitions._mcl_fences_baseitem then
		local stick = "mcl_core:stick"
		local material = definitions._mcl_fences_baseitem
		local amount = definitions._mcl_fences_output_amount or 1

		if definitions._mcl_fences_stickreplacer then
			stick = definitions._mcl_fences_stickreplacer
		end

		minetest.register_craft({
			output = gate_id.." "..tostring(amount),
			recipe = {
				{ stick, material, stick },
				{ stick, material, stick }
			}
		})
	end

	if minetest.get_modpath("doc") then
		doc.add_entry_alias("nodes", gate_id, "nodes", open_gate_id)
	end

	return gate_id, open_gate_id
end

function mcl_fences.register_fence_and_fence_gate(id, fence_name, fence_gate_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close, texture_fence_gate)
	if texture_fence_gate == nil then
		texture_fence_gate = texture_fence
	end
	local fence_id = mcl_fences.register_fence(id, fence_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds)
	local gate_id, open_gate_id = mcl_fences.register_fence_gate(id, fence_gate_name, texture_fence_gate, groups, hardness, blast_resistance, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close)
	return fence_id, gate_id, open_gate_id
end
