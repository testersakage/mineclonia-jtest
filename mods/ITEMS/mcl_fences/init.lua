-- mcl_fences/init.lua
local S = core.get_translator and core.get_translator("mcl_fences") or function(s) return s end
mcl_fences = {}

-- CONFIG: mask size in pixels (change if your mask PNGs are a different resolution)
local MASK_SIZE = 64

-- Nodebox pieces (standard fence geometry)
local p = { -0.125, -0.5, -0.125, 0.125, 0.5, 0.125 }
local x1 = { -0.5, 0.25, -0.0625, -0.125, 0.4375, 0.0625 }
local x12 = { -0.5, -0.125, -0.0625, -0.125, 0.0625, 0.0625 }
local x2 = { 0.125, 0.25, -0.0625, 0.5, 0.4375, 0.0625 }
local x22 = { 0.125, -0.125, -0.0625, 0.5, 0.0625, 0.0625 }
local z1 = { -0.0625, 0.25, -0.5, 0.0625, 0.4375, -0.125 }
local z12 = { -0.0625, -0.125, -0.5, 0.0625, 0.0625, -0.125 }
local z2 = { -0.0625, 0.25, 0.125, 0.0625, 0.4375, 0.5 }
local z22 = { -0.0625, -0.125, 0.125, 0.0625, 0.0625, 0.5 }

-- Collision boxes
local cp = { -0.125, -0.5, -0.125, 0.125, 1.01, 0.125 }
local cx1 = { -0.5, -0.5, -0.125, -0.125, 1.01, 0.125 }
local cx2 = { 0.125, -0.5, -0.125, 0.5, 1.01, 0.125 }
local cz1 = { -0.125, -0.5, -0.5, 0.125, 1.01, -0.125 }
local cz2 = { -0.125, -0.5, 0.125, 0.125, 1.01, 0.5 }

-- screwdriver support (optional)
local on_rotate
if core.get_modpath and core.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

-- Fence gate logic
local function update_gate(pos, node)
	if node.name:sub(-5) == "_open" then
		node.name = node.name:gsub("_open", "")
	else
		node.name = node.name.."_open"
	end
	core.set_node(pos, node)
end

local function play_sound(pos, node, state)
	local sounddefs = {}
	local defs = core.registered_nodes[node.name]
	if defs and defs._mcl_fences_sounds then
		sounddefs = defs._mcl_fences_sounds[state] or {}
	end
	local spec = sounddefs.spec or ("doors_fencegate_"..(state or "open"))
	local gain = sounddefs.gain or 0.3
	core.sound_play(spec, { gain = gain, max_hear_distance = 16, pos = pos }, true)
end

local function punch_gate(pos, node)
	local meta = core.get_meta(pos)
	local state = meta:get_int("state")
	if state == 1 then
		state = 0
		play_sound(pos, node, "close")
	else
		state = 1
		play_sound(pos, node, "open")
	end
	update_gate(pos, node)
	meta:set_int("state", state)
end

-- Wood types → plank textures
local PLANK_TEXTURES = {
	oak       = "default_wood.png",
	spruce    = "mcl_core_planks_spruce.png",
	birch     = "mcl_core_planks_birch.png",
	jungle    = "default_junglewood.png",
	acacia    = "default_acacia_wood.png",
	cherry    = "mcl_cherry_blossom_planks.png",
	dark_oak  = "mcl_core_planks_big_oak.png",
	mangrove  = "mcl_mangrove_planks.png",
	bamboo    = "mcl_bamboo_bamboo_plank.png",
	crimson   = "crimson_hyphae_wood.png",
	warped    = "warped_hyphae_wood.png",
	nether_brick    = "mcl_nether_nether_brick.png",
}

-- Utility: detect a wood key from a string (baseitem or description)
local function get_wood_type(str)
	if not str then return nil end
	local s = str:lower()
	for wood, _ in pairs(PLANK_TEXTURES) do
		if s:find(wood) then return wood end
	end
	return nil
end

-- Ensure definitions.tiles[1] is a plank texture where possible.
-- This will:
--  1) Prefer an explicit mapping from _mcl_fences_baseitem.
--  2) If tiles[1] already references a plank-like filename, leave it.
--  3) If tiles[1] looks like a fence texture, attempt to infer wood from the filename.
local function ensure_tiles_are_plank(definitions)
	-- If already a plank-like filename, keep it
	if definitions.tiles and definitions.tiles[1] and definitions.tiles[1]:lower():find("plank") then
		return
	end

	-- Try _mcl_fences_baseitem -> mapping
	local baseitem = definitions._mcl_fences_baseitem or definitions._mcl_fences_material or definitions._mcl_fence_material -- various possible keys
	local wood = get_wood_type(baseitem or definitions.description or "")
	if wood and PLANK_TEXTURES[wood] then
		definitions.tiles = { PLANK_TEXTURES[wood] }
		minetest.log("action", "[mcl_fences] inferred plank '"..PLANK_TEXTURES[wood].."' for '"..tostring(definitions.description or "").."' from baseitem.")
		return
	end

	-- Try to infer from existing tiles[1] if present
	if definitions.tiles and definitions.tiles[1] then
		local t = definitions.tiles[1]:lower()
		for wood_key, plank in pairs(PLANK_TEXTURES) do
			if t:find(wood_key) then
				definitions.tiles = { plank }
				minetest.log("action", "[mcl_fences] mapped tile '"..t.."' -> plank '"..plank.."' for '"..tostring(definitions.description or "").."'")
				return
			end
		end
	end

	-- Nothing we can do automatically. Caller should provide tiles or baseitem.
end

-- handle_textures: in-world node uses plank only; inventory/wield uses mask composed over a scaled plank
local function handle_textures(block, definitions)
	-- ensure we have a plank tile when possible
	ensure_tiles_are_plank(definitions)

	if not definitions.tiles or not definitions.tiles[1] then
		minetest.log("warning", "[mcl_fences] handle_textures: no tiles defined for '"..tostring(definitions.description or "unknown").."', skipping texture composition.")
		return
	end

	-- base plank texture (used for in-world)
	local base_texture = definitions.tiles[1]

	-- set node tiles to plain plank (no mask applied in-world)
	definitions.tiles = { base_texture }

	-- build inventory/wield composed texture: mask ^ (plank resized) ^ mask ^ makealpha
	local mask_filename = (block == "fence_gate") and "mcl_fences_fence_gate_mask.png" or "mcl_fences_fence_mask.png"
	local scaled_plank = base_texture .. "^[resize:"..tostring(MASK_SIZE).."x"..tostring(MASK_SIZE)
	local composed = mask_filename .. "^" .. scaled_plank .. "^" .. mask_filename .. "^[makealpha:255,126,126"

	-- Only set inventory/wield if caller hasn't set them explicitly
	if not definitions.inventory_image then
		definitions.inventory_image = composed
	end
	if not definitions.wield_image then
		definitions.wield_image = composed
	end
end

-- Node templates
local tpl_fences = {
	_doc_items_longdesc = S("Fences are structures which block the way. Fences will connect to each other and solid blocks. They cannot be jumped over with a simple jump."),
	paramtype = "light",
	is_ground_content = false,
	connect_sides = { "front", "back", "left", "right" },
	sunlight_propagates = true,
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = { p },
		connect_front = { z1, z12 },
		connect_back = { z2, z22 },
		connect_left = { x1, x12 },
		connect_right = { x2, x22 }
	},
	collision_box = {
		type = "connected",
		fixed = { cp },
		connect_front = { cz1 },
		connect_back = { cz2 },
		connect_left = { cx1 },
		connect_right = { cx2 }
	}
}

local tpl_fence_gates = {
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
			{ -0.5, -0.1875, -0.0625, -0.375, 0.5, 0.0625 },
			{ 0.375, -0.1875, -0.0625, 0.5, 0.5, 0.0625 },
			{ -0.125, -0.125, -0.0625, 0, 0.4375, 0.0625 },
			{ 0, -0.125, -0.0625, 0.125, 0.4375, 0.0625 },
			{ -0.5, 0.25, -0.0625, -0.125, 0.4375, 0.0625 },
			{ -0.5, -0.125, -0.0625, -0.125, 0.0625, 0.0625 },
			{ 0.125, 0.25, -0.0625, 0.5, 0.4375, 0.0625 },
			{ 0.125, -0.125, -0.0625, 0.5, 0.0625, 0.0625 }
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {{ -0.5, -0.1875, -0.125, 0.5, 1, 0.125 }}
	},
	selection_box = {
		type = "fixed",
		fixed = {{ -0.5, -0.1875, -0.0625, 0.5, 0.5, 0.0625 }}
	},
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_int("state", 0)
	end,
	_mcl_redstone = {
		connects_to = function(node, dir) return true end,
		update = function(pos)
			if mcl_redstone and mcl_redstone.get_power and mcl_redstone.get_power(pos) ~= 0 then
				local node = core.get_node(pos)
				punch_gate(pos, node)
			end
		end,
		init = function() end,
	},
	on_rotate = on_rotate,
	on_rightclick = function(pos, node, _) punch_gate(pos, node) end,
	_on_wind_charge_hit = function(pos)
		local node = core.get_node(pos)
		punch_gate(pos, node)
		return true
	end
}

local tpl_fence_gates_open = {
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.1875, -0.0625, -0.375, 0.5, 0.0625 },
			{ 0.375, -0.1875, -0.0625, 0.5, 0.5, 0.0625 },
			{ -0.5, 0.25, 0.0625, -0.375, 0.4375, 0.375 },
			{ -0.5, -0.125, 0.0625, -0.375, 0.0625, 0.375 },
			{ 0.375, 0.25, 0.0625, 0.5, 0.4375, 0.5 },
			{ 0.375, -0.125, 0.0625, 0.5, 0.0625, 0.5 },
			{ -0.5, -0.125, 0.375, -0.375, 0.4375, 0.5 },
			{ 0.375, 0.0625, 0.5, 0.5, 0.25, 0.375 }
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {{ -0.5, -0.1875, -0.0625, 0.5, 0.5, 0.0625 }}
	},
	on_rightclick = function(pos, node, _) punch_gate(pos, node) end,
	_mcl_redstone = tpl_fence_gates._mcl_redstone,
	on_rotate = on_rotate,
	_on_wind_charge_hit = tpl_fence_gates._on_wind_charge_hit
}

-- Register fence
function mcl_fences.register_fence_def(name, definitions)
	local fence_name = "mcl_fences:"..name
	definitions.groups = definitions.groups or {}
	definitions.groups.fence = 1
	definitions._pathfinding_class = "FENCE"
	definitions.groups.deco_block = 1
	definitions.connects_to = definitions.connects_to or { fence_name, "group:fence", "group:fence_gate", "group:solid" }

	-- Ensure tiles point to plank and setup inventory image
	if definitions.tiles and definitions.tiles[1] then
		handle_textures("fence", definitions)
	else
		-- attempt to infer tiles from baseitem/description
		ensure_tiles_are_plank(definitions)
		if definitions.tiles and definitions.tiles[1] then
			handle_textures("fence", definitions)
		else
			minetest.log("warning", "[mcl_fences] register_fence_def: '"..tostring(name).."' has no tiles and could not infer plank texture.")
		end
	end

	core.register_node(":"..fence_name, table.merge(tpl_fences, definitions))

	if definitions._mcl_fences_baseitem then
		local stick = definitions._mcl_fences_stickreplacer or "mcl_core:stick"
		local material = definitions._mcl_fences_baseitem
		local amount = definitions._mcl_fences_output_amount or 3
		core.register_craft({
			output = fence_name.." "..tostring(amount),
			recipe = {
				{ material, stick, material },
				{ material, stick, material }
			}
		})
	end

	return fence_name
end

-- Register fence gate
function mcl_fences.register_fence_gate_def(name, definitions)
	local fence_gate_name = "mcl_fences:"..name.."_gate"
	local fence_gate_name_open = fence_gate_name.."_open"

	definitions.groups = definitions.groups or {}
	definitions.groups.fence_gate = 1
	definitions._pathfinding_class = "FENCE"
	definitions.groups.deco_block = 1

	if definitions.tiles and definitions.tiles[1] then
		handle_textures("fence_gate", definitions)
	else
		ensure_tiles_are_plank(definitions)
		if definitions.tiles and definitions.tiles[1] then
			handle_textures("fence_gate", definitions)
		else
			minetest.log("warning", "[mcl_fences] register_fence_gate_def: '"..tostring(name).."' has no tiles and could not infer plank texture.")
		end
	end

	core.register_node(":"..fence_gate_name, table.merge(tpl_fence_gates, definitions))

	-- open variant
	local opendefinitions = table.copy(definitions)
	opendefinitions.description = nil
	opendefinitions.inventory_image = nil
	opendefinitions.wield_image = nil
	opendefinitions._mcl_burntime = nil
	opendefinitions.groups = table.copy(definitions.groups)
	opendefinitions._pathfinding_class = "OPEN"
	opendefinitions.groups.not_in_creative_inventory = 1
	opendefinitions.mesecon_ignore_opaque_dig = 1
	opendefinitions.mesecon_effector_on = 1

	core.register_node(":"..fence_gate_name_open, table.merge(tpl_fence_gates_open, { drop = fence_gate_name }, opendefinitions))

	if definitions._mcl_fences_baseitem then
		local stick = definitions._mcl_fences_stickreplacer or "mcl_core:stick"
		local material = definitions._mcl_fences_baseitem
		local amount = definitions._mcl_fences_output_amount or 1
		core.register_craft({
			output = fence_gate_name.." "..tostring(amount),
			recipe = {
				{ stick, material, stick },
				{ stick, material, stick }
			}
		})
	end

	if core.get_modpath("doc") then
		doc.add_entry_alias("nodes", fence_gate_name, "nodes", fence_gate_name_open)
	end

	return fence_gate_name, fence_gate_name_open
end

-- Combined registration helper
function mcl_fences.register_fence_and_fence_gate_def(name, commondefs, fencedefs, gatedefs)
	local fence = mcl_fences.register_fence_def(name, table.merge(commondefs, fencedefs))
	local gate, gate_open = mcl_fences.register_fence_gate_def(name, table.merge(commondefs, gatedefs))
	return fence, gate, gate_open
end

-- Legacy friendly wrappers
function mcl_fences.register_fence(id, fence_name, texture, groups, hardness, blast_resistance, connects_to, sounds, burntime, baseitem, stickreplacer)
	return mcl_fences.register_fence_def(id, {
		description = fence_name,
		tiles = { texture },
		groups = groups,
		_mcl_blast_resistance = blast_resistance,
		_mcl_hardness = hardness,
		connects_to = connects_to,
		sounds = sounds,
		_mcl_burntime = burntime,
		_mcl_fences_baseitem = baseitem,
		_mcl_fences_stickreplacer = stickreplacer
	})
end

function mcl_fences.register_fence_gate(id, fence_gate_name, texture, groups, hardness, blast_resistance, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close, burntime, baseitem, stickreplacer)
	return mcl_fences.register_fence_gate_def(id, {
		description = fence_gate_name,
		tiles = { texture },
		groups = groups,
		_mcl_blast_resistance = blast_resistance,
		_mcl_hardness = hardness,
		sounds = sounds,
		_mcl_burntime = burntime,
		_mcl_fences_sounds = {
			open = { spec = sound_open, gain = sound_gain_open },
			close = { spec = sound_close, gain = sound_gain_close }
		},
		_mcl_fences_baseitem = baseitem,
		_mcl_fences_stickreplacer = stickreplacer
	})
end

function mcl_fences.register_fence_and_fence_gate(id, fence_name, fence_gate_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close, texture_fence_gate)
	if texture_fence_gate == nil then texture_fence_gate = texture_fence end
	local fence_id = mcl_fences.register_fence(id, fence_name, texture_fence, groups, hardness, blast_resistance, connects_to, sounds)
	local gate_id, open_gate_id = mcl_fences.register_fence_gate(id, fence_gate_name, texture_fence_gate, groups, hardness, blast_resistance, sounds, sound_open, sound_close, sound_gain_open, sound_gain_close)
	return fence_id, gate_id, open_gate_id
end

-- End of init.lua
