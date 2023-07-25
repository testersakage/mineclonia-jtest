local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize
local F = minetest.formspec_escape

mcl_furnaces = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/api.lua")

mcl_furnaces.register_furnace("furnace",{
	active = {
		tiles = {
			"default_furnace_top.png", "default_furnace_bottom.png",
			"default_furnace_side.png", "default_furnace_side.png",
			"default_furnace_side.png", {name = "mcl_furnaces_furnace_front_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, frames_w = 1, frames_h = 3, length = 0.6}},
		},
	},
})
mcl_furnaces.register_furnace("blast_furnace",{
	_mcl_furnace_groups = {
		ore = 2,
	},
	normal = {
		description = S("Blast Furnace"),
		_tt_help = S("Smelts ores faster than furnace"),
				S([[
					Use the furnace to open the furnace menu.
					Place a furnace fuel in the lower slot and the source material in the upper slot.
					The furnace will slowly use its fuel to smelt the item.
					The result will be placed into the output slot at the right side.
				]]).."\n"..
				S("Use the recipe book to see what ores you can smelt, what you can use as fuel and how long it will burn."),
		tiles = {
			"mcl_furnaces_blast_furnace_top.png", "mcl_furnaces_blast_furnace_top.png",
			"mcl_furnaces_blast_furnace_side.png", "mcl_furnaces_blast_furnace_side.png",
			"mcl_furnaces_blast_furnace_side.png", "mcl_furnaces_blast_furnace_front.png"
		},
	},
	active = {
		description = S("Blast Furnace"),
		tiles = {
			"mcl_furnaces_blast_furnace_top.png", "mcl_furnaces_blast_furnace_top.png",
			"mcl_furnaces_blast_furnace_side.png", "mcl_furnaces_blast_furnace_side.png",
			"mcl_furnaces_blast_furnace_side.png",
			{name = "mcl_furnaces_blast_furnace_front_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, frames_w = 1, frames_h = 2, length = 0.6}}
		},
	}
})
mcl_furnaces.register_furnace("smoker",{
	_mcl_furnace_groups = {
		food = 2,
	},
	normal = {
		description = S("Smoker"),
		_tt_help = S("Cooks food faster than furnace"),
				S([[
					Use the smoker to open the furnace menu.
					Place a furnace fuel in the lower slot and the source material in the upper slot.
					The smoker will slowly use its fuel to smelt the item.
					The result will be placed into the output slot at the right side.
				]]).."\n"..
				S("Use the recipe book to see what foods you can smelt, what you can use as fuel and how long it will burn."),
		tiles = {
			"mcl_furnaces_smoker_top.png", "mcl_furnaces_smoker_bottom.png",
			"mcl_furnaces_smoker_side.png", "mcl_furnaces_smoker_side.png",
			"mcl_furnaces_smoker_side.png", "mcl_furnaces_smoker_front.png"
		},
	},
	active = {
		description = S("Smoker"),
		tiles = {
			"mcl_furnaces_smoker_top.png", "mcl_furnaces_smoker_bottom.png",
			"mcl_furnaces_smoker_side.png", "mcl_furnaces_smoker_side.png",
			"mcl_furnaces_smoker_side.png", {name = "mcl_furnaces_smoker_front_animated.png",
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, frames_w = 1, frames_h = 3, length = 0.6}},
		},
	}
})

minetest.register_craft({
	output = "mcl_furnaces:furnace",
	recipe = {
		{ "group:cobble", "group:cobble", "group:cobble" },
		{ "group:cobble", "",             "group:cobble" },
		{ "group:cobble", "group:cobble", "group:cobble" },
	}
})

minetest.register_craft({
	output = "mcl_furnaces:smoker",
	recipe = {
		{ "", "group:tree", "" },
		{ "group:tree", "mcl_furnaces:furnace", "group:tree" },
		{ "", "group:tree", "" },
	}
})

minetest.register_craft({
	output = "mcl_blast_furnace:blast_furnace",
	recipe = {
		{ "mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot" },
		{ "mcl_core:iron_ingot", "mcl_furnaces:furnace", "mcl_core:iron_ingot" },
		{ "mcl_core:stone_polished", "mcl_core:stone_polished", "mcl_core:stone_polished" },
	}
})

dofile(modpath.."/aliases.lua")
