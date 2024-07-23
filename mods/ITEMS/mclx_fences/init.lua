local S = minetest.get_translator(minetest.get_current_modname())
local extra_nodes = minetest.settings:get_bool("mcl_extra_nodes", true)

-- Red Nether Brick Fence
mcl_fences.register_fence("red_nether_brick_fence", {
	description = S("Red Nether Brick Fence"),
	tiles = { "mcl_fences_fence_red_nether_brick.png" },
	groups = { pickaxey = 1, fence_nether_brick = 1, not_in_creative_inventory = not extra_nodes and 1 or 0 },
	connects_to = { "group:fence_nether_brick" },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 2,
})

mcl_fences.register_fence_gate("nether_brick_fence", {
	description = S("Nether Brick Fence Gate"),
	tiles = { "mcl_fences_fence_gate_nether_brick.png" },
	groups = { pickaxey = 1, fence_nether_brick = 1, not_in_creative_inventory = not extra_nodes and 1 or 0 },
	_mcl_blast_resistance = minetest.registered_nodes["mcl_nether:nether_brick"]._mcl_blast_resistance,
	_mcl_hardness = minetest.registered_nodes["mcl_nether:nether_brick"]._mcl_hardness,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_fences_sounds = {
		open = {
			spec = "mcl_fences_nether_brick_fence_gate_open"
		},
		close = {
			spec = "mcl_fences_nether_brick_fence_gate_close"
		}
	},
	_mcl_fences_baseitem = "mcl_nether:nether_brick",
	_mcl_fences_stickreplacer = "mcl_nether:netherbrick",
	_mcl_fences_output_amount = 2
})

-- Crafting

if extra_nodes then

	minetest.register_craft({
		output = "mclx_fences:red_nether_brick_fence_gate",
		recipe = {
			{"mcl_nether:nether_wart_item", "mcl_nether:red_nether_brick", "mcl_nether:netherbrick"},
			{"mcl_nether:netherbrick", "mcl_nether:red_nether_brick", "mcl_nether:nether_wart_item"},
		}
	})
	minetest.register_craft({
		output = "mclx_fences:red_nether_brick_fence_gate",
		recipe = {
			{"mcl_nether:netherbrick", "mcl_nether:red_nether_brick", "mcl_nether:nether_wart_item"},
			{"mcl_nether:nether_wart_item", "mcl_nether:red_nether_brick", "mcl_nether:netherbrick"},
		}
	})
end


-- Aliases for mcl_supplemental
minetest.register_alias("mcl_supplemental:red_nether_brick_fence", "mclx_fences:red_nether_brick_fence")

minetest.register_alias("mcl_supplemental:nether_brick_fence_gate", "mclx_fences:nether_brick_fence_gate")
minetest.register_alias("mcl_supplemental:nether_brick_fence_gate_open", "mclx_fences:nether_brick_fence_gate_open")

minetest.register_alias("mcl_supplemental:red_nether_brick_fence_gate", "mclx_fences:red_nether_brick_fence_gate")
minetest.register_alias("mcl_supplemental:red_nether_brick_fence_gate_open", "mclx_fences:red_nether_brick_fence_gate_open")
