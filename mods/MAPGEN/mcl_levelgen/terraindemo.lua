dofile ("init.lua")

local seed = mcl_levelgen.ull (0, 3228473)
local level = mcl_levelgen.make_overworld_preset (seed)
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (level, 80)

local a, b = {}, {}

local clock = os.clock ()

local function index (x, y, z)
	return x * 80 * 80 + y * 80 + z + 1
end

print ("Starting to generate terrain...")

for i = 1, 300 do

overworld_terrain:generate (-48 + i * 16, -32, -48 + i * 32, a, b, index)
overworld_terrain:generate (-48 + i * 16, 0, -48 + i * 16, a, b, index)
overworld_terrain:generate (-48 + i * 32, 0, -48 + i * 16, a, b, index)

print ("Generated " .. i * 3 .. " MapChunks...")

end

print ("Generation completed in: " .. math.floor (os.clock () - clock + 0.5) .. " s")
