mcl_fireworks = {}
local mod = core.get_current_modname()
local path = minetest.get_modpath(mod)
--local S = core.get_translator(mod)

mcl_fireworks.registered_shapes = {
	ball = {
		func = function(self)
			local colors = { "red", "black", "orange" }
			local tex = {}
			for _, c in pairs(colors) do
				if mcl_dyes.colors[c] then
					table.insert(tex, "mcl_particles_fire_flame.png^[colorize:"..mcl_dyes.colors[c].rgb)
				end
			end
			local rad = math.random(2,5)
			core.add_particlespawner({
				pos = self.object:get_pos(),
				time = 1,
				amount = 512,
				minexptime = 0.5,
				maxexptime = 2,
				minacc = vector.new(0, -0.5, 0),
				maxacc = vector.new(0.5, -5, 0.5),
				radius = {
					min = vector.new(rad, rad, rad),
					max = vector.new(rad, rad, rad),
				},
				texpool = tex,
				size = { min = 0.5, max = 1.5 },
				glow = 14,
			})
		end,
	},
	--[[
	--{id = "large_ball", desc = S("Large Ball")},
	{id = "star", desc = S("Star-shaped")},
	{id = "creeper", desc = S("Creeper-shaped")},
	{id = "burst", desc = S("Burst")}
	--]]
}

mcl_fireworks.registered_effects = {
--	{id = "twinkle", desc = S("Twinkle")},
--	{id = "trail", desc = S("Trail")}
}

dofile(path .. "/entity.lua")
dofile(path .. "/register.lua")
dofile(path .. "/crafting.lua")
