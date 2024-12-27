mcl_farming = {}
local path = core.get_modpath(core.get_current_modname())
-- IMPORTANT API AND HELPER FUNCTIONS --
-- Contain functions for planting seed, addind plant growth and gourds (melon/pumpkin-like)
dofile(path.."/shared_functions.lua")

dofile(path.."/api.lua")
dofile(path.."/soil.lua")
dofile(path.."/hoes.lua")
dofile(path.."/wheat.lua")
dofile(path.."/pumpkin.lua")
dofile(path.."/melon.lua")
dofile(path.."/carrots.lua")
dofile(path.."/potatoes.lua")
dofile(path.."/beetroot.lua")
dofile(path.."/sweet_berry.lua")
