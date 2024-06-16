local mg_seed = minetest.get_mapgen_setting("seed")
--[[ THE END ]]
minetest.register_biome({
	name = "End",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 1000, --ridiculously high values so End Island always takes precedent
	humidity_point = 1000,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})
minetest.register_biome({
	name = "EndBarrens",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 1000,
	humidity_point = 1000,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})
minetest.register_biome({
	name = "EndMidlands",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 1000,
	humidity_point = 1000,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})
minetest.register_biome({
	name = "EndHighlands",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 1000,
	humidity_point = 1000,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})
minetest.register_biome({
	name = "EndSmallIslands",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 1000,
	humidity_point = 1000,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})

minetest.register_biome({
	name = "EndBorder",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max + 80,
	heat_point = 500,
	humidity_point = 500,
	vertical_blend = 16,
	max_pos = {x = 1250, y = mcl_vars.mg_end_min + 512, z = 1250},
	min_pos = {x = -1250, y = mcl_vars.mg_end_min, z = -1250},
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})

minetest.register_biome({
	name = "EndIsland",
	node_stone = "air",
	node_filler = "air",
	node_water = "air",
	node_river_water = "air",
	node_cave_liquid = "air",
	max_pos = {x = 650, y = mcl_vars.mg_end_min + 512, z = 650},
	min_pos = {x = -650, y = mcl_vars.mg_end_min, z = -650},
	heat_point = 50,
	humidity_point = 50,
	vertical_blend = 16,
	_mcl_biome_type = "medium",
	_mcl_palette_index = 0,
--		_mcl_skycolor = end_skycolor,
--		_mcl_fogcolor = end_fogcolor
})

-- Generate fake End
-- TODO: Remove the "ores" when there's a better End generator

minetest.register_ore({
	ore_type        = "stratum",
	ore             = "mcl_end:end_stone",
	wherein         = {"air"},
	biomes          = {"EndSmallIslands","Endborder"},
	y_min           = mcl_vars.mg_end_min+64,
	y_max           = mcl_vars.mg_end_min+80,
	clust_num_ores  = 3375,
	clust_size      = 15,

	noise_params = {
		offset  = mcl_vars.mg_end_min+70,
		scale   = -1,
		spread  = {x=84, y=84, z=84},
		seed    = 145,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		--flags = "defaults",
	},

	np_stratum_thickness = {
		offset  = 0,
		scale   = 15,
		spread  = {x=84, y=84, z=84},
		seed    = 145,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		--flags = "defaults",
	},
	clust_scarcity = 1,
})

minetest.register_ore({
	ore_type        = "stratum",
	ore             = "mcl_end:end_stone",
	wherein         = {"air"},
	biomes          = {"End","EndMidlands","EndHighlands","EndBarrens"},
	y_min           = mcl_vars.mg_end_min+64,
	y_max           = mcl_vars.mg_end_min+80,

	noise_params = {
		offset  = mcl_vars.mg_end_min+70,
		scale   = -1,
		spread  = {x=126, y=126, z=126},
		seed    = mg_seed+9999,
		octaves = 3,
		persist = 0.5,
	},

	np_stratum_thickness = {
		offset  = -2,
		scale   = 10,
		spread  = {x=126, y=126, z=126},
		seed    = mg_seed+9999,
		octaves = 3,
		persist = 0.5,
	},
	clust_scarcity = 1,
})

minetest.register_ore({
	ore_type        = "stratum",
	ore             = "mcl_end:end_stone",
	wherein         = {"air"},
	biomes          = {"End","EndMidlands","EndHighlands","EndBarrens"},
	y_min           = mcl_vars.mg_end_min+64,
	y_max           = mcl_vars.mg_end_min+80,

	noise_params = {
		offset  = mcl_vars.mg_end_min+72,
		scale   = -3,
		spread  = {x=84, y=84, z=84},
		seed    = mg_seed+999,
		octaves = 4,
		persist = 0.8,
	},

	np_stratum_thickness = {
		offset  = -4,
		scale   = 10,
		spread  = {x=84, y=84, z=84},
		seed    = mg_seed+999,
		octaves = 4,
		persist = 0.8,
	},
	clust_scarcity = 1,
})
minetest.register_ore({
	ore_type        = "stratum",
	ore             = "mcl_end:end_stone",
	wherein         = {"air"},
	biomes          = {"End","EndMidlands","EndHighlands","EndBarrens"},
	y_min           = mcl_vars.mg_end_min+64,
	y_max           = mcl_vars.mg_end_min+80,

	noise_params = {
		offset  = mcl_vars.mg_end_min+70,
		scale   = -2,
		spread  = {x=84, y=84, z=84},
		seed    = mg_seed+99,
		octaves = 4,
		persist = 0.85,
	},

	np_stratum_thickness = {
		offset  = -3,
		scale   = 5,
		spread  = {x=63, y=63, z=63},
		seed    = mg_seed+50,
		octaves = 4,
		persist = 0.85,
	},
	clust_scarcity = 1,
})


-- Chorus plant
minetest.register_decoration({
	name = "mcl_biomes:chorus",
	deco_type = "simple",
	place_on = {"mcl_end:end_stone"},
	flags = "all_floors",
	sidelen = 16,
	noise_params = {
		offset = -0.012,
		scale = 0.024,
		spread = {x = 100, y = 100, z = 100},
		seed = 257,
		octaves = 3,
		persist = 0.6
	},
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max,
	decoration = "mcl_end:chorus_plant",
	height = 1,
	height_max = 8,
	biomes = { "End", "EndMidlands", "EndHighlands", "EndBarrens", "EndSmallIslands" },
})
minetest.register_decoration({
	name = "mcl_biomes:chorus_plant",
	deco_type = "simple",
	place_on = {"mcl_end:chorus_plant"},
	flags = "all_floors",
	sidelen = 16,
	fill_ratio = 10,
	--[[noise_params = {
		offset = -0.012,
		scale = 0.024,
		spread = {x = 100, y = 100, z = 100},
		seed = 257,
		octaves = 3,
		persist = 0.6
	},--]]
	y_min = mcl_vars.mg_end_min,
	y_max = mcl_vars.mg_end_max,
	decoration = "mcl_end:chorus_flower",
	height = 1,
	biomes = { "End", "EndMidlands", "EndHighlands", "EndBarrens", "EndSmallIslands" },
})

-- TODO: End cities
