------------------------------------------------------------------------
-- Level generator callbacks.
------------------------------------------------------------------------

local ipairs = ipairs
local mathmin = math.min
local mathmax = math.max

mcl_levelgen.initialize_nodeprops_in_async_env ()
mcl_levelgen.initialize_portable_schematics ()

local lighting_disabled = mcl_levelgen.lighting_disabled

-- local zone = require ("jit.zone")

if core.global_exists ("jit") then
	jit.opt.start ("maxmcode=33554432", "maxtrace=100000",
		       -- Just large enough that loops employing RNGs
		       -- can be unrolled and compiled but the
		       -- fix_distances loop in pick_grid_positions is
		       -- not.
		       "loopunroll=35", "maxside=1000")
	-- require ("jit.dump").start ("+birxmT", "server_perf.txt")
	-- local profile = require ("jit.p")
	-- profile.start ("fv")
end

local overworld_preset = mcl_levelgen.overworld_preset
-- Load carvers into biome descriptions.
mcl_levelgen.load_carvers ()

local mt_chunksize
	= math.max (1, tonumber (core.get_mapgen_setting ("chunksize")) or 5)
local chunksize = mt_chunksize * 16
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (overworld_preset, chunksize)
local OVERWORLD_OFFSET = mcl_levelgen.OVERWORLD_OFFSET

local cids, param2s, structuremask, biomes = {}, {}, {}, {}

local area = nil

local function index (x, y, z)
	return area:index (x, y, chunksize - z - 1)
end

local floor = math.floor

-- local profile = require ("jit.p")
-- local v = require ("jit.v")

-- local function do_jit_ctrl ()
-- 	if core.ipc_get ("mcl_levelgen:jit_flush") then
-- 		jit.flush ()
-- 		core.ipc_set ("mcl_levelgen:jit_flush", false)
-- 	end
-- 	if core.ipc_get ("mcl_levelgen:jit_profiler") then
-- 		profile.start ("f2v")
-- 		core.ipc_set ("mcl_levelgen:jit_profiler", false)
-- 	end
-- 	if core.ipc_get ("mcl_levelgen:jit_v") then
-- 		require ("jit.v").start ()
-- 		core.ipc_set ("mcl_levelgen:jit_profiler", false)
-- 	end
-- 	if core.ipc_get ("mcl_levelgen:jit_profiler_flush") then
-- 		profile.stop ()
-- 		core.ipc_set ("mcl_levelgen:jit_profiler_flush", false)
-- 	end
-- end

-- local icnt = 0
-- profile.start ("fv")

local function unpack6 (x)
	return x[1], x[2], x[3], x[4], x[5], x[6]
end

local function transform_structure_pieces (pieces, minp, maxp)
	for _, piece in ipairs (pieces) do
		local x1, y1, z1, x2, y2, z2 = unpack6 (piece)
		z1, z2 = -z2 - 1, -z1 - 1

		piece[1] = mathmax (x1, minp.x)
		piece[2] = mathmax (y1 - OVERWORLD_OFFSET, minp.y)
		piece[3] = mathmax (z1, minp.z)
		piece[4] = mathmin (x2, maxp.x)
		piece[5] = mathmin (y2 - OVERWORLD_OFFSET, maxp.y)
		piece[6] = mathmin (z2, maxp.z)

		if piece[1] > piece[4] or piece[2] > piece[5] or piece[3] > piece[6] then
			core.log ("warning", ("[mcl_levelgen]: Invalid structure extents: "
					      .. string.format ("(%d,%d,%d) - (%d,%d,%d)",
								unpack6 (piece))))
		end
	end
end

core.register_on_generated (function (vmanip, minp, maxp, _)
	-- profile.start ("5fv")
	-- do_jit_ctrl ()
	local emin, emax = vmanip:get_emerged_area ()
	area = VoxelArea (vector.subtract (emin, minp),
			  vector.subtract (emax, minp))
	vmanip:get_data (cids)
	vmanip:get_param2_data (param2s)
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
	-- print (string.format ("{%d,%d,%d,%d,%d,%d,},", minp.x, minp.y, minp.z,
	-- 		      maxp.x, maxp.y, maxp.z))
	-- local clock = core.get_us_time ()
	-- zone ("Biome generation")
	mcl_levelgen.generate_biomes_at_block (overworld_preset, biomes,
					       block_x, level_min, block_z,
					       mt_chunksize, level_height)
	-- zone ()
	-- zone ("Terrain generation")
	if not overworld_terrain:generate (minp.x, OVERWORLD_OFFSET + minp.y,
					   -minp.z - chunksize, cids, param2s,
					   structuremask, index, biomes) then
		local notifications, _
			= mcl_levelgen.flush_structure_gen_data ()
		core.save_gen_notify ("mcl_levelgen:gen_notifies", notifications)
		core.save_gen_notify ("mcl_levelgen:structure_pieces", nil)
		return
	end
	-- print (string.format ("%.2f", (core.get_us_time () - clock) / 1000))
	-- zone ()
	vmanip:set_data (cids)
	vmanip:set_param2_data (param2s)

	if not lighting_disabled then
		vmanip:set_lighting ({day=0, night=0,})
		vmanip:calc_lighting ()
	end
	local notifications, pieces = mcl_levelgen.flush_structure_gen_data ()
	core.save_gen_notify ("mcl_levelgen:gen_notifies", notifications)
	transform_structure_pieces (pieces, minp, maxp)
	core.save_gen_notify ("mcl_levelgen:structure_pieces", pieces)

	-- zone ("Biome encoding")
	local compressed = mcl_levelgen.encode_biomes (biomes, block_y - level_min,
						       mt_chunksize, mt_chunksize,
						       level_height)
	core.save_gen_notify ("mcl_levelgen:biome_data", compressed)
	-- zone ()

	core.save_gen_notify ("mcl_levelgen:level_height_map", {
		level = overworld_terrain.heightmap,
		wg = overworld_terrain.heightmap_wg,
	})

	if #structuremask > 6 then
		core.save_gen_notify ("mcl_levelgen:structure_mask",
				      structuremask)
	end
	-- icnt = icnt + 1
	-- print (icnt)
	-- if icnt >= 20 then
	-- 	print ("\n=== 20 chunks generated ===")
	-- 	icnt = 0
	-- 	profile.start ("fv")
	-- end
end)
