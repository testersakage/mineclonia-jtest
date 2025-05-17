------------------------------------------------------------------------
-- Level generator registration.
------------------------------------------------------------------------

local seed_str = core.get_mapgen_setting ("seed")
local ull = mcl_levelgen.ull
local tostringull = mcl_levelgen.tostringull
local stringtoull = mcl_levelgen.stringtoull

local seed = ull (0, 0)
mcl_levelgen.seed = seed
if not stringtoull (seed, seed_str) then
	core.log ("error", "`" .. seed_str .. "' is not a valid seed")
end

-- Load existing biome ID assignments.
local assignments = {}
local mod_storage
if core.save_gen_notify then
	assignments = core.ipc_get ("mcl_levelgen:biome_id_assignments")
else
	mod_storage = core.get_mod_storage ()
	local str = mod_storage:get_string ("biome_id_assignments")
	if str and str ~= "" then
		assignments = core.deserialize (str)
	end
end

-- Assign IDs to new biomes if any.
mcl_levelgen.assign_biome_ids (assignments)

if core.save_gen_notify then
	dofile (mcl_levelgen.prefix .. "/mg_register.lua")
else
	core.log ("action", ("[mcl_levelgen]: Initializing level generation with seed "
			     .. tostringull (seed)))
	mod_storage:set_string ("biome_id_assignments",
				core.serialize (assignments))
	core.ipc_set ("mcl_levelgen:biome_id_assignments", assignments)
	core.register_mapgen_script (mcl_levelgen.prefix .. "/init.lua")
end

