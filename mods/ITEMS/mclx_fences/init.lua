local S = minetest.get_translator(minetest.get_current_modname())
local extra_nodes = false and minetest.settings:get_bool("mcl_extra_nodes", true)

-- Red Nether Brick Fence and Red Nether Brick Fence Gate
mcl_fences.register_fence_and_fence_gate_def("red_nether_brick_fence", {
	tiles = { "mcl_fences_fence_red_nether_brick.png" },
	groups = { pickaxey = 1, fence_nether_brick = 1, not_in_creative_inventory = not extra_nodes and 1 or 0 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = minetest.registered_nodes["mcl_nether:red_nether_brick"]._mcl_blast_resistance,
	_mcl_hardness = minetest.registered_nodes["mcl_nether:red_nether_brick"]._mcl_hardness,
	_mcl_fences_baseitem = "mcl_nether:red_nether_brick",
	_mcl_fences_stickreplacer = "mcl_nether:netherbrick",
}, {
	description = S("Red Nether Brick Fence"),
	connects_to = { "group:fence_nether_brick", "group:solid" },
}, {
	description = S("Red Nether Brick Fence Gate"),
	_mcl_fences_sounds = {
		open = {
			spec = "mcl_fences_nether_brick_fence_gate_open"
		},
		close = {
			spec = "mcl_fences_nether_brick_fence_gate_close"
		}
	},
	_mcl_fences_output_amount = 2
})

-- Nether Brick Fence Gate
mcl_fences.register_fence_gate_def("nether_brick_fence", {
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


for wood, defs in pairs(mcl_trees.woods) do
	local groups = {
		handy = 1, axey = 1, material_wood = 1, fence_wood = 1,
		flammable = 3, fire_encouragement = 5, fire_flammability = 20
	}

	local basedefs = minetest.registered_nodes["mcl_trees:bark_"..wood]

	if defs.bark and defs.bark.groups then
		groups = defs.bark.groups
		groups.fence_wood = 1
	end

	mcl_fences.register_fence_and_fence_gate_def("wood_"..wood, {
		groups = extra_nodes and groups or table.merge(groups, { not_in_creative_inventory = 1 }),
		sounds = mcl_sounds.node_sound_wood_defaults(),
		tiles = basedefs.tiles,
		_on_axe_place = mcl_trees.strip_tree,
		_mcl_blast_resistance = basedefs._mcl_blast_resistance,
		_mcl_hardness = basedefs._mcl_hardness,
		_mcl_burntime = basedefs._mcl_burntime,
		_mcl_fences_baseitem = "mcl_trees:tree_"..wood
	}, {
		description = S("@1 Bark Fence", defs.readable_name),
		connects_to = { "group:fence_wood", "group:solid" },
		_mcl_stripped_variant = "mcl_fences:wood_stripped_"..wood,
		_mcl_fences_output_amount = 8
	}, {
		description = S("@1 Bark Fence Gate", defs.readable_name),
		_mcl_stripped_variant = "mcl_fences:wood_stripped_"..wood.."_gate",
		_mcl_fences_output_amount = 4
	})

	basedefs = minetest.registered_nodes["mcl_trees:bark_stripped_"..wood]

	mcl_fences.register_fence_and_fence_gate_def("wood_stripped_"..wood, {
		groups = extra_nodes and groups or table.merge(groups, { not_in_creative_inventory = 1 }),
		sounds = mcl_sounds.node_sound_wood_defaults(),
		tiles = basedefs.tiles,
		_mcl_blast_resistance = basedefs._mcl_blast_resistance,
		_mcl_hardness = basedefs._mcl_hardness,
		_mcl_burntime = basedefs._mcl_burntime,
		_mcl_fences_baseitem = "mcl_trees:stripped_"..wood
	}, {
		description = S("Stripped @1 Wood Fence", defs.readable_name),
		connects_to = { "group:fence_wood", "group:solid" },
		_mcl_fences_output_amount = 8
	}, {
		description = S("Stripped @1 Wood Fence Gate", defs.readable_name),
		_mcl_fences_output_amount = 4
	})
end

-- Aliases for mcl_supplemental
minetest.register_alias("mcl_supplemental:red_nether_brick_fence", "mclx_fences:red_nether_brick_fence")

minetest.register_alias("mcl_supplemental:nether_brick_fence_gate", "mclx_fences:nether_brick_fence_gate")
minetest.register_alias("mcl_supplemental:nether_brick_fence_gate_open", "mclx_fences:nether_brick_fence_gate_open")

minetest.register_alias("mcl_supplemental:red_nether_brick_fence_gate", "mclx_fences:red_nether_brick_fence_gate")
minetest.register_alias("mcl_supplemental:red_nether_brick_fence_gate_open", "mclx_fences:red_nether_brick_fence_gate_open")
