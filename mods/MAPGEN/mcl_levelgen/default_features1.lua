local mcl_levelgen = mcl_levelgen
local ipairs = ipairs
local pairs = pairs

local run_minp = mcl_levelgen.placement_run_minp
local run_maxp = mcl_levelgen.placement_run_maxp
local ull = mcl_levelgen.ull

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

local FACE_NORTH	= 0x01
local FACE_WEST		= 0x02
local FACE_SOUTH	= 0x04
local FACE_EAST		= 0x08
local FACE_UP		= 0x10
local FACE_DOWN		= 0x20

local face_opposites = {
	[FACE_NORTH] = FACE_SOUTH,
	[FACE_SOUTH] = FACE_NORTH,
	[FACE_WEST]  = FACE_EAST,
	[FACE_EAST]  = FACE_WEST,
	[FACE_UP]    = FACE_UP,
	[FACE_DOWN]  = FACE_DOWN,
}

local face_directions = {
	[FACE_NORTH] = { 0, 0, -1, },
	[FACE_SOUTH] = { 0, 0, 1, },
	[FACE_WEST]  = { -1, 0, 0, },
	[FACE_EAST]  = { 1, 0, 0, },
	[FACE_UP]    = { 0, 1, 0, },
	[FACE_DOWN]  = { 0, -1, 0, },
}

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
	for face, dir in pairs (face_directions) do
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
			for face1, dir1 in pairs (face_directions) do
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
