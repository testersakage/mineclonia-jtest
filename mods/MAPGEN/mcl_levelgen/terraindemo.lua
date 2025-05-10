dofile ("init.lua")

local seed = mcl_levelgen.ull (0, 3228473)
local level = mcl_levelgen.make_overworld_preset (seed)
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (level, 80)

local a, b = {}, {}

overworld_terrain:generate (-48, -64, -48, a, b, function (x, y, z)
	return 0
end)
