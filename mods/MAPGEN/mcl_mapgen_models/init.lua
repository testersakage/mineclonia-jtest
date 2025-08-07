mcl_mapgen_models = {}
local model = nil

local modpath = core.get_modpath (core.get_current_modname ())
dofile (modpath .. "/v7.lua")
dofile (modpath .. "/common.lua")

------------------------------------------------------------------------
-- Lua models of the built-in map generators.
------------------------------------------------------------------------

local name = core.get_mapgen_setting ("mg_name")
core.ipc_set ("mcl_mapgen_models:mg_name", name)

core.register_on_mods_loaded (function ()
	core.after (0, function ()
		if name == "v7" then
			model = mcl_mapgen_models.v7_mapgen_model ()
		else
			model = mcl_mapgen_models.ersatz_model ()
		end
	end)
end)

mcl_info.register_debug_field ("Estimated Generation Height", {
	level = 4,
	func = function (_, pos)
		if not model then
			return "N/A"
		else
			local x = math.floor (pos.x + 0.5)
			local z = math.floor (pos.z + 0.5)
			local fn = model.get_column_height
			return string.format ("y=%d/%d", fn (x, z, false), fn (x, z, true))
		end
	end,
})

------------------------------------------------------------------------
-- Exports.
------------------------------------------------------------------------

function mcl_mapgen_models.get_mapgen_model ()
	return model
end
