mcl_fireworks = {}
local mod = core.get_current_modname()
local path = minetest.get_modpath(mod)
local S = core.get_translator(mod)

mcl_fireworks.registered_shapes = {
	{id = "large_ball", desc = S("Large Ball")},
	{id = "star", desc = S("Star-shaped")},
	{id = "creeper", desc = S("Creeper-shaped")},
	{id = "burst", desc = S("Burst")}
}

mcl_fireworks.registered_effects = {
	{id = "twinkle", desc = S("Twinkle")},
	{id = "trail", desc = S("Trail")}
}

dofile(path .. "/entity.lua")
dofile(path .. "/register.lua")
dofile(path .. "/crafting.lua")
