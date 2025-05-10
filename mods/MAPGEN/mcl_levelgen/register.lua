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

if core.save_gen_notify then
	dofile (mcl_levelgen.prefix .. "/mg_register.lua")
else
	core.log ("action", ("[mcl_levelgen]: Initializing level generation with seed "
			     .. tostringull (seed)))
	core.register_mapgen_script (mcl_levelgen.prefix .. "/init.lua")
end

