local S = minetest.get_translator(minetest.get_current_modname())
local extra_nodes = minetest.settings:get_bool("mcl_extra_nodes", true)
-- Liquids: River Water

local source = table.copy(minetest.registered_nodes["mcl_core:water_source"])
source.description = S("River Water Source")
source.liquid_range = 2
source.waving = 3
source.liquid_alternative_flowing = "mclx_core:river_water_flowing"
source.liquid_alternative_source = "mclx_core:river_water_source"
source.liquid_renewable = false
source._doc_items_longdesc = S("River water has the same properties as water, but has a reduced flowing distance and is not renewable.")
source._doc_items_entry_name = S("River Water")
-- Auto-expose entry only in valleys mapgen
source._doc_items_hidden = minetest.get_mapgen_setting("mg_name") ~= "valleys"
source.post_effect_color = {a=192, r=0x2c, g=0x88, b=0x8c}
source.tiles = {
	{name="default_river_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0}}
}
source.special_tiles = {
	-- New-style water source material (mostly unused)
	{
		name="default_river_water_source_animated.png",
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0},
		backface_culling = false,
	}
}

local flowing = table.copy(minetest.registered_nodes["mcl_core:water_flowing"])
flowing.description = S("Flowing River Water")
flowing.liquid_range = 2
flowing.waving = 3
flowing.liquid_alternative_flowing = "mclx_core:river_water_flowing"
flowing.liquid_alternative_source = "mclx_core:river_water_source"
flowing.liquid_renewable = false
flowing.tiles = {"default_river_water_flowing_animated.png^[verticalframe:64:0"}
flowing.post_effect_color = {a=192, r=0x2c, g=0x88, b=0x8c}
flowing.special_tiles = {
	{
		image="default_river_water_flowing_animated.png",
		backface_culling=false,
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
	},
	{
		image="default_river_water_flowing_animated.png",
		backface_culling=false,
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
	},
}

minetest.register_node("mclx_core:river_water_source", source)
minetest.register_node("mclx_core:river_water_flowing", flowing)

if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mclx_core:river_water_source", "nodes", "mclx_core:river_water_flowing")
end

local groups = { pickaxey = 1, building_block = 1, material_stone = 1, stonecuttable = 1 }

minetest.register_node(":mcl_core:andesite_smoothbrick", {
	description = S("Smooth Andesite Bricks"),
	_doc_items_longdesc = S("Smooth andesite bricks are decorative bricks made from smooth andesite."),
	tiles = { "mcl_core_andesite_bricks.png" },
	groups = extra_nodes and groups or table.merge(groups, { not_in_creative_inventory = 1 }),
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_core:andesite_smooth" }
})

minetest.register_node(":mcl_core:diorite_smoothbrick", {
	description = S("Smooth Diorite Bricks"),
	_doc_items_longdesc = S("Smooth diorite bricks are decorative bricks made from smooth diorite."),
	tiles = { "mcl_core_diorite_bricks.png" },
	groups = extra_nodes and groups or table.merge(groups, { not_in_creative_inventory = 1 }),
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_core:diorite_smooth" }
})

minetest.register_node(":mcl_core:granite_smoothbrick", {
	description = S("Smooth Granite Bricks"),
	_doc_items_longdesc = S("Smooth granite bricks are decorative bricks made from smooth granite."),
	tiles = { "mcl_core_granite_bricks.png" },
	groups = extra_nodes and groups or table.merge(groups, { not_in_creative_inventory = 1 }),
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_core:granite_smooth" }
})

mcl_stairs.register_stair_and_slab("andesite_smoothbrick", {
	baseitem = "mcl_core:andesite_smoothbrick",
	description_stair = S("Smooth Andesite Bricks Stairs"),
	description_slab = S("Smooth Andesite Bricks Slab"),
	groups = not extra_nodes and { not_in_creative_inventory = 1 },
	overrides = {_mcl_stonecutter_recipes = { "mcl_core:andesite_smoothbrick" }},
})

mcl_stairs.register_stair_and_slab("diorite_smoothbrick", {
	baseitem = "mcl_core:diorite_smoothbrick",
	description_stair = S("Smooth Diorite Bricks Stairs"),
	description_slab = S("Smooth Diorite Bricks Slab"),
	groups = not extra_nodes and { not_in_creative_inventory = 1 },
	overrides = {_mcl_stonecutter_recipes = { "mcl_core:diorite_smoothbrick" }},
})

mcl_stairs.register_stair_and_slab("granite_smoothbrick", {
	baseitem = "mcl_core:granite_smoothbrick",
	description_stair = S("Smooth Granite Bricks Stairs"),
	description_slab = S("Smooth Granite Bricks Slab"),
	groups = not extra_nodes and { not_in_creative_inventory = 1 },
	overrides = {_mcl_stonecutter_recipes = { "mcl_core:granite_smoothbrick" }},
})
