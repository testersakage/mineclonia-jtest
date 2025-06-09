dofile ("init.lua")
dofile ("mineshaft.lua")
dofile ("beardifier_demo.lua")

local seed = mcl_levelgen.ull (0, 3228473)
local level = mcl_levelgen.make_overworld_preset (seed)
local overworld_terrain
	= mcl_levelgen.make_terrain_generator (level, 80)
mcl_levelgen.load_carvers ()

local a, b, structuremask = {}, {}, {}
local biomes = {}

local clock = os.clock ()

local function index (x, y, z)
	return x * 80 * 80 + y * 80 + z + 1
end

print ("Starting to generate terrain...")

local function do_generate (x, y, z)
	mcl_levelgen.generate_biomes_at_block (level, biomes,
					       x / 16,
					       level.min_y / 16,
					       z / 16, 5,
					       level.height / 16)
	overworld_terrain:generate (x, y, z, a, b, structuremask,
				    index, biomes)
end

for i = 1, 15 do

do_generate (-48 + i * 3 * 16, -32, -48 + i * 3 * 32)
do_generate (-48 + i * 3 * 16, -32, -48 + i * -3 * 32)
do_generate (-48 + i * 3 * 16, 0, -48 + i * 6 * 16)
do_generate (-48 + i * 3 * 32, 0, -48 + i * 6 * 16)

print ("Generated " .. i * 4 .. " MapChunks...")

end

print ("Generation completed in: " .. math.floor (os.clock () - clock + 0.5) .. " s")
-- print (string.format ("%.3f%%", (nwithveins / ntotal * 100)), nwithveins, ntotal)

