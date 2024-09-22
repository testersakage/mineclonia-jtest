mcl_redstone = {}

mcl_redstone._solid_opaque_tab = {}

minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		if minetest.get_item_group(name, "opaque") ~= 0 and minetest.get_item_group(name, "solid") ~= 0 then
			mcl_redstone._solid_opaque_tab[name] = true
		end
	end
end)

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/logic.lua")
dofile(modpath.."/eventqueue.lua")
dofile(modpath.."/wire.lua")
