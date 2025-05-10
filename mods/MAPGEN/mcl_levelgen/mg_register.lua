------------------------------------------------------------------------
-- Level generator callbacks.
------------------------------------------------------------------------

local seed = mcl_levelgen.seed
local overworld_preset = mcl_levelgen.make_overworld_preset (seed)
local mt_chunksize = math.max (1, tonumber (core.get_mapgen_setting ("chunksize")) or 5)
local chunksize = mt_chunksize * 16
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (overworld_preset, chunksize)

local cids, param2s = {}, {}

local area = nil

local function index (x, y, z)
	return area:index (x, y, chunksize - z - 1)
end

core.register_on_generated (function (vmanip, minp, maxp, _)
	local emin, emax = vmanip:get_emerged_area ()
	area = VoxelArea (vector.subtract (emin, minp),
			  vector.subtract (emax, minp))
	vmanip:get_data (cids)
	if not overworld_terrain:generate (minp.x, minp.y, -minp.z,
					   cids, param2s, index) then
		return
	end
	vmanip:set_data (cids)
	vmanip:set_param2_data (param2s)
end)
