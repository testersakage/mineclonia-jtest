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
	light =  14,
	groups = {dig_immediate = 3, deco_block = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	particles = {
		smoke = {
			maxpos_to_add = vector.new(0.0625, 0.1875, 0.0625),
			minpos_to_add = vector.new(-0.0625, 0.125, -0.0625),
			ps_defs = {
				maxvel = vector.new(0.025, 0.3125, 0.025),
				minvel = vector.new(-0.025, 0.25, -0.025),
				maxacc = vector.new(0, 0.5, 0),
				minacc = vector.new(0, 0.5, 0),
				texpool = {
					{
						name = "mcl_torches_smoke_anim.png^[colorize:black",
						animation = {
							type = "vertical_frames",
							aspect_h = 16,
							aspect_w = 16,
							length = 1
						}
					},
					{
						name = "mcl_torches_smoke_anim.png^[colorize:gray",
						animation = {
							type = "vertical_frames",
							aspect_h = 16,
							aspect_w = 16,
							length = 1
						}
					},
					{
						name = "mcl_torches_smoke_anim.png^[colorize:silver",
						animation = {
							type = "vertical_frames",
							aspect_h = 16,
							aspect_w = 16,
							length = 1
						}
					}
				}
			}
		},
		flame = "mcl_particles_fire_flame.png"
	}
})

minetest.register_craft({
	output = "mcl_torches:torch 4",
	recipe = {
		{"group:coal"},
		{"mcl_core:stick"},
	}
})

