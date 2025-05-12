------------------------------------------------------------------------
-- Level generator callbacks.
------------------------------------------------------------------------

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
	mcl_levelgen.generate_biomes_at_block (overworld_preset, biomes,
					       block_x, block_y, block_z,
					       mt_chunksize, mt_chunksize)
	if not overworld_terrain:generate (minp.x, OVERWORLD_OFFSET + minp.y,
					   -minp.z - chunksize, cids, param2s,
					   index) then
		return
	end
	vmanip:set_data (cids)
	vmanip:set_param2_data (param2s)
	vmanip:update_liquids ()

	local compressed = mcl_levelgen.encode_biomes (biomes, mt_chunksize,
						       mt_chunksize)
	core.save_gen_notify ("mcl_levelgen:biome_data", compressed)
end)
