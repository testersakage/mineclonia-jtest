-- Checklist:
--
-- - [X] mcl_crimson:crimson_forest_vegetation
-- - [X] mcl_crimson:crimson_fungi
-- - [X] mcl_crimson:nether_sprouts
-- - [X] mcl_crimson:patch_crimson_roots
-- - [X] mcl_crimson:twisting_vines
-- - [X] mcl_crimson:warped_forest_vegetation
-- - [X] mcl_crimson:warped_fungi
-- - [X] mcl_crimson:weeping_vines
-- - [X] mcl_levelgen:blackstone_blobs
-- - [X] mcl_levelgen:ore_ancient_debris_large
-- - [X] mcl_levelgen:ore_blackstone
-- - [X] mcl_levelgen:ore_debris_small
-- - [X] mcl_levelgen:ore_gold_deltas
-- - [X] mcl_levelgen:ore_gold_nether
-- - [X] mcl_levelgen:ore_gravel_nether
-- - [X] mcl_levelgen:ore_magma
-- - [X] mcl_levelgen:ore_quartz_deltas
-- - [X] mcl_levelgen:ore_quartz_nether
-- - [X] mcl_levelgen:ore_soul_sand
-- - [X] mcl_levelgen:patch_fire
-- - [X] mcl_levelgen:patch_soul_fire
-- - [X] mcl_levelgen:spring_closed
-- - [X] mcl_levelgen:spring_closed_double
-- - [X] mcl_levelgen:spring_open
-- - [ ] mcl_mushrooms:brown_mushroom_nether
-- - [ ] mcl_mushrooms:red_mushroom_nether
-- - [ ] mcl_nether:basalt_blobs
-- - [ ] mcl_nether:basalt_pillar
-- - [ ] mcl_nether:delta
-- - [X] mcl_nether:glowstone
-- - [X] mcl_nether:glowstone_extra
-- - [ ] mcl_nether:large_basalt_columns
-- - [ ] mcl_nether:small_basalt_columns
-- - [ ] mcl_nether:spring_delta

------------------------------------------------------------------------
-- Nether level generation.
------------------------------------------------------------------------

local ipairs = ipairs

local mathmin = math.min
local mathmax = math.max

local get_block = mcl_levelgen.get_block
local set_block = mcl_levelgen.set_block
local fix_lighting = mcl_levelgen.fix_lighting
local is_air = mcl_levelgen.is_air

local ull = mcl_levelgen.ull
local nether_rng = mcl_levelgen.xoroshiro (ull (0, 0), ull (0, 0))

local uniform_height = mcl_levelgen.uniform_height
local biased_to_bottom_height = mcl_levelgen.biased_to_bottom_height

local run_minp = mcl_levelgen.placement_run_minp
local run_maxp = mcl_levelgen.placement_run_maxp

------------------------------------------------------------------------
-- Glowstone Blob.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/feature/GlowstoneBlobFeature.html
------------------------------------------------------------------------

local nether_preset = mcl_levelgen.get_dimension ("mcl_levelgen:nether").preset
local NETHER_MIN = nether_preset.min_y
local NETHER_TOP = NETHER_MIN + nether_preset.height - 1

local TEN = function (_) return 10 end

local cid_blackstone = core.get_content_id ("mcl_blackstone:blackstone")
local cid_basalt = core.get_content_id ("mcl_blackstone:basalt")
local cid_netherrack = core.get_content_id ("mcl_nether:netherrack")
local cid_glowstone = core.get_content_id ("mcl_nether:glowstone")

local just_one_neighboring_p = mcl_levelgen.just_one_neighboring_p

local function glowstone_p (cid, param2)
	return cid == cid_glowstone
end

local function one_neighboring_glowstone_p (x1, y1, z1)
	return just_one_neighboring_p (x1, y1, z1, glowstone_p)
end

local function glowstone_blob_place (_, x, y, z, cfg, rng)
	nether_rng:reseed (rng:next_long ())
	if y < run_minp.y or y > run_maxp.y or not is_air (x, y, z) then
		return false
	else
		local rng = nether_rng
		local cid, _ = get_block (x, y + 1, z)
		local min_x = x
		local min_y = y
		local min_z = z
		local max_x = x
		local max_y = y
		local max_z = z

		if cid == cid_blackstone
			or cid == cid_basalt
			or cid == cid_netherrack then
			set_block (x, y, z, cid_glowstone, 0)

			for i = 1, 1500 do
				local dx = rng:next_within (8) - rng:next_within (8)
				local dy = rng:next_within (8) - rng:next_within (8)
				local dz = rng:next_within (8) - rng:next_within (8)
				local x1, y1, z1 = x + dx, y + dy, z + dz

				if is_air (x1, y1, z1) then
					-- Place glowstone if there is
					-- exclusively one adjacent
					-- glowstone block.
					if one_neighboring_glowstone_p (x1, y1, z1) then
						set_block (x1, y1, z1, cid_glowstone, 0)
						min_x = mathmin (min_x, x1)
						min_y = mathmin (min_y, y1)
						min_z = mathmin (min_z, z1)
						max_x = mathmax (max_x, x1)
						max_y = mathmax (max_y, y1)
						max_z = mathmax (max_z, z1)
					end
				end
			end

			fix_lighting (min_x, min_y, min_z, max_x, max_y, max_z)
			return true
		end

		return false
	end
end

mcl_levelgen.register_feature ("mcl_nether:glowstone_blob", {
	place = glowstone_blob_place,
})

mcl_levelgen.register_configured_feature ("mcl_nether:glowstone_extra", {
	feature = "mcl_nether:glowstone_blob",
})

mcl_levelgen.register_placed_feature ("mcl_nether:glowstone", {
	configured_feature = "mcl_nether:glowstone_extra",
	placement_modifiers = {
		mcl_levelgen.build_count (TEN),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (NETHER_MIN,
								 NETHER_TOP)),
		mcl_levelgen.build_in_biome (),
	},
})

mcl_levelgen.register_placed_feature ("mcl_nether:glowstone_extra", {
	configured_feature = "mcl_nether:glowstone_extra",
	placement_modifiers = {
		mcl_levelgen.build_count (biased_to_bottom_height (0, 9, nil)),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (NETHER_MIN + 4,
								 NETHER_TOP - 4)),
		mcl_levelgen.build_in_biome (),
	},
})
