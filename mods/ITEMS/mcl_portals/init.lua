-- Load files

mcl_portals = {
	storage = core.get_mod_storage(),
}

local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath.."/portal_nether.lua")
dofile(modpath.."/portal_end.lua")
dofile(modpath.."/portal_gateway.lua")
