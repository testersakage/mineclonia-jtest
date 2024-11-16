mcl_redstone = {}

mcl_redstone._solid_opaque_tab = {} -- True if node is opaque by name

--- Wireflags are numbers with binary representation YYYYXXXX where XXXX
--- determines if there is a visible connection in each of the four cardinal
--- directions and YYYY if the respective connection also goes up over the
--- neighbouring node. Order of the bits (right to left) are -z, +x, +z, -x.
--
-- This table contains wireflags by node name.
mcl_redstone._wireflag_tab = {}

minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		if minetest.get_item_group(name, "opaque") ~= 0 and minetest.get_item_group(name, "solid") ~= 0 then
			mcl_redstone._solid_opaque_tab[name] = true
		end
	end
end)

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/propagate.lua")
dofile(modpath.."/logic.lua")
dofile(modpath.."/eventqueue.lua")
dofile(modpath.."/wire.lua")
