mcl_bamboo = {}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator("mcl_bamboo")

dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/recipes.lua")

mcl_util.generate_on_place_plant_function(function(pos)
	local node_below = minetest.get_node(vector.offset(pos,0,-1,0))
	return minetest.get_item_group(node_below.name, "soil_bamboo") > 0
end)

-- Historically mcla provided non canonical bamboo bark blocks.
-- These have been replaced by aliases, but for the time being can be reenabled
-- (instead of the aliases) by setting `extra_nodes` to true.
local extra_nodes = false

local block_doc = S("A Block made of Bamboo stalks. Can be crafted into Bamboo Planks.")

local block_groups = {
	handy = 1, axey = 1, material_wood = 1, building_block = 1,
	flammable = 3, fire_encouragement = 5, fire_flammability = 20
}

mcl_trees.register_wood("bamboo",{
	readable_name = "Bamboo",
	sign_color="#FCE6BC",
	sapling = false,
	potted_sapling = false,
	leaves = false,
	wood_amount = 2,
	tree = {
		description = S("Block of Bamboo"),
		_doc_items_longdesc = block_doc,
		groups = block_groups,
		tiles = {"mcl_bamboo_bamboo_bottom.png", "mcl_bamboo_bamboo_bottom.png","mcl_bamboo_bamboo_block.png" },
		_mcl_cooking_output = false,
	},
	stripped = {
		description = S("Block of Stripped Bamboo"),
		_doc_items_longdesc = block_doc,
		groups = block_groups,
		tiles = {"mcl_bamboo_bamboo_bottom_stripped.png", "mcl_bamboo_bamboo_bottom_stripped.png","mcl_bamboo_bamboo_block_stripped.png" }
	},
	wood = { tiles = {"mcl_bamboo_bamboo_plank.png"}},
	bark = extra_nodes and { tiles = {"mcl_bamboo_bamboo_block.png"}},
	stripped_bark = extra_nodes and { tiles = {"mcl_bamboo_bamboo_block_stripped.png"}},
	fence = { tiles = { "mcl_bamboo_fence_bamboo.png" },},
	fence_gate = { tiles = { "mcl_bamboo_fence_gate_bamboo.png" }, },
	door = {
		inventory_image = "mcl_bamboo_door_wield.png",
		tiles_bottom = {"mcl_bamboo_door_bottom.png","mcl_bamboo_door_bottom.png"},
		tiles_top = {"mcl_bamboo_door_top.png","mcl_bamboo_door_bottom.png"},
	},
	trapdoor = {
		tile_front = "mcl_bamboo_trapdoor_side.png",
		tile_side = "mcl_bamboo_trapdoor_side.png",
		wield_image = "mcl_bamboo_trapdoor_side.png",
	},
	boat = {
		item = {
			description = S("Bamboo Raft"),
		},
		object = {
			collisionbox = {-0.5, -0.15, -0.5, 0.5, 0.25, 0.5},
			selectionbox = {-0.7, -0.15, -0.7, 0.7, 0.25, 0.7},
		},
	}, --needs different model
	chest_boat = {
		item = {
			description = S("Chest Bamboo Raft"),
		},
		object = {
			collisionbox = {-0.5, -0.15, -0.5, 0.5, 0.25, 0.5},
			selectionbox = {-0.7, -0.15, -0.7, 0.7, 0.25, 0.7},
		},
	},
})

minetest.register_abm({
	label = "Bamboo growth",
	nodenames = {"group:bamboo_tree"},
	neighbors = {"group:soil_sapling","group:soil_bamboo"},
	interval = 15,
	chance = 10,
	action = function(pos,node)
		mcl_bamboo.grow(pos)
	end,
})

if not extra_nodes then
	minetest.register_alias("mcl_trees:bark_bamboo", "mcl_trees:tree_bamboo")
	minetest.register_alias("mcl_trees:bark_stripped_bamboo", "mcl_trees:stripped_bamboo")
	minetest.register_alias("mcl_stairs:slab_bamboo_bark", "mcl_stairs:slab_bamboo")
	minetest.register_alias("mcl_stairs:slab_bamboo_bark_double", "mcl_stairs:slab_bamboo_double")
	minetest.register_alias("mcl_stairs:slab_bamboo_bark_top", "mcl_stairs:slab_bamboo_top")
	minetest.register_alias("mcl_stairs:stair_bamboo_bark", "mcl_stairs:stair_bamboo")
	minetest.register_alias("mcl_stairs:stair_bamboo_bark_inner", "mcl_stairs:stair_bamboo_inner")
	minetest.register_alias("mcl_stairs:stair_bamboo_bark_outer", "mcl_stairs:stair_bamboo_outer")
end
