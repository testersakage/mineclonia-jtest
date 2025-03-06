local S = core.get_translator(core.get_current_modname())

core.register_node("mcl_pale_garden:resin_block", {
	_mcl_blast_resistance = 0,
	_mcl_crafting_output = {single = {output = "mcl_pale_garden:resin_clump 9"}},
	_mcl_hardness = 0,
	description = S("Block of Resin"),
	groups = {building_block = 1, dig_immediate = 3},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	tiles = {"mcl_pale_garden_resin_block.png"}
})

core.register_node("mcl_pale_garden:resin_bricks", {
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	description = S("Resin Bricks"),
	groups = {building_block = 1, pickaxey = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	tiles = {"mcl_pale_garden_resin_bricks.png"}
})

core.register_node("mcl_pale_garden:chiseled_resin_bricks", {
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	description = S("Chiseled Resin Bricks"),
	groups = {building_block = 1, pickaxey = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	tiles = {"mcl_pale_garden_chiseled_resin_bricks.png"}
})

core.register_node("mcl_pale_garden:resin_clump", {
	_mcl_blast_resistance = 0,
	_mcl_crafting_output = {square3 = {output = "mcl_pale_garden:resin_block"}},
	_mcl_hardness = 0,
	description = S("Resin Clump"),
	drawtype = "signlike",
	groups = {
		attached_node = 1, building_block = 1, destroy_by_lava_flow = 1, dig_by_piston = 1,
		dig_by_water = 1, dig_immediate = 1
	},
	inventory_image = "mcl_pale_garden_resin_clump_inv.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sounds = mcl_sounds.node_sound_stone_defaults(),
	sunlight_propagates = true,
	selection_box = {fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, type = "fixed"},
	tiles = {"mcl_pale_garden_resin_clump.png"},
	use_texture_alpha = "blend",
	wield_image = "mcl_pale_garden_resin_clump_inv.png"
})

mcl_stairs.register_stair_and_slab("resin_bricks", {
	baseitem = "mcl_pale_garden:resin_bricks",
	description_slab = S("Resin Brick Slab"),
	description_stair = S("Resin Brick Stairs"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_pale_garden:resin_bricks"}}
})

mcl_walls.register_wall_def("mcl_pale_garden:resinbrickwall",{
	_mcl_stonecutter_recipes = { "mcl_pale_garden:resin_bricks" },
	description = S("Resin Brick Wall"),
	source = "mcl_pale_garden:resin_bricks",
	tiles = {"mcl_pale_garden_resin_bricks.png"}
})

core.register_craftitem("mcl_pale_garden:resin_brick", {
	_mcl_crafting_output = {square2 = {output = "mcl_pale_garden:resin_bricks"}},
	description = S("Resin Brick"),
	groups = {crafitem = 1},
	inventory_image = "mcl_pale_garden_resin_brick.png",
	wield_image = "mcl_pale_garden_resin_brick.png"
})

