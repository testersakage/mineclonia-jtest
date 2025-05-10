local prefix = "."

if core and core.save_gen_notify then
	prefix = core.ipc_get ("mcl_levelgen:modpath")
elseif core and core.get_current_modname then
	prefix = core.get_modpath (core.get_current_modname ())
	core.ipc_set ("mcl_levelgen:modpath", prefix)
end

mcl_levelgen = { prefix = prefix, }
mcl_levelgen.md5 = dofile (prefix .. "/md5.lua")
dofile (prefix .. "/random.lua")
dofile (prefix .. "/noise.lua")
dofile (prefix .. "/density_funcs.lua")
dofile (prefix .. "/biomes.lua")
dofile (prefix .. "/presets.lua")
dofile (prefix .. "/terrain.lua")

-- Is this file being loaded into Minetest?
if core and core.get_current_modname then
	dofile (prefix .. "/register.lua")
end
