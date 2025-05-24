--------------------------------------------------------------------------
-- Level generator scripting interface.
--------------------------------------------------------------------------

local level_generator_scripts = {}

if core then
	core.ipc_set ("mcl_levelgen:levelgen_scripts", level_generator_scripts)
end

function mcl_levelgen.register_levelgen_script (script)
	if not core then
		dofile (script)
	else
		table.insert (level_generator_scripts, script)
		core.ipc_set ("mcl_levelgen:levelgen_scripts",
			      level_generator_scripts)
	end
end
