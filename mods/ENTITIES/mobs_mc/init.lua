--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes
mobs_mc = {}

local pr = PseudoRandom(os.time()*5)

local offsets = {}
for x=-2, 2 do
	for z=-2, 2 do
		table.insert(offsets, {x=x, y=0, z=z})
	end
end

mobs_mc.shears_wear = 276
mobs_mc.water_level = tonumber(minetest.settings:get("water_level")) or 0

-- Auto load all lua files
local path = minetest.get_modpath("mobs_mc")
for _, file in pairs(minetest.get_dir_list(path, false)) do
	if file:sub(-4) == ".lua" and file ~= "init.lua" then
		dofile(path .. "/" ..file)
	end
end
