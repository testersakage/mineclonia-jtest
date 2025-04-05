mcl_end = {}

local basepath = core.get_modpath(core.get_current_modname())
dofile(basepath.."/chorus_plant.lua")
dofile(basepath.."/building.lua")
dofile(basepath.."/eye_of_ender.lua")
if not core.get_modpath("mcl_end_crystal") then
	dofile(basepath.."/end_crystal.lua")
end
