local prefix = "."

if core and not core.get_mod_storage then
	prefix = core.ipc_get ("mcl_levelgen:modpath")
	mcl_vars = core.ipc_get ("mcl_levelgen:mcl_vars")
elseif core then
	prefix = core.get_modpath (core.get_current_modname ())
	core.ipc_set ("mcl_levelgen:modpath", prefix)
	core.ipc_set ("mcl_levelgen:mcl_vars", mcl_vars)

	local mt_chunksize
		= math.max (1, tonumber (core.get_mapgen_setting ("chunksize")) or 5)
	core.ipc_set ("mcl_levelgen:mt_chunksize", mt_chunksize)
end

mcl_levelgen = { prefix = prefix, }
mcl_levelgen.md5 = dofile (prefix .. "/md5.lua")
mcl_levelgen.sha = dofile (prefix .. "/sha2.lua")

dofile (prefix .. "/random.lua")
dofile (prefix .. "/noise.lua")
dofile (prefix .. "/density_funcs.lua")
dofile (prefix .. "/biomes.lua")
dofile (prefix .. "/presets.lua")
dofile (prefix .. "/terrain.lua")
dofile (prefix .. "/biomegen.lua")
dofile (prefix .. "/aquifer.lua")
dofile (prefix .. "/surface_system.lua")
dofile (prefix .. "/surface_presets.lua")
dofile (prefix .. "/carvers.lua")
dofile (prefix .. "/features.lua")
dofile (prefix .. "/scripting.lua")

-- Is this file being loaded into Minetest?
if core and core.get_current_modname then
	dofile (prefix .. "/util.lua")
	dofile (prefix .. "/nodeprops.lua")
	dofile (prefix .. "/register.lua")
end
