local prefix = "."

if core and core.save_gen_notify then
	prefix = core.ipc_get ("mcl_levelgen:modpath")
	mcl_vars = core.ipc_get ("mcl_levelgen:mcl_vars")
elseif core and core.get_current_modname then
	prefix = core.get_modpath (core.get_current_modname ())
	core.ipc_set ("mcl_levelgen:modpath", prefix)
	core.ipc_set ("mcl_levelgen:mcl_vars", mcl_vars)
end

mcl_levelgen = { prefix = prefix, }
mcl_levelgen.md5 = dofile (prefix .. "/md5.lua")
dofile (prefix .. "/random.lua")
dofile (prefix .. "/noise.lua")
dofile (prefix .. "/density_funcs.lua")
dofile (prefix .. "/biomes.lua")
dofile (prefix .. "/presets.lua")
dofile (prefix .. "/terrain.lua")
dofile (prefix .. "/biomegen.lua")
dofile (prefix .. "/aquifer.lua")

-- Is this file being loaded into Minetest?
if core and core.get_current_modname then
	dofile (prefix .. "/util.lua")
	dofile (prefix .. "/register.lua")
end
