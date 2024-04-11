local S = minetest.get_translator(minetest.get_current_modname())

mcl_torches.register_torch({
	name = "torch",
	description = S("Torch"),
	doc_items_longdesc = S("Torches are light sources which can be placed at the side or on the top of most blocks."),
	doc_items_hidden = false,
	icon = "default_torch_on_floor.png",
	tiles = {{
		name = "default_torch_on_floor_animated.png",
		animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	-- this is 15 in minecraft
	light = 14,
	groups = {dig_immediate = 3, deco_block = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	particles = true,
	flame_type = 1,
})

local psdef = {
	amount = 8,
	time = 0,
	minpos = vector.new(-0.1, 0.05, -0.1),
	maxpos = vector.new(0.1, 0.15, 0.1),
	minvel = { x = -0.01, y = 0, z = -0.01 },
	maxvel = { x = 0.01, y = 0.1, z = 0.01 },
	minexptime = 0.3,
	maxexptime = 0.6,
	minsize = 0.7,
	maxsize = 2,
	texture = "mcl_particles_flame.png",
	glow = 14,
}

function mcl_torches.get_pspos(pos, _)
	local node = minetest.get_node(pos)
	local dir = minetest.wallmounted_to_dir(node.param2)
	local p1 = dir * 0.1
	local p2 = dir * 0.5
	return {
		minpos = vector.offset(p1, 0, 0.35, 0),
		maxpos = vector.offset(p2, 0, 0.45, 0),
	}
end

mcl_node_particles.register_particlespawner("mcl_torches:torch", psdef)
mcl_node_particles.register_particlespawner("mcl_torches:torch_wall", psdef, mcl_torches.get_pspos)

minetest.register_craft({
	output = "mcl_torches:torch 4",
	recipe = {
		{"group:coal"},
		{"mcl_core:stick"},
	}
})

