local bor = bit.bor
local lshift = bit.lshift

local decompose_AABBs = mcl_util.decompose_AABBs

--------------------------------------------------------------------------
-- Node property testing.
--------------------------------------------------------------------------

local function nodename_matcher(node_or_groupname)
	if string.sub(node_or_groupname, 1, 6) == "group:" then
		local groups = string.split(node_or_groupname:sub(("group:"):len() + 1), ",")
		return function(nodename)
			for _, groupname in pairs(groups) do
				if core.get_item_group(nodename, groupname) == 0 then
					return false
				end
			end
			return true
		end
	else
		return function(nodename)
			return nodename == node_or_groupname
		end
	end
end
-- Minetest allows shorthand box = {...} instead of {{...}}
local function get_boxes (box_or_boxes)
	return type (box_or_boxes[1]) == "number" and {box_or_boxes} or box_or_boxes
end

local has_boxes_prop = {collision_box = "walkable", selection_box = "pointable"}

-- Required for raycast box IDs to be accurate
local connect_sides_order = {
	"top", "bottom", "front",
	"left", "back", "right",
}

local connect_sides_directions = {
	top = vector.new (0, 1, 0),
	bottom = vector.new (0, -1, 0),
	front = vector.new (0, 0, 1),
	left = vector.new (-1, 0, 0),
	back = vector.new (0, 0, -1),
	right = vector.new (1, 0, 0),
}

local get_block

local function get_node_compat (pos)
	local cid, param2 = get_block (pos.x, pos.y, pos.z)
	return {
		name = cid and core.get_name_from_content_id (cid) or "ignore",
		param2 = param2 or 0,
	}
end

local function get_node_boxes (x, y, z)
	local pos = vector.new (x, y, z)
	local node = get_node_compat (pos)
	local node_def = core.registered_nodes[node.name]
	if not node_def or node_def[has_boxes_prop[type]] == false then
		return {}, true
	end
	local boxes = {{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}}
	local def_node_box = node_def.drawtype == "nodebox" and node_def.node_box
	local def_box = node_def[type] or def_node_box -- will evaluate to def_node_box for type = nil
	if not def_box then
		return boxes, true -- default to regular box
	end
	local box_type = def_box.type
	if box_type == "regular" then
		return boxes, true
	end
	local fixed = def_box.fixed
	boxes = get_boxes(fixed or {})
	local paramtype2 = node_def.paramtype2
	if box_type == "leveled" then
		boxes = table.copy(boxes)
		local level = (paramtype2 == "leveled" and node.param2 or node_def.leveled or 0) / 255 - 0.5
		for _, box in ipairs(boxes) do
			box[5] = level
		end
	elseif box_type == "wallmounted" then
		local dir = core.wallmounted_to_dir((paramtype2 == "colorwallmounted" and node.param2 % 8 or node.param2) or 0)
		local box
		-- The (undocumented!) node box defaults below are taken from `NodeBox::reset`
		if dir.y > 0 then
			box = def_box.wall_top or {-0.5, 0.5 - 1/16, -0.5, 0.5, 0.5, 0.5}
		elseif dir.y < 0 then
			box = def_box.wall_bottom or {-0.5, -0.5, -0.5, 0.5, -0.5 + 1/16, 0.5}
		else
			box = def_box.wall_side or {-0.5, -0.5, -0.5, -0.5 + 1/16, 0.5, 0.5}
			if dir.z > 0 then
				box = {box[3], box[2], -box[4], box[6], box[5], -box[1]}
			elseif dir.z < 0 then
				box = {-box[6], box[2], box[1], -box[3], box[5], box[4]}
			elseif dir.x > 0 then
				box = {-box[4], box[2], box[3], -box[1], box[5], box[6]}
			else
				box = {box[1], box[2], -box[6], box[4], box[5], -box[3]}
			end
		end
		return {assert(box, "incomplete wallmounted collisionbox definition of " .. node.name)}, true
	end
	if box_type == "connected" then
		boxes = table.copy(boxes)
		local connect_sides = connect_sides_directions -- (ab)use directions as a "set" of sides
		if node_def.connect_sides then -- build set of sides from given list
			connect_sides = {}
			for _, side in ipairs(node_def.connect_sides) do
				connect_sides[side] = true
			end
		end
		local function add_collisionbox(key)
			for _, box in ipairs(get_boxes(def_box[key] or {})) do
				table.insert(boxes, box)
			end
		end
		local matchers = {}
		for i, nodename_or_group in ipairs(node_def.connects_to or {}) do
			matchers[i] = nodename_matcher(nodename_or_group)
		end
		local function connects_to(nodename)
			for _, matcher in ipairs(matchers) do
				if matcher(nodename) then
					return true
				end
			end
		end
		local connected, connected_sides
		for _, side in ipairs(connect_sides_order) do
			if connect_sides[side] then
				local direction = connect_sides_directions[side]
				local neighbor = get_node_compat (vector.add (pos, direction))
				local connects = connects_to(neighbor.name)
				connected = connected or connects
				connected_sides = connected_sides or (side ~= "top" and side ~= "bottom")
				add_collisionbox((connects and "connect_" or "disconnected_") .. side)
			end
		end
		if not connected then
			add_collisionbox("disconnected")
		end
		if not connected_sides then
			add_collisionbox("disconnected_sides")
		end
		return boxes, false
	end
	if box_type == "fixed" and paramtype2 == "facedir" or paramtype2 == "colorfacedir" then
		local param2 = paramtype2 == "colorfacedir" and node.param2 % 32 or node.param2 or 0
		if param2 ~= 0 then
			boxes = table.copy(boxes)
			local axis = ({5, 6, 3, 4, 1, 2})[math.floor(param2 / 4) + 1]
			local other_axis_1, other_axis_2 = (axis % 3) + 1, ((axis + 1) % 3) + 1
			local rotation = (param2 % 4) / 2 * math.pi
			local flip = axis > 3
			if flip then axis = axis - 3; rotation = -rotation end
			local sin, cos = math.sin(rotation), math.cos(rotation)
			if axis == 2 then
				sin = -sin
			end
			for _, box in ipairs(boxes) do
				for off = 0, 3, 3 do
					local axis_1, axis_2 = other_axis_1 + off, other_axis_2 + off
					local value_1, value_2 = box[axis_1], box[axis_2]
					box[axis_1] = value_1 * cos - value_2 * sin
					box[axis_2] = value_1 * sin + value_2 * cos
				end
				if not flip then
					box[axis], box[axis + 3] = -box[axis + 3], -box[axis]
				end
				local function fix(coord)
					if box[coord] > box[coord + 3] then
						box[coord], box[coord + 3] = box[coord + 3], box[coord]
					end
				end
				fix(other_axis_1)
				fix(other_axis_2)
			end
		end
	end
	return boxes, true
end

-- Table of node shapes that do not vary by surroundings.
local static_node_shapes = {}

-- Table of node shapes derived from cid and param2.
local node_shape_cache = {}

local EMPTY_SHAPE = decompose_AABBs ({})
local FULL_BLOCK = decompose_AABBs ({{
	-0.5, -0.5, -0.5,
	0.5, 0.5, 0.5,
}})

local cid_ice
local cid_packed_ice
local cid_mud
local cid_mangrove_propagule
local cid_hanging_mangrove_propagule
local cid_soul_sand
local cid_honey_block
local cid_dead_bush
local cid_red_sand
local cid_sand
local cid_air
local cid_water_source
local cid_water_flowing
local is_cid_sapling = {}
local is_cid_dirt = {}
local is_cid_snow_layer, cid_snow = {}
local is_cid_walkable = {}
local is_cid_double_plant = {}
local is_cid_bush = {}
local is_cid_leaf = {}
local is_cid_terracotta = {}
local is_cid_soil_bamboo = {}
local is_cid_soil_propagule = {}
local is_cid_water_floating_node = {}
local is_cid_bamboo = {}
local is_cid_solid = {}
local double_plant_tops = {}
local paramtype2 = {}
local mathmin = math.min

mcl_levelgen.is_cid_dirt = is_cid_dirt

local function initialize_nodeprops ()
	cid_ice = core.get_content_id ("mcl_core:ice")
	cid_packed_ice = core.get_content_id ("mcl_core:packed_ice")
	cid_mud = core.get_content_id ("mcl_mud:mud")
	cid_mangrove_propagule = core.get_content_id ("mcl_mangrove:propagule")
	cid_hanging_mangrove_propagule
		= core.get_content_id ("mcl_mangrove:hanging_propagule_1")
	cid_soul_sand = core.get_content_id ("mcl_nether:soul_sand")
	cid_honey_block = core.get_content_id ("mcl_honey:honey_block")
	cid_dead_bush = core.get_content_id ("mcl_core:deadbush")
	cid_sand = core.get_content_id ("mcl_core:sand")
	cid_red_sand = core.get_content_id ("mcl_core:redsand")
	cid_air = core.CONTENT_AIR
	cid_water_source = core.get_content_id ("mcl_core:water_source")
	cid_water_flowing = core.get_content_id ("mcl_core:water_flowing")

	for i = 1, 8 do
		local cid
		if i == 1 then
			cid = core.get_content_id ("mcl_core:snow")
			cid_snow = cid
		else
			cid = core.get_content_id ("mcl_core:snow_" .. i)
		end
		is_cid_snow_layer[cid] = true
	end

	for name, def in pairs (core.registered_nodes) do
		local cid = core.get_content_id (name)
		if not def.walkable then
			is_cid_walkable[cid] = false
			static_node_shapes[cid] = EMPTY_SHAPE
		else
			is_cid_walkable[cid] = true
			local boxes = def.collision_box or def.node_box

			if not boxes or boxes.type == "regular" then
				static_node_shapes[cid] = FULL_BLOCK
			elseif boxes.type == "fixed" then
				-- ALways read from the default box.
				local fixed = boxes.fixed

				if type (fixed[1]) == "number" then
					fixed = {fixed}
				end
				local shape = decompose_AABBs (fixed)
				if not shape then
					error (string.format ("`%s''s collision box is too complex",
							      name))
				end
				static_node_shapes[cid] = shape
			end
		end

		if def.groups.sapling and def.groups.sapling >= 1 then
			is_cid_sapling[cid] = true
		end
		if def.groups.dirt and def.groups.dirt >= 1 then
			is_cid_dirt[cid] = true
		end
		if def.groups.double_plant and def.groups.double_plant >= 1 then
			is_cid_double_plant[cid] = true
			if def.groups.double_plant == 1 then
				local node = name .. "_top"
				local cid_top = minetest.get_content_id (node)
				double_plant_tops[cid] = cid_top
			end
		end
		if ((def.groups.plant and def.groups.plant >= 1)
			or (def.groups.double_plant and def.groups.double_plant >= 1)
			or (def.groups.flower and def.groups.flower >= 1))
			and not (def.groups.dripleaf and def.groups.dripleaf >= 1)
			and def.groups.attached_node ~= 4
			and not is_cid_sapling[cid] then
			-- TODO: wallmounted nodes!
			is_cid_bush[cid] = true
		end
		if (def.groups.leaves and def.groups.leaves >= 1) then
			is_cid_leaf[cid] = true
		end
		if def.groups.hardened_clay and def.groups.hardened_clay >= 1 then
			is_cid_terracotta[cid] = true
		end
		if def.groups.soil_propagule and def.groups.soil_propagule >= 1 then
			is_cid_soil_propagule[cid] = true
		end
		if def.groups.soil_bamboo and def.groups.soil_bamboo >= 1 then
			is_cid_soil_bamboo[cid] = true
		end
		if def.groups.floating_node == 3 then
			is_cid_water_floating_node[cid] = true
		end
		if def.groups.bamboo and def.groups.bamboo >= 1 then
			is_cid_bamboo[cid] = true
		end
		if def.groups.solid and def.groups.solid >= 1
			and (not def.groups.chest_entity
			     or def.groups.chest_entity == 0)
			and name ~= "mcl_chests:chest" then
			is_cid_solid[cid] = true
		end
		paramtype2[cid] = def.paramtype2
	end
end

if core.register_on_mods_loaded then
	core.register_on_mods_loaded (initialize_nodeprops)
else
	initialize_nodeprops ()
end

local function get_node_shape (x, y, z)
	local cid, param2 = get_block (x, y, z)
	if static_node_shapes[cid] then
		return static_node_shapes[cid], true
	elseif cid then
		local hash = bor (lshift (cid, 8), param2)
		if node_shape_cache[hash] then
			return node_shape_cache[hash], true
		end

		local boxes, reusable = get_node_boxes (x, y, z)
		local value = decompose_AABBs (boxes)
		assert (value, cid .. "'s collision box is too complex")
		if reusable then
			node_shape_cache[hash] = value
		end
		return value, reusable
	else
		return nil, false
	end
end

local rotate_facedir = {
	-- Table value = rotated facedir
	-- Columns: 0, 90, 180, 270 degrees rotation around vertical axis
	-- Rotation is anticlockwise as seen from above (+Y)

	0, 1, 2, 3,  -- Initial facedir 0 to 3
	1, 2, 3, 0,
	2, 3, 0, 1,
	3, 0, 1, 2,

	4, 13, 10, 19,  -- 4 to 7
	5, 14, 11, 16,
	6, 15, 8, 17,
	7, 12, 9, 18,

	8, 17, 6, 15,  -- 8 to 11
	9, 18, 7, 12,
	10, 19, 4, 13,
	11, 16, 5, 14,

	12, 9, 18, 7,  -- 12 to 15
	13, 10, 19, 4,
	14, 11, 16, 5,
	15, 8, 17, 6,

	16, 5, 14, 11,  -- 16 to 19
	17, 6, 15, 8,
	18, 7, 12, 9,
	19, 4, 13, 10,

	20, 23, 22, 21,  -- 20 to 23
	21, 20, 23, 22,
	22, 21, 20, 23,
	23, 22, 21, 20,
}

local ROTATE_0 = 0
local ROTATE_90 = 1
local ROTATE_180 = 2
local ROTATE_270 = 3

local wallmounted_to_rot = {
	ROTATE_0,
	ROTATE_180,
	ROTATE_90,
	ROTATE_270,
}

local rot_to_wallmounted = {
	[ROTATE_0] = 2,
	[ROTATE_90] = 4,
	[ROTATE_180] = 3,
	[ROTATE_270] = 5,
}

local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local DWM_COUNT = 8

local function namerot (rot)
	if rot == "0" then
		return ROTATE_0
	elseif rot == "90" then
		return ROTATE_90
	elseif rot == "180" then
		return ROTATE_180
	else
		return ROTATE_270
	end
end

-- See MapNode::rotateAlongYAxis in mapnode.cpp.
function mcl_levelgen.rotate_param2 (cid, param2, rot)
	local cpt2 = paramtype2[cid]
	local rot = namerot (rot)

	if cpt2 == "facedir" or cpt2 == "colorfacedir" then
		local facedir = band (param2, 31) % 24
		local index = facedir * 4 + rot + 1
		param2 = band (param2, bnot (31))
		param2 = bor (param2, rotate_facedir[index])
	elseif cpt2 == "4dir" or cpt2 == "color4dir" then
		local facedir = band (param2, 3)
		local index = facedir * 4 + rot + 1
		param2 = band (param2, bnot (3))
		param2 = bor (param2, rotate_facedir[index])
	elseif cpt2 == "wallmounted" or "colorwallmounted" then
		local wmountface = mathmin (band (param2, 0x07), DWM_COUNT - 1)
		if wmountface > 1 then
			local oldrot = wallmounted_to_rot[wmountface - 2 + 1]
			param2 = band (param2, bnot (7))
			local newrot = rot_to_wallmounted[band (oldrot - rot, 3)]
			param2 = bor (param2, newrot)
		end
	elseif cpt2 == "degrotate" then
		local angle = param2 -- in 1.5 deg increments
		angle = angle + 60 * rot;
		angle = angle % 240;
		param2 = angle
	elseif cpt2 == "colordegrotate" then
		local angle = band (param2, 0x1f) -- in 15 deg increments
		local color = band (param2, 0xe0)
		angle = angle + 6 * rot
		angle = angle % 24
		param2 = bor (angle, color)
	end
	return param2
end

--------------------------------------------------------------------------
-- Feature generation interface.
--------------------------------------------------------------------------

local supports_snow = {}

function mcl_levelgen.is_position_hospitable (cid, x, y, z)
	if not cid then
		return false
	end

	if is_cid_snow_layer[cid] then
		-- Test whether the surface of the node below is not
		-- any manner of ice and is sturdy, or mud, soul sand,
		-- or a honey block.
		local cid, param2 = get_block (x, y - 1, z)
		if cid == cid_ice
			or cid == cid_packed_ice
			or cid == cid_air
			or is_cid_snow_layer[cid] then
			return false
		elseif cid == cid_mud or cid == cid_soul_sand
			or cid == cid_honey_block then
			return true
		end

		local hash = bor (lshift (cid, 8), param2)
		if supports_snow[hash] ~= nil then
			return supports_snow[hash]
		end
		local shape, reusable = get_node_shape (x, y - 1, z)
		if not shape then
			return false
		end
		local top_face = shape:select_face ("y", 0.5)
		local sturdy = top_face:equal_p (FULL_BLOCK)
		if reusable then
			supports_snow[hash] = sturdy
		end
		return sturdy
	elseif cid == cid_dead_bush then
		local cid, _ = get_block (x, y - 1, z)
		return cid == cid_sand
			or cid == cid_red_sand
			or is_cid_terracotta[cid]
			or is_cid_dirt[cid]
	elseif is_cid_bamboo[cid] then
		local cid, _ = get_block (x, y - 1, z)
		return is_cid_soil_bamboo[cid]
	elseif cid == cid_mangrove_propagule
		or cid == cid_hanging_mangrove_propagule then
		local cid, _ = get_block (x, y - 1, z)
		return is_cid_soil_propagule[cid]
	elseif is_cid_water_floating_node[cid] then
		local cid, _ = get_block (x, y - 1, z)
		return cid == cid_water_source
	elseif is_cid_sapling[cid] or is_cid_bush[cid] then
		local cid, _ = get_block (x, y - 1, z)
		return is_cid_dirt[cid]
	end

	return true
end

local is_position_hospitable = mcl_levelgen.is_position_hospitable

function mcl_levelgen.can_place_snow (x, y, z)
	local cid, _ = get_block (x, y, z)
	if cid == cid_air or is_cid_snow_layer[cid] then
		return is_position_hospitable (cid_snow, x, y, z)
	end
	return false
end

function mcl_levelgen.is_position_walkable (x, y, z)
	local cid, _ = get_block (x, y, z)
	return is_cid_walkable[cid]
end

function mcl_levelgen.is_leaf_or_air (x, y, z)
	local cid, _ = get_block (x, y, z)
	return cid == cid_air or is_cid_leaf[cid]
end

function mcl_levelgen.is_water_or_air (x, y, z)
	local cid, _ = get_block (x, y, z)
	return cid == cid_air
		or cid == cid_water_source
		or cid == cid_water_flowing
end

function mcl_levelgen.is_air (x, y, z)
	local cid, _ = get_block (x, y, z)
	return cid == cid_air
end

function mcl_levelgen.is_air_with_dirt_below (x, y, z)
	local cid, _ = get_block (x, y, z)
	if cid == cid_air then
		local cid, _ = get_block (x, y - 1, z)
		return is_cid_dirt[cid]
	end
	return false
end

function mcl_levelgen.is_air_with_water_source_below (x, y, z)
	local cid, _ = get_block (x, y, z)
	if cid == cid_air then
		local cid, _ = get_block (x, y - 1, z)
		return cid == cid_water_source
	end
	return false
end

function mcl_levelgen.is_air_with_dirt_sand_or_terracotta_below (x, y, z)
	local cid, _ = get_block (x, y, z)
	if cid == cid_air then
		local cid, _ = get_block (x, y - 1, z)
		return is_cid_dirt[cid]
			or cid == cid_sand
			or cid == cid_red_sand
			or is_cid_terracotta[cid]
	end
	return false
end

function mcl_levelgen.adjoins_air (x, y, z)
	local cid, _ = get_block (x - 1, y, z)
	if cid == cid_air then
		return true
	end
	local cid, _ = get_block (x, y, z - 1)
	if cid == cid_air then
		return true
	end
	local cid, _ = get_block (x + 1, y, z)
	if cid == cid_air then
		return true
	end
	local cid, _ = get_block (x, y, z + 1)
	if cid == cid_air then
		return true
	end
	local cid, _ = get_block (x, y - 1, z)
	if cid == cid_air then
		return true
	end
	local cid, _ = get_block (x, y + 1, z)
	if cid == cid_air then
		return true
	end
	return false
end

function mcl_levelgen.count_adjoining_solids (x, y, z)
	local cnt, cnt_x, cnt_z = 0, 0, 0
	local cid, _ = get_block (x - 1, y, z)
	if is_cid_solid[cid] then
		cnt = cnt + 1
		cnt_x = cnt_x + 1
	end
	local cid, _ = get_block (x, y, z - 1)
	if is_cid_solid[cid] then
		cnt = cnt + 1
		cnt_z = cnt_z + 1
	end
	local cid, _ = get_block (x + 1, y, z)
	if is_cid_solid[cid] then
		cnt = cnt + 1
		cnt_x = cnt_x + 1
	end
	local cid, _ = get_block (x, y, z + 1)
	if is_cid_solid[cid] then
		cnt = cnt + 1
		cnt_z = cnt_z + 1
	end
	return cnt, cnt_x, cnt_z
end

function mcl_levelgen.is_solid (x, y, z)
	local cid, _ = get_block (x, y, z)
	return is_cid_solid[cid]
end

function mcl_levelgen.solid_p (cid)
	return is_cid_solid[cid]
end

function mcl_levelgen.double_plant_p (cid)
	return is_cid_double_plant[cid]
end

function mcl_levelgen.place_double_plant (cid, x, y, z, param2, set_block)
	local top_cid = double_plant_tops[cid]
	assert (top_cid, "Double plant (cid = " .. cid .. ") has no matching top node")
	set_block (x, y, z, cid, param2)
	set_block (x, y + 1, z, top_cid, param2)
end

local sturdy = {}

function mcl_levelgen.face_sturdy_p (x, y, z, axis, dir)
	if axis == "z" then
		dir = -dir
	end
	local shape, reusable = get_node_shape (x, y, z)
	if shape and reusable then
		if sturdy[shape] ~= nil then
			return sturdy[shape]
		end
		local face = shape:select_face (axis, dir * 0.5)
		sturdy[shape] = face:equal_p (FULL_BLOCK)
		return sturdy[shape]
	elseif shape then
		local face = shape:select_face (axis, dir * 0.5)
		return face:equal_p (FULL_BLOCK)
	end
	return false
end

local face_sturdy_p = mcl_levelgen.face_sturdy_p
function mcl_levelgen.is_bottom_face_sturdy (x, y, z)
	return face_sturdy_p (x, y, z, "y", -1.0)
end

--------------------------------------------------------------------------
-- Utility functions.
--------------------------------------------------------------------------

function mcl_levelgen.construct_cid_list (names)
	local cids = {}
	for _, target in ipairs (names) do
		if target:sub (1, 6) == "group:" then
			local group = target:sub (7)
			for name, tbl in pairs (core.registered_nodes) do
				if tbl.groups[group] and tbl.groups[group] > 0 then
					local id = core.get_content_id (name)
					table.insert (cids, id)
				end
			end
		else
			table.insert (cids, core.get_content_id (target))
		end
	end
	return cids
end

function mcl_levelgen.facedir_to_wallmounted (axis, dir)
	if axis == "y" then
		return dir >= 0 and 0 or -1
	elseif axis == "x" then
		return dir >= 0 and 2 or 3
	elseif axis == "z" then
		return dir >= 0 and 5 or 4
	else
		assert (false)
	end
end

--------------------------------------------------------------------------
-- Late initialization.
--------------------------------------------------------------------------

function mcl_levelgen.initialize_nodeprops_in_async_env ()
	get_block = mcl_levelgen.get_block
end
