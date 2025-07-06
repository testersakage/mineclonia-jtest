local prefix = "."
local floor = math.floor

local function init_chunksize ()
	if not core.get_mapgen_chunksize
		or not mcl_vars.enable_mcl_levelgen then
		local cs = tonumber (core.get_mapgen_setting ("chunksize")) or 5
		core.ipc_set ("mcl_levelgen:mt_chunksize", vector.new (cs, cs, cs))
		local origin = floor (cs / 2)
		core.ipc_set ("mcl_levelgen:mt_chunk_origin",
			      vector.new (origin, origin, origin))
	else
		local cs = core.get_mapgen_chunksize ()
		if cs.x ~= cs.z then
			local blurb = "Chunk size must be symmetrical along the X axis: "
				.. vector.to_string (cs)
			core.log ("error", blurb)
			error ("Invalid chunk size")
		end

		local DESIRED_Y_SIZE = floor (384 / 16)
		local DESIRED_Y_BASE = floor (-128 / 16)
		cs.y = DESIRED_Y_SIZE
		core.set_mapgen_setting ("chunksize", vector.to_string (cs), true)

		local cs = core.get_mapgen_chunksize ()
		local v = vector.new (-floor (cs.x / 2), DESIRED_Y_BASE,
				      -floor (cs.z / 2))
		core.set_mapgen_setting ("chunk_origin", v:to_string (), true)
		core.ipc_set ("mcl_levelgen:mt_chunksize", cs)
		core.ipc_set ("mcl_levelgen:mt_chunk_origin", v)
	end
	core.ipc_set ("mcl_levelgen:mt_chunk_limit",
		      core.get_mapgen_setting ("mapgen_limit"))
end

if core and not core.get_mod_storage then
	prefix = core.ipc_get ("mcl_levelgen:modpath")
	mcl_vars = core.ipc_get ("mcl_levelgen:mcl_vars")
elseif core then
	prefix = core.get_modpath (core.get_current_modname ())
	core.ipc_set ("mcl_levelgen:modpath", prefix)
	core.ipc_set ("mcl_levelgen:mcl_vars", mcl_vars)
	init_chunksize ()
end

mcl_levelgen = { prefix = prefix, }
mcl_levelgen.md5 = dofile (prefix .. "/md5.lua")
mcl_levelgen.sha = dofile (prefix .. "/sha2.lua")
mcl_levelgen.lighting_disabled = false

mcl_levelgen.mt_chunksize
	= core and core.ipc_get ("mcl_levelgen:mt_chunksize")
mcl_levelgen.mt_chunk_origin
	= core and core.ipc_get ("mcl_levelgen:mt_chunk_origin")
mcl_levelgen.mt_chunk_limit
	= core and core.ipc_get ("mcl_levelgen:mt_chunk_limit")

dofile (prefix .. "/util.lua")
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
dofile (prefix .. "/schematics.lua")
dofile (prefix .. "/features.lua")
dofile (prefix .. "/structures.lua")
dofile (prefix .. "/scripting.lua")

-- Is this file being loaded into Minetest?
if core and core.get_current_modname then
	dofile (prefix .. "/nodeprops.lua")
	dofile (prefix .. "/templates.lua")
	dofile (prefix .. "/register.lua")
end
