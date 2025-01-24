mcl_fireworks = {}
local mod = core.get_current_modname()
local path = minetest.get_modpath(mod)
--local S = core.get_translator(mod)

mcl_fireworks.registered_shapes = {
	--[[
	--{id = "large_ball", desc = S("Large Ball")},
	{id = "star", desc = S("Star-shaped")},
	{id = "creeper", desc = S("Creeper-shaped")},
	{id = "burst", desc = S("Burst")}
	--]]
}

mcl_fireworks.registered_effects = {
	circle = {
		func = function(self)
			local color = self._color or "#FF0000"
			core.add_particlespawner({
				pos = self.object:get_pos(),
				time = 1,
				amount = 32,
				exptime = 4,
				minvel = 1,
				maxvel = 3,
				acc = 0,
				radius = {
					min = vector.new(2, 2, 2),
					max = vector.new(2, 2, 2),
				},
				texture = "mcl_particles_fire_flame.png^[colorize:"..color,
				size = { min = 0.5, max = 1.5 },
				glow = 14,
			})
		end,
	},
--	{id = "twinkle", desc = S("Twinkle")},
--	{id = "trail", desc = S("Trail")}
}

dofile(path .. "/entity.lua")
dofile(path .. "/register.lua")
dofile(path .. "/crafting.lua")
