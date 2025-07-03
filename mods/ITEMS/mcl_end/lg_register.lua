local ipairs = ipairs
local mcl_levelgen = mcl_levelgen
local W = mcl_levelgen.build_weighted_list

------------------------------------------------------------------------
-- End Spike.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/feature/EndSpikeFeature.html
------------------------------------------------------------------------

-- local end_spike_cfg = {
-- 	crystal_invulnerable = nil,
-- 	spikes = {
-- 		{
-- 			center_x = ...,
-- 			center_z = ...,
-- 			radius = ...,
-- 			height = ...,
-- 			guarded = ...,

-- 		},
-- 		...
-- 	},
-- 	crystal_beam_target = ...,
-- }

local insert = table.insert
local band = bit.band

local floor = math.floor
local mathcos = math.cos
local mathsin = math.sin
local mathmax = math.max
local mathmin = math.min
local pi = math.pi

local ull = mcl_levelgen.ull
local extull = mcl_levelgen.extull
local spike_rng = mcl_levelgen.jvm_random (ull (0, 0))
local fisher_yates = mcl_levelgen.fisher_yates
local ipos3 = mcl_levelgen.ipos3
local set_block = mcl_levelgen.set_block
local notify_generated = mcl_levelgen.notify_generated
local uniform_height = mcl_levelgen.uniform_height

local function get_spikes (preset)
	if preset.end_spikes then
		return preset.end_spikes
	end

	spike_rng:reseed (preset.seed)
	local value = band (spike_rng:next_long ()[1], 0xffff)
	local sizes = {
		0,
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
	}
	spike_rng:reseed (extull (value))
	fisher_yates (sizes, spike_rng)

	local spikes = {}
	for i = 0, 9 do
		-- https://minecraft.wiki/w/End_spike#Construction
		local angle = 2.0 * (-pi + (pi / 10) * i)
		local x = floor (42.0 * mathcos (angle))
		local z = floor (42.0 * mathsin (angle))
		local size = sizes[i + 1]
		local radius = floor (2 + size / 3)
		local height = 76 + size * 3
		local guarded = size == 1 or size == 2

		insert (spikes, {
			center_x = x,
			center_z = z,
			radius = radius,
			height = height,
			guarded = guarded,
		})
	end
	preset.end_spikes = spikes
	return spikes
end

local function mapblock_distance (x1, z1, x2, z2)
	local bx1 = band (x1, -16)
	local bz1 = band (z1, -16)
	local dx = mathmax (0, x2 - (bx1 + 15), bx1 - x2)
	local dz = mathmax (0, z2 - (bz1 + 15), bz1 - z2)
	return dx * dx + dz * dz
end

local cid_obsidian = core.get_content_id ("mcl_core:obsidian")
local cid_iron_bars = core.get_content_id ("mcl_panes:bar")
local cid_eternal_fire = core.get_content_id ("mcl_fire:eternal_fire")
local cid_bedrock = core.get_content_id ("mcl_core:bedrock")

local cid_air = core.CONTENT_AIR

local function end_spike_place_1 (preset, spike, r, run_min_y, run_max_y)
	local cx, cz = spike.center_x, spike.center_z
	local height = spike.height
	for x, y, z in ipos3 (cx - r,
			      mathmax (preset.min_y, run_min_y),
			      cz - r,
			      cx + r,
			      mathmin (height + 10, run_max_y),
			      cz + r) do
		local d_sqr
			= ((x - cx) * (x - cx) + (z - cz) * (z - cz))
		if d_sqr <= r * r + 1 and y < height then
			set_block (x, y, z, cid_obsidian, 0)
		elseif y > 65 then
			set_block (x, y, z, cid_air, 0)
		end
	end

	-- Cage.

	if spike.guarded then
		for dx, y, dz in ipos3 (-2, mathmax (height, run_min_y), -2,
					2, mathmin (height + 3, run_max_y), 2) do
			local at_corner = dx == -2 or dx == 2
				or dz == -2 or dz == 2
				or y == height + 3
			if at_corner then
				set_block (cx + dx, y, cz + dz, cid_iron_bars, 0)
			end
		end
	end

	-- Fire & bedrock.
	set_block (cx, height + 1, cz, cid_eternal_fire, 0)
	set_block (cx, height, cz, cid_bedrock, 0)

	-- End Crystal.
	local minp = mcl_levelgen.placement_run_minp
	local maxp = mcl_levelgen.placement_run_maxp
	if height >= run_min_y
		and height <= run_max_y
		and cx >= minp.x and cx <= maxp.x
		and cz >= minp.z and cz <= maxp.z then
		notify_generated ("mcl_end:spawn_end_crystal", {
			cx, height, cz,
		})
	end
end

local function end_spike_place (_, x, y, z, cfg, rng)
	local preset = mcl_levelgen.placement_level
	local spikes = #cfg.spikes > 0 and cfg.spikes
		or get_spikes (preset)
	local run_min_y = mcl_levelgen.placement_run_minp.y
	local run_max_y = mcl_levelgen.placement_run_maxp.y

	for _, spike in ipairs (spikes) do
		local cx, cz = spike.center_x, spike.center_z
		local r = spike.radius
		if mapblock_distance (x, z, cx, cz) < r * r then
			end_spike_place_1 (preset, spike, r, run_min_y,
					   run_max_y)
		end
	end

	return true
end

mcl_levelgen.register_feature ("mcl_end:end_spike", {
	place = end_spike_place,
})

mcl_levelgen.register_configured_feature ("mcl_end:end_spike", {
	feature = "mcl_end:end_spike",
	crystal_invulnerable = false,
	spikes = {},
})

mcl_levelgen.register_placed_feature ("mcl_end:end_spike", {
	configured_feature = "mcl_end:end_spike",
	placement_modifiers = {
		mcl_levelgen.build_in_biome (),
	},
})

------------------------------------------------------------------------
-- End Island.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/feature/EndIslandFeature.html
------------------------------------------------------------------------

local ceil = math.ceil
local cid_end_stone = core.get_content_id ("mcl_end:end_stone")

local function small_end_island_place (_, x, y, z, cfg, rng)
	local r = rng:next_within (3) + 4.0
	local dy = 0
	while r > 0.5 do
		for x1, y1, z1 in ipos3 (x + floor (-r),
					 y + dy,
					 z + floor (-r),
					 x + ceil (r),
					 y + dy,
					 z + ceil (r)) do
			local d = (x1 - x) * (x1 - x)
				+ (z1 - z) * (z1 - z)
			if d <= (r + 1.0) * (r + 1.0) then
				set_block (x1, y1, z1, cid_end_stone, 0)
			end
		end
		dy = dy - 1
		r = r - (rng:next_within (2) + 0.5)
	end
	return true
end

mcl_levelgen.register_feature ("mcl_end:end_island", {
	place = small_end_island_place,
})

mcl_levelgen.register_configured_feature ("mcl_end:end_island", {
	feature = "mcl_end:end_island",
})

mcl_levelgen.register_placed_feature ("mcl_end:end_island_decorated", {
	configured_feature = "mcl_end:end_island",
	placement_modifiers = {
		mcl_levelgen.build_rarity_filter (14),
		mcl_levelgen.build_count (W ({
			{
				weight = 3,
				data = 1,
			},
			{
				weight = 1,
				data = 2,
			},
		})),
		mcl_levelgen.build_in_square (),
		mcl_levelgen.build_height_range (uniform_height (55, 70)),
		mcl_levelgen.build_in_biome (),
	},
})
