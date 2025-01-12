mcl_fireworks = {}
mcl_fireworks.registered_shapes = {"large_ball", "star", "creeper", "burst"}
mcl_fireworks.registered_effects = {"twinkle", "trail"}

local path = minetest.get_modpath("mcl_fireworks")

dofile(path .. "/entity.lua")
dofile(path .. "/register.lua")
dofile(path .. "/crafting.lua")
