------------------------------------------------------------------------
-- Level generator callbacks.
------------------------------------------------------------------------

-- local zone = require ("jit.zone")

if core.global_exists ("jit") then
	jit.opt.start ("maxmcode=16777216", "maxtrace=8000",
		       "loopunroll=10", "maxside=1000")
	-- require ("jit.dump").start ("+biraxmT", "server_perf.txt")
	-- local profile = require ("jit.p")
	-- profile.start ("fz")
end

local seed = mcl_levelgen.seed
local overworld_preset = mcl_levelgen.make_overworld_preset (seed)
local mt_chunksize = math.max (1, tonumber (core.get_mapgen_setting ("chunksize")) or 5)
local chunksize = mt_chunksize * 16
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (overworld_preset, chunksize)
local OVERWORLD_OFFSET = mcl_levelgen.OVERWORLD_OFFSET

local cids, param2s, biomes = {}, {}, {}

local area = nil

local function index (x, y, z)
	return area:index (x, y, chunksize - z - 1)
end

local floor = math.floor

core.register_on_generated (function (vmanip, minp, maxp, _)
	-- local clock = os.clock ()
	local emin, emax = vmanip:get_emerged_area ()
	area = VoxelArea (vector.subtract (emin, minp),
			  vector.subtract (emax, minp))
	vmanip:get_data (cids)
	local block_x = minp.x / 16
	local block_y = (OVERWORLD_OFFSET + minp.y) / 16
	local block_z = minp.z / 16
	assert (block_x == floor (block_x))
	assert (block_y == floor (block_y))
	assert (block_z == floor (block_z))
	local level_min = overworld_preset.min_y / 16
	local level_height = overworld_preset.height / 16
	assert (level_min == floor (level_min))
	assert (level_height == floor (level_height))
	-- zone ("Biome generation")
	mcl_levelgen.generate_biomes_at_block (overworld_preset, biomes,
					       block_x, level_min, block_z,
					       mt_chunksize, level_height)
	-- zone ()
	-- zone ("Terrain generation")
	if not overworld_terrain:generate (minp.x, OVERWORLD_OFFSET + minp.y,
					   -minp.z - chunksize, cids, param2s,
					   index, biomes) then
		return
	end
	-- zone ()
	vmanip:set_data (cids)
	vmanip:set_param2_data (param2s)
	vmanip:update_liquids ()

	-- zone ("Biome encoding")
	local compressed = mcl_levelgen.encode_biomes (biomes, block_y - level_min,
						       mt_chunksize, mt_chunksize,
						       level_height)
	core.save_gen_notify ("mcl_levelgen:biome_data", compressed)
	-- zone ()
	-- print (string.format ("%.2f", os.clock () - clock))
end)
