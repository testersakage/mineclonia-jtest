--------------------------------------------------------------------------
-- Level generator scripting interface.
--------------------------------------------------------------------------

local level_generator_scripts = {}

function mcl_levelgen.register_levelgen_script (script)
	if not core then
		mcl_levelgen.is_levelgen_environment = true
		dofile (script)
	elseif core.get_mod_storage then
		table.insert (level_generator_scripts, script)
		core.ipc_set ("mcl_levelgen:levelgen_scripts",
			      level_generator_scripts)
	end
end
