------------------------------------------------------------------------
-- Lua models of the built-in map generators.
------------------------------------------------------------------------

function mcl_mapgen_models.ersatz_model ()
	local sea_level = core.get_mapgen_setting ("water_level")
	return {
		is_ersatz_model = true,
		get_column_height = function (x, z)
			return sea_level + 1
		end,
	}
end
