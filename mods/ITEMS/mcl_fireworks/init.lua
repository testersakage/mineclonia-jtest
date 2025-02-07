mcl_fireworks = {}
local mod = core.get_current_modname()
local path = minetest.get_modpath(mod)
--local S = core.get_translator(mod)
local tpl_ball_ps = {
	time = 1,
	amount = 512,
	minexptime = 0.5,
	maxexptime = 2,
	minacc = vector.new(0, -0.5, 0),
	maxacc = vector.new(0.5, -5, 0.5),
	size = { min = 0.5, max = 1.5 },
	glow = 14,
}

local function get_color_textures(colors)
	local tex = {}
	for _, c in pairs(colors) do
		if mcl_dyes.colors[c] then
			table.insert(tex, "mcl_particles_fire_flame.png^[colorize:"..mcl_dyes.colors[c].rgb)
		end
	end
	return tex
end

mcl_fireworks.registered_shapes = {
	ball = {
		id = 1,
		func = function(self)
			local rad = mcl_util.float_random(2,4)
			core.add_particlespawner(table.merge(tpl_ball_ps, {
				pos = self.object:get_pos(),
				amount = 512,
				radius = {
					min = vector.new(rad, rad, rad),
					max = vector.new(rad, rad, rad),
				},
				texpool = get_color_textures(self._effect.colors),
			}))
		end,
	},
	large_ball = {
		id = 2,
		func = function(self)
			local rad = mcl_util.float_random(5,8)
			core.add_particlespawner(table.merge(tpl_ball_ps, {
				pos = self.object:get_pos(),
				amount = 1024,
				radius = {
					min = vector.new(rad, rad, rad),
					max = vector.new(rad, rad, rad),
				},
				texpool = get_color_textures(self._effect.colors),
			}))
		end,
	},
	star = { id = 3 },
	creeper = { id = 4 },
	burst = {
		id = 5,
		func = function(self)
			local rad = mcl_util.float_random(5,8)
			core.add_particlespawner({
				pos = self.object:get_pos(),
				radius = {
					min = vector.new(-0.2, rad, -0.2),
					max = vector.new(0.2, rad*2, 0.2),
				},
				texpool = get_color_textures(self._effect.colors),
				time = 1,
				amount = 512,
				minexptime = 0.8,
				maxexptime = 3,
				minacc = vector.new(-1.5, 8, -1.5),
				maxacc = vector.new(1.5, 19, 1.5),
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
	twinkle = { id = 1 },
	trail = { id = 2 },
}

mcl_fireworks.index_shape = {}
mcl_fireworks.index_effect = {}
for k, v in pairs(mcl_fireworks.registered_shapes) do
	if v.id then
		mcl_fireworks.index_shape[v.id] = k
	end
end

for k, v in pairs(mcl_fireworks.registered_effects) do
	if v.id then
		mcl_fireworks.index_effect[v.id] = k
	end
end

dofile(path .. "/entity.lua")
dofile(path .. "/register.lua")
dofile(path .. "/crafting.lua")
