local mcl_levelgen = mcl_levelgen
local ipairs = ipairs
-- local pairs = pairs

local run_minp = mcl_levelgen.placement_run_minp
local run_maxp = mcl_levelgen.placement_run_maxp
local ull = mcl_levelgen.ull

------------------------------------------------------------------------
-- Feature configuration in the main environment.
------------------------------------------------------------------------

local fossil_schematics = {
	"mcl_levelgen:fossil_skull_1",
	"mcl_levelgen:fossil_skull_2",
	"mcl_levelgen:fossil_skull_3",
	"mcl_levelgen:fossil_skull_4",
	"mcl_levelgen:fossil_spine_1",
	"mcl_levelgen:fossil_spine_2",
	"mcl_levelgen:fossil_spine_3",
	"mcl_levelgen:fossil_spine_4",
}

if not mcl_levelgen.is_levelgen_environment then
	local modpath = core.get_modpath ("mcl_structures")
	local fossil_schematic_files = {
		modpath .. "/schematics/mcl_structures_fossil_skull_1.mts",
		modpath .. "/schematics/mcl_structures_fossil_skull_2.mts",
		modpath .. "/schematics/mcl_structures_fossil_skull_3.mts",
		modpath .. "/schematics/mcl_structures_fossil_skull_4.mts",
		modpath .. "/schematics/mcl_structures_fossil_spine_1.mts",
		modpath .. "/schematics/mcl_structures_fossil_spine_2.mts",
		modpath .. "/schematics/mcl_structures_fossil_spine_3.mts",
		modpath .. "/schematics/mcl_structures_fossil_spine_4.mts",
	}
	for i = 1, #fossil_schematic_files do
		mcl_levelgen.register_portable_schematic (fossil_schematics[i],
							  fossil_schematic_files[i],
							  true)
	end

	return
end

------------------------------------------------------------------------
-- Fundamental features.  (Continued.)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Multiface Growth.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/feature/MultifaceGrowthFeature.html
------------------------------------------------------------------------

-- local multiface_growth_cfg = {
-- 	block = nil,
-- 	can_be_placed_on = nil,
-- 	can_place_on_ceiling = nil,
-- 	can_place_on_floor = nil,
-- 	can_place_on_wall = nil,
-- 	chance_of_spreading = 0.5,
-- 	search_range = 20,
-- }

-- local multiface_growth_block_cfg = {
-- 	-- is_self = function (cid, param2) .., end,
-- 	-- alter_placement = function (x, y, z, newfaces, rng, spreading) ... end,
-- }

local FACE_NORTH = mcl_levelgen.FACE_NORTH
local FACE_WEST = mcl_levelgen.FACE_WEST
local FACE_SOUTH = mcl_levelgen.FACE_SOUTH
local FACE_EAST = mcl_levelgen.FACE_EAST
local FACE_UP = mcl_levelgen.FACE_UP
local FACE_DOWN = mcl_levelgen.FACE_DOWN

local face_opposites = mcl_levelgen.face_opposites
local face_directions = mcl_levelgen.face_directions
local FACE_ORDINALS = mcl_levelgen.FACE_ORDINALS

local is_water_or_air = mcl_levelgen.is_water_or_air
local water_or_air_p = mcl_levelgen.water_or_air_p
local fisher_yates = mcl_levelgen.fisher_yates
local get_block = mcl_levelgen.get_block
local set_block = mcl_levelgen.set_block
local indexof = table.indexof

local multiface_growth_rng
	= mcl_levelgen.xoroshiro (ull (0, 0), ull (0, 0))
local band = bit.band
local bnot = bit.bnot
local bor = bit.bor
local lshift = bit.lshift

local function place_against_faces (x, y, z, cfg, rng, allowed_faces, faces)
	local can_be_placed_on = cfg.can_be_placed_on
	local alter_placement = cfg.block.alter_placement
	local chance_of_spreading = cfg.chance_of_spreading

	for _, face in ipairs (faces) do
		if band (allowed_faces, face) == face then
			local dir = face_directions[face]
			local x1, y1, z1
				= x + dir[1], y + dir[2], z + dir[3]
			local cid = get_block (x1, y1, z1)
			if indexof (can_be_placed_on, cid) ~= -1 then
				alter_placement (x, y, z, face, rng,
						 chance_of_spreading)
				return true
			end
		end
	end
	return false
end

local HORIZ_FACES = 0xf

local function multiface_growth_place (_, x, y, z, cfg, rng)
	multiface_growth_rng:reseed (rng:next_long ())
	if y < run_minp.y or y > run_maxp.y then
		return false
	else
		if not is_water_or_air (x, y, z) then
			return false
		else
			local allowed_faces = 0
			if cfg.can_place_on_wall then
				allowed_faces = bor (allowed_faces, HORIZ_FACES)
			end
			if cfg.can_place_on_ceiling then
				allowed_faces = bor (allowed_faces, FACE_UP)
			end
			if cfg.can_place_on_floor then
				allowed_faces = bor (allowed_faces, FACE_DOWN)
			end
			local rng = multiface_growth_rng
			local faces = {
				FACE_NORTH,
				FACE_SOUTH,
				FACE_EAST,
				FACE_WEST,
				FACE_UP,
				FACE_DOWN,
			}
			fisher_yates (faces, rng)

			local range = cfg.search_range
			local block_cfg = cfg.block

			local x, y, z = x, y, z
			for _, face in ipairs (faces) do
				if band (face, allowed_faces) ~= 0 then
					local dir = face_directions[face]
					local opposite = face_opposites[face]
					local allowed_faces = band (allowed_faces, bnot (opposite))

					for i = 0, range do
						x = x + dir[1]
						y = y + dir[2]
						z = z + dir[3]

						local cid, param2 = get_block (x, y, z)
						if not water_or_air_p (cid)
							and not block_cfg.is_self (cid, param2) then
							break
						end

						if place_against_faces (x, y, z, cfg, rng, allowed_faces,
									faces) then
							return true
						end
					end
				end
			end

			return false
		end
	end
end

mcl_levelgen.register_feature ("mcl_levelgen:multiface_growth", {
	place = multiface_growth_place,
})

------------------------------------------------------------------------
-- Glow Lichen interface.
------------------------------------------------------------------------

local glow_lichen_cids = {}
local glow_lichen_param2s = {}
local glow_lichen_to_flags = {}
local is_glow_lichen = {}

local function glow_lichen_flags_to_content (flags)
	if flags == FACE_NORTH then
		return "mcl_core:glow_lichen", 4
	elseif flags == FACE_SOUTH then
		return "mcl_core:glow_lichen", 5
	elseif flags == FACE_EAST then
		return "mcl_core:glow_lichen", 2
	elseif flags == FACE_WEST then
		return "mcl_core:glow_lichen", 3
	elseif flags == FACE_UP then
		return "mcl_core:glow_lichen", 0
	elseif flags == FACE_DOWN then
		return "mcl_core:glow_lichen", 1
	else
		local name = "mcl_core:glow_lichen_"

		if band (flags, FACE_NORTH) ~= 0 then
			name = name .. "n"
		end
		if band (flags, FACE_WEST) ~= 0 then
			name = name .. "w"
		end
		if band (flags, FACE_SOUTH) ~= 0 then
			name = name .. "s"
		end
		if band (flags, FACE_EAST) ~= 0 then
			name = name .. "e"
		end
		if band (flags, FACE_UP) ~= 0 then
			name = name .. "u"
		end
		if band (flags, FACE_DOWN) ~= 0 then
			name = name .. "d"
		end
		return name, 0
	end
end

for i = 1, 63 do
	local name, param2 = glow_lichen_flags_to_content (i)
	local cid = core.get_content_id (name)
	glow_lichen_cids[i] = cid
	glow_lichen_param2s[i] = param2
	local encoded = lshift (cid, 8) + param2
	glow_lichen_to_flags[encoded] = i
	is_glow_lichen[cid] = true
end

local function glow_lichen_is_self (cid, param2)
	return is_glow_lichen[cid] or false
end

local fix_lighting = mcl_levelgen.fix_lighting
local glow_lichen_spread

local function glow_lichen_alter_placement (x, y, z, face, rng,
					    chance_of_spreading)
	local cid, param2 = get_block (x, y, z)
	if not water_or_air_p (cid) and not is_glow_lichen[cid] then
		return false
	end
	local encoded = lshift (cid, 8) + param2
	local flags_here = glow_lichen_to_flags[encoded] or 0
	local new_flags = bor (face, flags_here)
	local cid = glow_lichen_cids[new_flags]
	local param2 = glow_lichen_param2s[new_flags]
	set_block (x, y, z, cid, param2)
	fix_lighting (x, y, z, x, y, z)
	if chance_of_spreading > 0.0
		and rng:next_float () < chance_of_spreading then
		glow_lichen_spread (x, y, z, new_flags, rng)
	end
	return true
end

local insert = table.insert
local face_sturdy_p = mcl_levelgen.face_sturdy_p

local function test_wallmounted_face (x, y, z, dirface)
	local axis, dir
	if dirface == FACE_NORTH then
		axis, dir = "z", 1
	elseif dirface == FACE_SOUTH then
		axis, dir = "z", -1
	elseif dirface == FACE_WEST then
		axis, dir = "x", 1
	elseif dirface == FACE_EAST then
		axis, dir = "x", -1
	elseif dirface == FACE_UP then
		axis, dir = "y", -1
	else
		axis, dir = "y", 1
	end

	return face_sturdy_p (x, y, z, axis, dir)
end

function glow_lichen_spread (x, y, z, faces, rng)
	-- Evaluate where this glow lichen block may spread.  A glow
	-- lichen block is permitted to spread from its current
	-- position to a contacting face or to the sides of any block
	-- to which it is attached except along the axis of its
	-- attachment.

	local spread_poses = {}
	for _, face in ipairs (FACE_ORDINALS) do
		local dir = face_directions[face]
		if band (faces, face) == 0 then
			-- Attempt to spread to an adjacent face.
			local x1, y1, z1 = x + dir[1], y + dir[2], z + dir[3]
			if test_wallmounted_face (x1, y1, z1, face) then
				insert (spread_poses, { x, y, z, face, })
			end
		else
			-- Or faces around this node.
			local xbehind, ybehind, zbehind
				= x + dir[1], y + dir[2], z + dir[3]
			for _, face1 in ipairs (FACE_ORDINALS) do
				local dir1 = face_directions[face1]
				-- But not behind it.
				if dir1 ~= dir then
					-- Spread around this node.
					if test_wallmounted_face (xbehind, ybehind, zbehind,
								  face1) then
						insert (spread_poses, {
							xbehind - dir1[1],
							ybehind - dir1[2],
							zbehind - dir1[3],
							face1,
						})
					end
				end

				-- Spread crosswise.
				local x1 = xbehind + dir1[1]
				local y1 = ybehind + dir1[2]
				local z1 = zbehind + dir1[3]
				if test_wallmounted_face (x1, y1, z1, face) then
					insert (spread_poses, {
						x1 - dir[1],
						x1 - dir[2],
						x1 - dir[3],
						face,
					})
				end
			end
		end
	end
	if #spread_poses == 0 then
		return
	end
	fisher_yates (spread_poses, rng)

	-- Iterate through each eligible position and attempt to add a
	-- lichen attachment at that position and in the direction
	-- specified.
	for _, attachment in ipairs (spread_poses) do
		local x, y, z, face = attachment[1],
			attachment[2],
			attachment[3],
			attachment[4]
		if glow_lichen_alter_placement (x, y, z, face, nil, 0.0) then
			return
		end
	end
end

mcl_levelgen.register_configured_feature ("mcl_levelgen:glow_lichen", {
	feature = "mcl_levelgen:multiface_growth",
	block = {
		is_self = glow_lichen_is_self,
		alter_placement = glow_lichen_alter_placement,
	},
	can_be_placed_on = mcl_levelgen.construct_cid_list ({
		"mcl_core:stone",
		"mcl_core:andesite",
		"mcl_core:diorite",
		"mcl_core:granite",
		"mcl_dripstone:dripstone_block",
		"mcl_amethyst:calcite",
		"mcl_deepslate:deepslate",
	}),
	can_place_on_ceiling = true,
	can_place_on_floor = false,
	can_place_on_wall = true,
	chance_of_spreading = 0.5,
	-- This option is actually not implemented by Minecraft.
	search_range = 0,
})

local uniform_height = mcl_levelgen.uniform_height
local overworld = mcl_levelgen.overworld_preset
local OVERWORLD_MIN = overworld.min_y
local OVERWORLD_TOP = overworld.min_y + overworld.height
local huge = math.huge

mcl_levelgen.register_placed_feature ("mcl_levelgen:glow_lichen", {
	configured_feature = "mcl_levelgen:glow_lichen",
	placement_modifiers = {
		mcl_levelgen.build_count (uniform_height (104, 157)),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN,
								 256)),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_surface_relative_threshold_filter ("motion_blocking_wg",
								      -huge, -13),
		mcl_levelgen.build_in_biome (),
	},
})

------------------------------------------------------------------------
-- Default schematic processors.
------------------------------------------------------------------------

function mcl_levelgen.block_rot_processor (integrity, rottable_cids)
	return function (x, y, z, rng, cid_existing, param2_existing,
			 cid, param2)
		assert (cid and param2)
		if (rottable_cids and indexof (rottable_cids, cid) == -1)
			or rng:next_float () <= integrity then
			return cid, param2
		end
		return nil, nil
	end
end

function mcl_levelgen.block_rule_processor (rules)
	local default = function (_, _, _)
		return true
	end
	local default_pos_predicate = function (_, _, _)
		return true
	end

	for _, rule in ipairs (rules) do
		rule.input_predicate = rule.input_predicate
			or default
		rule.loc_predicate = rule.loc_predicate
			or default
		rule.pos_predicate = rule.pos_predicate
			or default_pos_predicate
		assert (type (rule.cid) == "number")
		assert (type (rule.param2) == "number")
	end

	return function (x, y, z, rng, cid_existing,
			 param2_existing, cid, param2)
		for _, rule in ipairs (rules) do
			if rule.input_predicate (rng, cid, param2)
				and rule.loc_predicate (rng, cid_existing,
							param2_existing)
				and rule.pos_predicate (x, y, z, cid_existing,
							param2_existing,
							cid, param2) then
				return rule.cid, rule.param2
			end
		end
		assert (cid and param2)
		return cid, param2
	end
end

function mcl_levelgen.protected_blocks_processor (protected_cids)
	return function (x, y, z, rng, cid_existing, param2_existing,
			 cid, param2)
		if indexof (protected_cids) ~= -1 then
			return nil, nil
		end
		assert (cid and param2)
		return cid, param2
	end
end

------------------------------------------------------------------------
-- Fossils.
------------------------------------------------------------------------

-- local fossil_cfg = {
-- 	fossil_processors = nil,
-- 	fossil_schematics = nil,
-- 	max_empty_corners_allowed = nil,
-- 	overlay_processors = nil,
-- 	overlay_schematics = nil,
-- }

local mathmax = math.max
local mathmin = math.min
local ceil = math.ceil

local random_schematic_rotation = mcl_levelgen.random_schematic_rotation
local get_schematic_size = mcl_levelgen.get_schematic_size
local factory = overworld.factory ("mcl_levelgen:fossil_placement"):fork_positional ()
local fossil_rng = factory:create_reseedable ()

local function unpack6 (x)
	return x[1], x[2], x[3], x[4], x[5], x[6]
end

local function AABB_intersect (a, b)
	local x1a, y1a, z1a, x2a, y2a, z2a = unpack6 (a)
	local x1b, y1b, z1b, x2b, y2b, z2b = unpack6 (b)
	return {
		mathmax (x1a, x1b),
		mathmax (y1a, y1b),
		mathmax (z1a, z1b),
		mathmin (x2a, x2b),
		mathmin (y2a, y2b),
		mathmin (z2a, z2b),
	}
end

local ipos3 = mcl_levelgen.ipos3
local index_heightmap = mcl_levelgen.index_heightmap
local request_additional_context
	= mcl_levelgen.request_additional_context
local push_schematic_processors = mcl_levelgen.push_schematic_processors
local pop_schematic_processors = mcl_levelgen.pop_schematic_processors
local place_schematic = mcl_levelgen.place_schematic
local is_water_air_or_lava = mcl_levelgen.is_water_air_or_lava

local function empty_corner (x, y, z)
	if is_water_air_or_lava (x, y, z) then
		return 1
	else
		return 0
	end
end

local function num_empty_corners (aabb)
	local cnt = empty_corner (aabb[1], aabb[2], aabb[3])
	cnt = cnt + empty_corner (aabb[1], aabb[2], aabb[6])
	cnt = cnt + empty_corner (aabb[4], aabb[2], aabb[6])
	cnt = cnt + empty_corner (aabb[4], aabb[2], aabb[3])
	cnt = cnt + empty_corner (aabb[1], aabb[5], aabb[3])
	cnt = cnt + empty_corner (aabb[1], aabb[5], aabb[6])
	cnt = cnt + empty_corner (aabb[4], aabb[5], aabb[6])
	cnt = cnt + empty_corner (aabb[4], aabb[5], aabb[3])
	return cnt
end

local function fossil_place (_, x, y, z, cfg, rng)
	if y < run_minp.y or y > run_maxp.y then
		return false
	else
		local rng = fossil_rng
		rng:reseed_positional (x, y, z)
		local cnt_schematics = #cfg.fossil_schematics
		assert (cnt_schematics == #cfg.overlay_schematics)
		local idx = 1 + rng:next_within (cnt_schematics)
		local schematic = cfg.fossil_schematics[idx]
		local overlay_schematic = cfg.overlay_schematics[idx]

		-- Ascertain the bounding box of this schematic.
		local level_bounds = {
			run_minp.x - 16,
			run_minp.y - 32,
			run_minp.z - 16,
			run_maxp.x + 16,
			run_maxp.y + 32,
			run_maxp.z + 16,
		}
		local rotation = random_schematic_rotation (rng)
		local sx, sy, sz = get_schematic_size (schematic, rotation)
		local half_sx = ceil (sx / 2)
		local half_sz = ceil (sz / 2)
		local schematic_bounds = AABB_intersect (level_bounds, {
			x - half_sx,
			y,
			z - half_sz,
			x - half_sx + sx - 1,
			y + sy - 1,
			z - half_sz + sz - 1,
		})

		-- Prevent fossil placement above the initial surface
		-- of the level.
		local start_y = y
		for x, _, z in ipos3 (schematic_bounds[1], 0, schematic_bounds[3],
				      schematic_bounds[4], 0, schematic_bounds[6]) do
			local _, motion_blocking = index_heightmap (x, z, true)
			start_y = mathmin (start_y, motion_blocking)
		end
		local level_min = mcl_levelgen.placement_level_min
		local target_y
			= mathmax (start_y - 15 - rng:next_within (10), level_min + 10)

		-- If the schematic would be truncated, request more context.
		if target_y < level_bounds[2] then
			request_additional_context (0, level_bounds[2] - target_y)
			return false
		end

		local schematic_bounds_actual = AABB_intersect (level_bounds, {
			x - half_sx,
			target_y,
			z - half_sz,
			x - half_sx + sx - 1,
			target_y + sy - 1,
			z - half_sz + sz - 1,
		})
		if num_empty_corners (schematic_bounds_actual)
			> cfg.max_empty_corners_allowed then
			return false
		end

		local i = push_schematic_processors (cfg.fossil_processors)
		place_schematic (x - half_sx, target_y, z - half_sz,
				 schematic, rotation, true, {}, rng)
		pop_schematic_processors (i)
		i = push_schematic_processors (cfg.overlay_processors)
		place_schematic (x - half_sx, target_y, z - half_sz,
				 overlay_schematic, rotation, true,
				 {}, rng)
		pop_schematic_processors (i)
		return true
	end
end

mcl_levelgen.register_feature ("mcl_levelgen:fossil", {
	place = fossil_place,
})

local cannot_replace = mcl_levelgen.construct_cid_list ({
	"group:features_cannot_replace",
})

local cid_bone_block = core.get_content_id ("mcl_core:bone_block")
local cid_coal_ore = core.get_content_id ("mcl_core:stone_with_coal")
local cid_deepslate_diamond_ore
	= core.get_content_id ("mcl_deepslate:deepslate_with_diamond")

local function substitute_for_bone_block (cid_substitute)
	return mcl_levelgen.block_rule_processor ({
		{
			input_predicate = function (rng, cid, param2)
				return cid == cid_bone_block
			end,
			cid = cid_substitute,
			param2 = 0,
		},
	})
end

mcl_levelgen.register_configured_feature ("mcl_levelgen:fossil_coal", {
	feature = "mcl_levelgen:fossil",
	fossil_schematics = fossil_schematics,
	fossil_processors = {
		mcl_levelgen.block_rot_processor (0.9, nil),
		mcl_levelgen.protected_blocks_processor (cannot_replace),
	},
	max_empty_corners_allowed = 4,
	overlay_schematics = fossil_schematics,
	overlay_processors = {
		mcl_levelgen.block_rot_processor (0.1, nil),
		substitute_for_bone_block (cid_coal_ore),
		mcl_levelgen.protected_blocks_processor (cannot_replace),
	},
})

mcl_levelgen.register_configured_feature ("mcl_levelgen:fossil_diamonds", {
	feature = "mcl_levelgen:fossil",
	fossil_schematics = fossil_schematics,
	fossil_processors = {
		mcl_levelgen.block_rot_processor (0.9, nil),
		mcl_levelgen.protected_blocks_processor (cannot_replace),
	},
	max_empty_corners_allowed = 4,
	overlay_schematics = fossil_schematics,
	overlay_processors = {
		mcl_levelgen.block_rot_processor (0.1, nil),
		substitute_for_bone_block (cid_deepslate_diamond_ore),
		mcl_levelgen.protected_blocks_processor (cannot_replace),
	},
})

local function fossil_limit_to_heightmap (x, y, z, rng)
	local _, motion_blocking
		= index_heightmap (x, z, true)
	if y > motion_blocking + 20 then
		y = motion_blocking + 20
	end
	return { x, y, z, }
end

mcl_levelgen.register_placed_feature ("mcl_levelgen:fossil_upper", {
	configured_feature = "mcl_levelgen:fossil_coal",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (64),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (0, OVERWORLD_TOP)),
		fossil_limit_to_heightmap,
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:fossil_lower", {
	configured_feature = "mcl_levelgen:fossil_diamonds",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (64),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (OVERWORLD_MIN, -8)),
		fossil_limit_to_heightmap,
		mcl_levelgen.build_in_biome (),
	},
})

------------------------------------------------------------------------
-- Block Pile.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/feature/BlockPileFeature.html
------------------------------------------------------------------------

-- local block_pile_cfg = {
-- 	content = nil,
-- }

local pile_rng = mcl_levelgen.xoroshiro (ull (0, 0), ull (0, 0))
local ALWAYS_PLACE_THRESHOLD = 0.031
local is_air = mcl_levelgen.is_air
local cid_dirt_path = core.get_content_id ("mcl_core:grass_path")

local function add_pile_block (x, y, z, rng, content)
	if is_air (x, y, z) then
		local cid_below, _ = get_block (x, y - 1, z)
		if (cid_below == cid_dirt_path and rng:next_boolean ())
			or face_sturdy_p (x, y - 1, z, "y", 1) then
			local cid, param2 = content (x, y, z, rng)
			set_block (x, y, z, cid, param2)
			return true
		end
	end
	return false
end

local function block_pile_place (_, x, y, z, rng, cfg)
	local min_y = mcl_levelgen.placement_level_min
	if y < min_y + 5 then
		return false
	else
		pile_rng:reseed (rng:next_long ())
		if y < run_minp.y or y > run_minp.max then
			return false
		end

		local placed = false
		local rng = pile_rng
		local content = cfg.content
		local dx = 2 + rng:next_within (2)
		local dz = 2 + rng:next_within (2)
		for dx, dy, dz in ipos3 (-dx, 0, -dz, dx, 1, dz) do
			local d_sqr = dx * dx + dz * dz
			local r_sqr = rng:next_float () * 10.0
				+ rng:next_float () * 6.0
			if d_sqr <= r_sqr
				or rng:next_float () < ALWAYS_PLACE_THRESHOLD then
				if add_pile_block (x + dx, y + dy, z + dz, rng, content) then
					placed = true
				end
			end
		end
		if placed then
			fix_lighting (x - dx, y, z - dz, x + dx, y + 1, z + dz)
		end
		return true
	end
end

mcl_levelgen.register_feature ("mcl_levelgen:block_pile", {
	place = block_pile_place,
})

------------------------------------------------------------------------
-- Cactus.
------------------------------------------------------------------------

local biased_to_bottom_height = mcl_levelgen.biased_to_bottom_height
local is_position_hospitable = mcl_levelgen.is_position_hospitable

local cid_cactus = core.get_content_id ("mcl_core:cactus")

mcl_levelgen.register_configured_feature ("mcl_levelgen:cactus_column", {
	feature = "mcl_levelgen:block_column",
	layers = {
		{
			height = biased_to_bottom_height (1, 3, nil),
			content = function (x, y, z, _)
				return cid_cactus, 0
			end,
		},
	},
	prioritize_tip = false,
	allowed_placement = is_air,
	direction = 1,
})

local function build_hospitability_check (cid)
	return function (x, y, z, rng)
		if is_position_hospitable (cid, x, y, z) then
			return { x, y, z, }
		else
			return nil
		end
	end
end

local cid_sand = core.get_content_id ("mcl_core:sand")
local cid_red_sand = core.get_content_id ("mcl_core:redsand")

local function require_air_with_sand_below (x, y, z, rng)
	if is_air (x, y, z) then
		local cid, param2 = get_block (x, y - 1, z)
		if cid == cid_sand or cid == cid_red_sand then
			return { x, y, z, }
		end
	end
	return nil
end

mcl_levelgen.register_configured_feature ("mcl_levelgen:patch_cactus", {
	feature = "mcl_levelgen:random_patch",
	placed_feature = {
		configured_feature = "mcl_levelgen:cactus_column",
		placement_modifiers = {
			require_air_with_sand_below,
			build_hospitability_check (cid_cactus),
		},
	},
	tries = 10,
	xz_spread = 7,
	y_spread = 3,
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_cactus_decorated", {
	configured_feature = "mcl_levelgen:patch_cactus",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (13),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_levelgen:patch_cactus_desert", {
	configured_feature = "mcl_levelgen:patch_cactus",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (6),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_heightmap ("motion_blocking"),
		mcl_levelgen.build_in_biome (),
	},
})
