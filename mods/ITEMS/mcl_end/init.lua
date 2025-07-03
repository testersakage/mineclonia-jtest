mcl_end = {}

local basepath = core.get_modpath(core.get_current_modname())
dofile(basepath.."/chorus_plant.lua")
dofile(basepath.."/building.lua")
dofile(basepath.."/eye_of_ender.lua")
if not core.get_modpath("mcl_end_crystal") then
	dofile(basepath.."/end_crystal.lua")
end

------------------------------------------------------------------------
-- Level generation & callbacks.
------------------------------------------------------------------------

mcl_levelgen.register_levelgen_script (basepath .. "/lg_register.lua")

local v = vector.zero ()
local level_to_minetest_position = mcl_levelgen.level_to_minetest_position

local function handle_spawn_end_crystal (_, data)
	v.x, v.y, v.z
		= level_to_minetest_position (data[1], data[2], data[3])
	core.add_entity (v, "mcl_end:crystal")
end

mcl_levelgen.register_notification_handler ("mcl_end:spawn_end_crystal",
					    handle_spawn_end_crystal)
