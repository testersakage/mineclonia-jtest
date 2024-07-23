local mod_mcl_structures = minetest.get_modpath("mcl_structures")
local mod_mcl_core = minetest.get_modpath("mcl_core")
local mod_mcl_mushrooms = minetest.get_modpath("mcl_mushrooms")
local mod_mcl_mangrove = minetest.get_modpath("mcl_mangrove")
local mod_cherry_blossom = minetest.get_modpath("mcl_cherry_blossom")

-- Template to register a grass or fern decoration
function mcl_biomes.register_grass_decoration(grasstype, offset, scale, biomes)
	local place_on, seed, node
	if grasstype == "fern" then
		node = "mcl_flowers:fern"
		place_on = {"group:grass_block_no_snow", "mcl_core:podzol","mcl_mud:mud"}
		seed = 333
	elseif grasstype == "tallgrass" then
		node = "mcl_flowers:tallgrass"
		place_on = {"group:grass_block_no_snow","mcl_mud:mud"}
		seed = 420
	end
	local noise = {
		offset = offset,
		scale = scale,
		spread = {x = 200, y = 200, z = 200},
		seed = seed,
		octaves = 3,
		persist = 0.6
	}
	for b=1, #biomes do
		local param2 = minetest.registered_biomes[biomes[b]]._mcl_palette_index
		minetest.register_decoration({
			deco_type = "simple",
			place_on = place_on,
			sidelen = 16,
			noise_params = noise,
			biomes = { biomes[b] },
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			decoration = node,
			param2 = param2,
		})
	end
end

local register_grass_decoration = mcl_biomes.register_grass_decoration

function mcl_biomes.register_seagrass_decoration(grasstype, offset, scale, biomes)
	local seed, nodes, surfaces, param2, param2_max, y_max
	if grasstype == "seagrass" then
		seed = 16
		param2 = 3
		surfaces = { "mcl_core:dirt", "mcl_core:sand", "mcl_core:gravel", "mcl_core:redsand" }
		nodes = { "mcl_ocean:seagrass_dirt", "mcl_ocean:seagrass_sand", "mcl_ocean:seagrass_gravel", "mcl_ocean:seagrass_redsand" }
		y_max = 0
	elseif grasstype == "kelp" then
		seed = 32
		param2 = 16
		param2_max = 96
		surfaces = { "mcl_core:dirt", "mcl_core:sand", "mcl_core:gravel" }
		nodes = { "mcl_ocean:kelp_dirt", "mcl_ocean:kelp_sand", "mcl_ocean:kelp_gravel" }
		y_max = -6
	end
	local noise = {
		offset = offset,
		scale = scale,
		spread = {x = 100, y = 100, z = 100},
		seed = seed,
		octaves = 3,
		persist = 0.6,
	}

	for s=1, #surfaces do
		minetest.register_decoration({
			deco_type = "simple",
			place_on = { surfaces[s] },
			sidelen = 16,
			noise_params = noise,
			biomes = biomes,
			y_min = mcl_vars.mg_ocean_deep_min,
			y_max = y_max,
			decoration = nodes[s],
			param2 = param2,
			param2_max = param2_max,
			place_offset_y = -1,
			flags = "force_placement",
		})
	end
end

local register_seagrass_decoration = mcl_biomes.register_seagrass_decoration

local coral_min = mcl_vars.mg_ocean_min
local coral_max = -10
local warm_oceans = {
	"BambooJungle_ocean",
	"JungleEdgeM_ocean",
	"Jungle_deep_ocean",
	"Savanna_ocean",
	"MesaPlateauF_ocean",
	"Swampland_ocean",
	"Mesa_ocean",
	"Plains_ocean",
	"MesaPlateauFM_ocean",
	"MushroomIsland_ocean",
	"SavannaM_ocean",
	"JungleEdge_ocean",
	"MesaBryce_ocean",
	"Jungle_ocean",
	"Desert_ocean",
	"JungleM_ocean",
	"MangroveSwamp_ocean"
}
local corals = {
	"brain",
	"horn",
	"bubble",
	"tube",
	"fire"
}

local function register_coral_decos(ck)
	local c = corals[ck]
	local noise = {
			offset = -0.0085,
			scale = 0.002,
			spread = {x = 25, y = 120, z = 25},
			seed = 235,
			octaves = 5,
			persist = 1.8,
			lacunarity = 3.5,
			flags = "absvalue"
		}
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:sand","mcl_core:gravel","mcl_mud:mud"},
		sidelen = 80,
		noise_params = noise,
		biomes = warm_oceans,
		y_min = coral_min,
		y_max = coral_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_coral_"..c.."_1.mts",
		rotation = "random",
		flags = "all_floors,force_placement",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:sand","mcl_core:gravel","mcl_mud:mud"},
		noise_params = noise,
		sidelen = 80,
		biomes = warm_oceans,
		y_min = coral_min,
		y_max = coral_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_coral_"..c.."_2.mts",
		rotation = "random",
		flags = "all_floors,force_placement",
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:"..c.."_coral_block"},
		sidelen = 16,
		fill_ratio = 3,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:"..c.."_coral",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:horn_coral_block"},
		sidelen = 16,
		fill_ratio = 7,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:"..c.."_coral_fan",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
	})
end

function mcl_biomes.register_decorations()
	--Deep Dark
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_sculk:sculk"},
		sidelen = 16,
		fill_ratio = 0.1,
		decoration = "mcl_sculk:catalyst",
		biomes = {"DeepDark"},
		flags = "all_floors",
	})
	-- Coral Reefs
	for k,_ in pairs(corals) do
		register_coral_decos(k)
	end


	local lushcaves = { "LushCaves", "LushCaves_underground", "LushCaves_ocean", "LushCaves_deep_ocean"}
	local lushcaves_underground = { "LushCaves_underground", "LushCaves_ocean", "LushCaves_deep_ocean"}

	minetest.register_decoration({
		decoration = "mcl_lush_caves:moss",
		deco_type = "simple",
		place_on = table.merge(mcl_biomes.stonelike, {"mcl_core:stone","mcl_deepslate:deepslate","mcl_deepslate:tuff", "mcl_core:gravel", "mcl_core:bedrock"}),
		biomes = lushcaves,
		fill_ratio = 10,
		flags = "all_floors, all_ceilings",
		y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
		decoration = "mcl_flowers:tallgrass",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:moss"},
		biomes = lushcaves,
		fill_ratio = 1,
		flags = "all_floors",
		y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
		decoration = "mcl_lush_caves:cave_vines",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:moss"},
		height = 1,
		height_max = 4,
		fill_ratio = 0.2,
		flags = "all_ceilings",
		biomes = lushcaves_underground,
		y_min = mcl_vars.mg_overworld_min,
	})
	minetest.register_decoration({
		decoration = "mcl_lush_caves:cave_vines_lit",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:moss"},
		height = 1,
		height_max = 4,
		fill_ratio = 0.3,
		flags = "all_ceilings",
		biomes = lushcaves_underground,
		y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
			decoration = "mcl_lush_caves:azalea",
			deco_type = "simple",
			place_on = {"mcl_lush_caves:moss"},
			biomes = lushcaves,
			fill_ratio = 0.2,
			flags = "all_floors",
			y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
			decoration = "mcl_lush_caves:azalea_flowering",
			deco_type = "simple",
			place_on = {"mcl_lush_caves:moss"},
			biomes = lushcaves,
			fill_ratio = 0.05,
			flags = "all_floors",
			y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
		decoration = "mcl_lush_caves:cave_vines_lit",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:cave_vines_lit","mcl_lush_caves:cave_vines"},
		height = 1,
		height_max = 4,
		fill_ratio = 0.1,
		flags = "all_ceilings",
		biomes = lushcaves_underground,
		y_min = mcl_vars.mg_overworld_min,
	})
	minetest.register_decoration({
		decoration = "mcl_lush_caves:cave_vines",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:cave_vines_lit","mcl_lush_caves:cave_vines"},
		height = 1,
		height_max = 5,
		fill_ratio = 0.1,
		flags = "all_ceilings",
		biomes = lushcaves_underground,
		y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
		place_on = {"mcl_lush_caves:rooted_dirt"},
		decoration = "mcl_lush_caves:hanging_roots",
		deco_type = "simple",
		fill_ratio = 10,
		flags = "all_ceilings",
		biomes = lushcaves,
		y_min = mcl_vars.mg_overworld_min,
	})

	minetest.register_decoration({
		decoration = "mcl_lush_caves:spore_blossom",
		deco_type = "simple",
		place_on = {"mcl_lush_caves:moss"},
		spawn_by = {"air"},
		num_spawn_by = 4,
		fill_ratio = 0.8,
		param2 = 4,
		flags = "all_ceilings",
		y_min = mcl_vars.mg_overworld_min,
		biomes = lushcaves_underground,
	})

	minetest.register_decoration({
		decoration = "mcl_lush_caves:moss_carpet",
		deco_type = "simple",
		place_on = table.merge(mcl_biomes.stonelike, {"mcl_deepslate:deepslate", "mcl_core:gravel","mcl_lush_caves:moss"}),
		fill_ratio = 0.1,
		flags = "all_floors",
		y_min = mcl_vars.mg_overworld_min,
		biomes = lushcaves,
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = "mcl_lush_caves:moss","mcl_core:clay",
		fill_ratio = 0.5,
		biomes = lushcaves,
		decoration = "mcl_flowers:tallgrass",
		y_min = mcl_vars.mg_overworld_min,
		flags = "all_floors",
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:sand","mcl_core:gravel","mcl_mud:mud"},
		sidelen = 16,
		noise_params = {
			offset = -0.0085,
			scale = 0.002,
			spread = {x = 25, y = 120, z = 25},
			seed = 235,
			octaves = 5,
			persist = 1.8,
			lacunarity = 3.5,
			flags = "absvalue"
		},
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:dead_brain_coral_block",
		biomes = warm_oceans,
		flags = "force_placement",
		height = 1,
		height_max = 1,
		place_offset_y = -1,
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:dead_brain_coral_block"},
		sidelen = 16,
		fill_ratio = 3,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:sea_pickle_1_dead_brain_coral_block",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
		place_offset_y = -1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:dead_brain_coral_block"},
		sidelen = 16,
		fill_ratio = 3,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:sea_pickle_2_dead_brain_coral_block",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
		place_offset_y = -1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:dead_brain_coral_block"},
		sidelen = 16,
		fill_ratio = 2,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:sea_pickle_3_dead_brain_coral_block",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
		place_offset_y = -1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_ocean:dead_brain_coral_block"},
		sidelen = 16,
		fill_ratio = 2,
		y_min = coral_min,
		y_max = coral_max,
		decoration = "mcl_ocean:sea_pickle_4_dead_brain_coral_block",
		biomes = warm_oceans,
		flags = "force_placement, all_floors",
		height = 1,
		height_max = 1,
		place_offset_y = -1,
	})
	--rare CORAl
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:sand","mcl_core:gravel"},
		fill_ratio = 0.0001,
		sidelen = 80,
		biomes = warm_oceans,
		y_min = coral_min,
		y_max = coral_max,
		schematic = mod_mcl_structures.."/schematics/coral_cora.mts",
		rotation = "random",
		flags = "place_center_x,place_center_z, force_placement",
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:dirt_with_grass","mcl_core:podzol"},
		sidelen = 16,
		noise_params = {
			offset = 0,
			scale = 0.012,
			spread = {x = 100, y = 100, z = 100},
			seed = 354,
			octaves = 1,
			persist = 0.5,
			lacunarity = 1.0,
			flags = "absvalue"
		},
		biomes = {"Taiga","ColdTaiga","MegaTaiga","MegaSpruceTaiga"},
		y_max = mcl_vars.mg_overworld_max,
		y_min = 2,
		decoration = "mcl_sweet_berry:sweet_berry_bush_3"
	})

	-- Large ice spike
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:snowblock", "mcl_core:snow", "group:grass_block_snow"},
		sidelen = 80,
		noise_params = {
			offset = 0.00040,
			scale = 0.001,
			spread = {x = 250, y = 250, z = 250},
			seed = 1133,
			octaves = 4,
			persist = 0.67,
		},
		biomes = {"IcePlainsSpikes"},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_ice_spike_large.mts",
		rotation = "random",
		flags = "place_center_x, place_center_z",
	})

	-- Small ice spike
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:snowblock", "mcl_core:snow", "group:grass_block_snow"},
		sidelen = 80,
		noise_params = {
			offset = 0.005,
			scale = 0.001,
			spread = {x = 250, y = 250, z = 250},
			seed = 1133,
			octaves = 4,
			persist = 0.67,
		},
		biomes = {"IcePlainsSpikes"},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_ice_spike_small.mts",
		rotation = "random",
		flags = "place_center_x, place_center_z",
	})

	-- Oak
	-- Large oaks
	for i=1, 4 do
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
			sidelen = 80,
			noise_params = {
				offset = 0.000545,
				scale = 0.0011,
				spread = {x = 250, y = 250, z = 250},
				seed = 3 + 5 * i,
				octaves = 3,
				persist = 0.66
			},
			biomes = {"Forest"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/mcl_core_oak_large_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})

		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"group:grass_block", "mcl_core:dirt", },
			sidelen = 80,
			noise_params = {
				offset = -0.0007,
				scale = 0.001,
				spread = {x = 250, y = 250, z = 250},
				seed = 3,
				octaves = 3,
				persist = 0.6
			},
			biomes = {"ExtremeHills", "ExtremeHillsM", "ExtremeHills+", "ExtremeHills+_snowtop"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/mcl_core_oak_large_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
	end
	-- Small “classic” oak (many biomes)
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.025,
			scale = 0.0022,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"Forest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.01,
			scale = 0.0022,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"FlowerForest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block", "mcl_core:dirt", },
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.002,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"ExtremeHills", "ExtremeHillsM", "ExtremeHills+", "ExtremeHills+_snowtop"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.006,
			scale = 0.002,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"ExtremeHills+", "ExtremeHills+_snowtop"},
		y_min = 50,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.015,
			scale = 0.002,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"MesaPlateauF_grasstop"},
		y_min = 30,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.008,
			scale = 0.002,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"MesaPlateauFM_grasstop"},
		y_min = 30,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block", "mcl_core:dirt", },
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.0002,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"IcePlains"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.004,
		biomes = {"Jungle", "JungleM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.0004,
		biomes = {"BambooJungle", "JungleEdge", "JungleEdgeM", "Savanna"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_mud:mud"},
		fill_ratio = 0.004,
		height = 7,
		height_max = 15,
		biomes = {"BambooJungle", "Jungle", "JungleM", "JungleEdge", "MangroveSwamp"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		param2 = 0,
		param2_max = 3,
		decoration = "mcl_bamboo:bamboo" ,
	})
	for i=1,3 do
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_mud:mud"},
			fill_ratio = 0.004+(i*0.001),
			height = 7,
			height_max = 15,
			param2 = 0,
			param2_max = 3,
			biomes = {"BambooJungle", "Jungle", "JungleM", "JungleEdge", "MangroveSwamp"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			decoration = "mcl_bamboo:bamboo"..i,
		})
	end

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_mud:mud"},
		fill_ratio = 0.1,
		height = 7,
		height_max = 15,
		biomes = { "BambooJungle" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		param2 = 0,
		param2_max = 3,
		decoration = "mcl_bamboo:bamboo" ,
	})
	for i=1,3 do
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_mud:mud"},
			fill_ratio = 0.1+(i*0.001),
			height = 7,
			height_max = 15,
			param2 = 0,
			param2_max = 3,
			biomes = { "BambooJungle" },
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			decoration = "mcl_bamboo:bamboo"..i,
		})
	end

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		--[[noise_params = {
			offset = 0.01,
			scale = 0.00001,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.33
		},]]--
		fill_ratio = 0.0002,
		biomes = {"FlowerForest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic_bee_nest.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
		spawn_by = "group:flower",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		--[[noise_params = {
			offset = 0.01,
			scale = 0.00001,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.33
		},]]--
		fill_ratio = 0.00002,
		biomes = {"Forest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_classic_bee_nest.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
		spawn_by = "group:flower",
	})

	-- Rare balloon oak
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.002083,
			scale = 0.0022,
			spread = {x = 250, y = 250, z = 250},
			seed = 3,
			octaves = 3,
			persist = 0.6,
		},
		biomes = {"Forest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_balloon.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	-- Swamp oak
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.0055,
			scale = 0.0011,
			spread = {x = 250, y = 250, z = 250},
			seed = 5005,
			octaves = 5,
			persist = 0.6,
		},
		biomes = {"Swampland", "Swampland_shore"},
		y_min = 0,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_oak_swamp.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		name = "mcl_biomes:mangrove_tree_1",
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.0065,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_tree_1.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
	})
	minetest.register_decoration({
		name = "mcl_biomes:mangrove_tree_2",
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.0045,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = -1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_tree_2.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
	})
	minetest.register_decoration({
		name = "mcl_biomes:mangrove_tree_3",
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.023,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = -1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_tree_3.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
	})
	minetest.register_decoration({
		name = "mcl_biomes:mangrove_tree_4",
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.023,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = -1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_tree_4.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
	})
	minetest.register_decoration({
		name = "mcl_biomes:mangrove_tree_5",
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.023,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = -1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_tree_5.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		--[[noise_params = {
			offset = 0.01,
			scale = 0.00001,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.33
		},]]--
		fill_ratio = 0.0005,
		biomes = {"MangroveSwamp"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mangrove.."/schematics/mcl_mangrove_bee_nest.mts",
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random",
		spawn_by = "group:flower",
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.045,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = 0,
		y_max = 0,
		decoration = "mcl_mangrove:water_logged_roots",
		flags = "place_center_x, place_center_z, force_placement",
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_mangrove:mangrove_roots"},
		spawn_by = {"group:water"},
		num_spawn_by = 2,
		sidelen = 80,
		fill_ratio = 10,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		y_min = 0,
		y_max = 0,
		decoration = "mcl_mangrove:water_logged_roots",
		flags = "place_center_x, place_center_z, force_placement, all_ceilings",
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.045,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		place_offset_y = -1,
		decoration = "mcl_mangrove:mangrove_mud_roots",
		flags = "place_center_x, place_center_z, force_placement",
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_mud:mud"},
		sidelen = 80,
		fill_ratio = 0.008,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		decoration = "mcl_core:deadbush",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:water_source"},
		sidelen = 80,
		fill_ratio = 0.035,
		biomes = {"MangroveSwamp","MangroveSwamp_shore"},
		decoration = "mcl_flowers:waterlily",
		flags = "place_center_x, place_center_z, liquid_surface",
	})

	-- Jungle tree

	-- Huge jungle tree (4 variants)
	for i=1, 4 do
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
			sidelen = 80,
			fill_ratio = 0.0008,
			biomes = {"Jungle"},
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_huge_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
			sidelen = 80,
			fill_ratio = 0.003,
			biomes = {"JungleM"},
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_huge_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
	end

	-- Common jungle tree
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.025,
		biomes = {"Jungle"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.015,
		biomes = {"Jungle"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_2.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.005,
		biomes = {"Jungle"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_3.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.005,
		biomes = {"Jungle"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_4.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.025,
		biomes = {"Jungle"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.0045,
		biomes = {"BambooJungle", "JungleEdge", "JungleEdgeM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		fill_ratio = 0.09,
		biomes = {"JungleM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_tree_2.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})
	-- Spruce
	local function quick_spruce(seed, offset, sprucename, biomes, y)
		if not y then
			y = 1
		end
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"group:grass_block", "mcl_core:dirt", "mcl_core:podzol"},
			sidelen = 16,
			noise_params = {
				offset = offset,
				scale = 0.0006,
				spread = {x = 250, y = 250, z = 250},
				seed = seed,
				octaves = 3,
				persist = 0.66
			},
			biomes = biomes,
			y_min = y,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/"..sprucename,
			flags = "place_center_x, place_center_z",
		})
	end

	-- Huge spruce
	quick_spruce(3000, 0.0030, "mcl_core_spruce_huge_1.mts", {"MegaSpruceTaiga"})
	quick_spruce(4000, 0.0036, "mcl_core_spruce_huge_2.mts", {"MegaSpruceTaiga"})
	quick_spruce(6000, 0.0036, "mcl_core_spruce_huge_3.mts", {"MegaSpruceTaiga"})
	quick_spruce(6600, 0.0036, "mcl_core_spruce_huge_4.mts", {"MegaSpruceTaiga"})

	quick_spruce(3000, 0.0008, "mcl_core_spruce_huge_up_1.mts", {"MegaTaiga"})
	quick_spruce(4000, 0.0008, "mcl_core_spruce_huge_up_2.mts", {"MegaTaiga"})
	quick_spruce(6000, 0.0008, "mcl_core_spruce_huge_up_3.mts", {"MegaTaiga"})


	-- Common spruce
	quick_spruce(11000, 0.00150, "mcl_core_spruce_5.mts", {"Taiga", "ColdTaiga"})

	quick_spruce(2500, 0.00325, "mcl_core_spruce_1.mts", {"MegaSpruceTaiga", "MegaTaiga", "Taiga", "ColdTaiga"})
	quick_spruce(7000, 0.00425, "mcl_core_spruce_3.mts", {"MegaSpruceTaiga", "MegaTaiga", "Taiga", "ColdTaiga"})
	quick_spruce(9000, 0.00325, "mcl_core_spruce_4.mts", {"MegaTaiga", "Taiga", "ColdTaiga"})

	quick_spruce(9500, 0.00500, "mcl_core_spruce_tall.mts", {"MegaTaiga"})

	quick_spruce(5000, 0.00250, "mcl_core_spruce_2.mts", {"MegaSpruceTaiga", "MegaTaiga"})

	quick_spruce(11000, 0.000025, "mcl_core_spruce_5.mts", {"ExtremeHills", "ExtremeHillsM"})
	quick_spruce(2500, 0.00005, "mcl_core_spruce_1.mts", {"ExtremeHills", "ExtremeHillsM"})
	quick_spruce(7000, 0.00005, "mcl_core_spruce_3.mts", {"ExtremeHills", "ExtremeHillsM"})
	quick_spruce(9000, 0.00005, "mcl_core_spruce_4.mts", {"ExtremeHills", "ExtremeHillsM"})

	quick_spruce(11000, 0.001, "mcl_core_spruce_5.mts", {"ExtremeHills+", "ExtremeHills+_snowtop"}, 50)
	quick_spruce(2500, 0.002, "mcl_core_spruce_1.mts", {"ExtremeHills+", "ExtremeHills+_snowtop"}, 50)
	quick_spruce(7000, 0.003, "mcl_core_spruce_3.mts", {"ExtremeHills+", "ExtremeHills+_snowtop"}, 50)
	quick_spruce(9000, 0.002, "mcl_core_spruce_4.mts", {"ExtremeHills+", "ExtremeHills+_snowtop"}, 50)


	-- Small lollipop spruce
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block", "mcl_core:podzol"},
		sidelen = 16,
		noise_params = {
			offset = 0.004,
			scale = 0.0022,
			spread = {x = 250, y = 250, z = 250},
			seed = 2500,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"Taiga", "ColdTaiga"},
		y_min = 2,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_spruce_lollipop.mts",
		flags = "place_center_x, place_center_z",
	})

	-- Matchstick spruce: Very few leaves, tall trunk
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block", "mcl_core:podzol"},
		sidelen = 80,
		noise_params = {
			offset = -0.025,
			scale = 0.025,
			spread = {x = 250, y = 250, z = 250},
			seed = 2566,
			octaves = 5,
			persist = 0.60,
		},
		biomes = {"Taiga", "ColdTaiga"},
		y_min = 3,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_spruce_matchstick.mts",
		flags = "place_center_x, place_center_z",
	})

	-- Rare spruce in Ice Plains
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block"},
		sidelen = 16,
		noise_params = {
			offset = -0.00075,
			scale = -0.0015,
			spread = {x = 250, y = 250, z = 250},
			seed = 11,
			octaves = 3,
			persist = 0.7
		},
		biomes = {"IcePlains"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_spruce_5.mts",
		flags = "place_center_x, place_center_z",
	})

	-- Acacia (many variants)
	for a=1, 7 do
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"mcl_core:dirt_with_grass", "mcl_core:dirt", "mcl_core:coarse_dirt"},
			sidelen = 16,
			fill_ratio = 0.0002,
			biomes = {"Savanna", "SavannaM"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_mcl_core.."/schematics/mcl_core_acacia_"..a..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
	end

	-- Birch
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = 0.03,
			scale = 0.0025,
			spread = {x = 250, y = 250, z = 250},
			seed = 11,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"BirchForest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_birch.mts",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = 0.03,
			scale = 0.0025,
			spread = {x = 250, y = 250, z = 250},
			seed = 11,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"BirchForestM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_birch_tall.mts",
		flags = "place_center_x, place_center_z",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.000333,
			scale = -0.0015,
			spread = {x = 250, y = 250, z = 250},
			seed = 11,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"Forest", "FlowerForest"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_birch.mts",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 16,
		--[[noise_params = {
			offset = 0.01,
			scale = 0.00001,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.33
		},]]--
		fill_ratio = 0.00002,
		biomes = {"Forest", "BirchForest", "BirchForestM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_birch_bee_nest.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
		spawn_by = "group:flower",
	})

	-- Dark Oak
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = 0.05,
			scale = 0.0015,
			spread = {x = 125, y = 125, z = 125},
			seed = 223,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"RoofedForest"},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_dark_oak.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	-- Cherry
	for i=1,3 do
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"mcl_core:dirt_with_grass"},
			sidelen = 80,
			noise_params = {
				offset = 0.007,
				scale = 0.08,
				spread = {x = 250, y = 250, z = 250},
				seed = 13+i,
				octaves = 3,
				persist = 0.6
			},
			biomes = {"CherryGrove"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_cherry_blossom.."/schematics/mcl_cherry_blossom_tree_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
		minetest.register_decoration({
			deco_type = "schematic",
			place_on = {"mcl_core:dirt_with_grass"},
			sidelen = 80,
			noise_params = {
				offset = 0.0005,
				scale = 0.0001,
				spread = {x = 250, y = 250, z = 250},
				seed = 32+i,
				octaves = 3,
				persist = 0.01
			},
			biomes = {"CherryGrove"},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = mod_cherry_blossom.."/schematics/mcl_cherry_blossom_tree_beehive_"..i..".mts",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
	end


	local ratio_mushroom = 0.0001
	local ratio_mushroom_huge = ratio_mushroom * (11/12)
	local ratio_mushroom_giant = ratio_mushroom * (1/12)
	local ratio_mushroom_mycelium = 0.002
	local ratio_mushroom_mycelium_huge = ratio_mushroom_mycelium * (11/12)
	local ratio_mushroom_mycelium_giant = ratio_mushroom_mycelium * (1/12)

	-- Huge Brown Mushroom
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "group:grass_block_no_snow", "mcl_core:dirt" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_huge,
		biomes = { "RoofedForest" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_huge_brown.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "group:grass_block_no_snow", "mcl_core:dirt" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_giant,
		biomes = { "RoofedForest" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_giant_brown.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "mcl_core:mycelium" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_mycelium_huge,
		biomes = { "MushroomIsland", "MushroomIslandShore" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_huge_brown.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "mcl_core:mycelium" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_mycelium_giant,
		biomes = { "MushroomIsland", "MushroomIslandShore" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_giant_brown.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})

	-- Huge Red Mushroom
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "group:grass_block_no_snow", "mcl_core:dirt" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_huge,
		biomes = { "RoofedForest" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_huge_red.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "group:grass_block_no_snow", "mcl_core:dirt" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_giant,
		biomes = { "RoofedForest" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_giant_red.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "mcl_core:mycelium" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_mycelium_huge,
		biomes = { "MushroomIsland", "MushroomIslandShore" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_huge_red.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = { "mcl_core:mycelium" },
		sidelen = 80,
		fill_ratio = ratio_mushroom_mycelium_giant,
		biomes = { "MushroomIsland", "MushroomIslandShore" },
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_mushrooms.."/schematics/mcl_mushrooms_giant_red.mts",
		flags = "place_center_x, place_center_z",
		rotation = "0",
	})

	--Snow on snowy dirt
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:dirt_with_grass_snow"},
		sidelen = 80,
		fill_ratio = 10,
		flags = "all_floors",
		y_min = mcl_vars.mg_overworld_min,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_core:snow",
	})

	--Mushrooms in caves
	minetest.register_decoration({
		deco_type = "simple",
		place_on = table.merge(mcl_biomes.stonelike, {"mcl_deepslate:deepslate"}),
		sidelen = 80,
		fill_ratio = 0.009,
		noise_threshold = 2.0,
		flags = "all_floors",
		y_min = mcl_vars.mg_overworld_min,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_mushrooms:mushroom_red",
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = table.merge(mcl_biomes.stonelike, {"mcl_deepslate:deepslate"}),
		sidelen = 80,
		fill_ratio = 0.009,
		noise_threshold = 2.0,
		y_min = mcl_vars.mg_overworld_min,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_mushrooms:mushroom_brown",
	})

	-- Mossy cobblestone boulder (3×3)
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:podzol", "mcl_core:dirt", "mcl_core:coarse_dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.00015,
			scale = 0.001,
			spread = {x = 300, y = 300, z = 300},
			seed = 775703,
			octaves = 4,
			persist = 0.63,
		},
		biomes = {"MegaTaiga", "MegaSpruceTaiga"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_boulder.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	-- Small mossy cobblestone boulder (2×2)
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"mcl_core:podzol", "mcl_core:dirt", "mcl_core:coarse_dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.001,
			scale = 0.001,
			spread = {x = 300, y = 300, z = 300},
			seed = 775703,
			octaves = 4,
			persist = 0.63,
		},
		biomes = {"MegaTaiga", "MegaSpruceTaiga"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_structures.."/schematics/mcl_structures_boulder_small.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	})

	-- Cacti
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:sand"},
		sidelen = 16,
		noise_params = {
			offset = -0.012,
			scale = 0.024,
			spread = {x = 100, y = 100, z = 100},
			seed = 257,
			octaves = 3,
			persist = 0.6
		},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_core:cactus",
		biomes = {"Desert",
			"Mesa","Mesa_sandlevel",
			"MesaPlateauF","MesaPlateauF_sandlevel",
			"MesaPlateauFM","MesaPlateauFM_sandlevel"},
		height = 1,
		height_max = 3,
	})

	-- Sugar canes
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:dirt", "mcl_core:coarse_dirt", "group:grass_block_no_snow", "group:sand", "mcl_core:podzol", "mcl_core:reeds"},
		sidelen = 16,
		noise_params = {
			offset = -0.3,
			scale = 0.7,
			spread = {x = 200, y = 200, z = 200},
			seed = 2,
			octaves = 3,
			persist = 0.7
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_core:reeds",
		height = 1,
		height_max = 3,
		spawn_by = { "mcl_core:water_source", "group:frosted_ice" },
		num_spawn_by = 1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:dirt", "mcl_core:coarse_dirt", "group:grass_block_no_snow", "group:sand", "mcl_core:podzol", "mcl_core:reeds"},
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.5,
			spread = {x = 200, y = 200, z = 200},
			seed = 2,
			octaves = 3,
			persist = 0.7,
		},
		biomes = {"Swampland", "Swampland_shore"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_core:reeds",
		height = 1,
		height_max = 3,
		spawn_by = { "mcl_core:water_source", "group:frosted_ice" },
		num_spawn_by = 1,
	})

	-- Doubletall grass
	function mcl_biomes.register_doubletall_grass(offset, scale, biomes)

		for b=1, #biomes do
			local param2 = minetest.registered_biomes[biomes[b]]._mcl_palette_index
			minetest.register_decoration({
				deco_type = "schematic",
				schematic = {
					size = { x=1, y=3, z=1 },
					data = {
						{ name = "air", prob = 0 },
						{ name = "mcl_flowers:double_grass", param1=255, param2=param2 },
						{ name = "mcl_flowers:double_grass_top", param1=255, param2=param2 },
					},
				},
				place_on = {"group:grass_block_no_snow"},
				sidelen = 16,
				noise_params = {
					offset = offset,
					scale = scale,
					spread = {x = 200, y = 200, z = 200},
					seed = 420,
					octaves = 3,
					persist = 0.6,
				},
				y_min = 1,
				y_max = mcl_vars.mg_overworld_max,
				biomes = { biomes[b] },
			})
		end
	end

	local register_doubletall_grass = mcl_biomes.register_doubletall_grass

	register_doubletall_grass(-0.01, 0.03, {"Taiga", "Forest", "FlowerForest", "BirchForest", "BirchForestM", "RoofedForest"})
	register_doubletall_grass(-0.002, 0.03, {"Plains", "SunflowerPlains", "CherryGrove"})
	register_doubletall_grass(-0.0005, -0.03, {"Savanna", "SavannaM"})

	-- Large ferns
	function mcl_biomes.register_double_fern(offset, scale, biomes)
		for b=1, #biomes do
			local param2 = minetest.registered_biomes[biomes[b]]._mcl_palette_index
			minetest.register_decoration({
				deco_type = "schematic",
				schematic = {
					size = { x=1, y=3, z=1 },
					data = {
						{ name = "air", prob = 0 },
						{ name = "mcl_flowers:double_fern", param1=255, param2=param2 },
						{ name = "mcl_flowers:double_fern_top", param1=255, param2=param2 },
					},
				},
				place_on = {"group:grass_block_no_snow", "mcl_core:podzol"},
				sidelen = 16,
				noise_params = {
					offset = offset,
					scale = scale,
					spread = {x = 250, y = 250, z = 250},
					seed = 333,
					octaves = 2,
					persist = 0.66,
				},
				y_min = 1,
				y_max = mcl_vars.mg_overworld_max,
				biomes = biomes[b],
			})
		end
	end

	local register_double_fern = mcl_biomes.register_double_fern

	register_double_fern(0.01, 0.03, { "BambooJungle", "Jungle", "JungleM", "JungleEdge", "JungleEdgeM", "Taiga", "ColdTaiga", "MegaTaiga", "MegaSpruceTaiga" })
	register_double_fern(0.15, 0.1, { "JungleM" })

	-- Large flowers
	function mcl_biomes.register_large_flower(name, biomes, seed, offset, flower_forest_offset)
		local maxi
		if flower_forest_offset then
			maxi = 2
		else
			maxi = 1
		end
		for i=1, maxi do
			local o, b -- offset, biomes
			if i == 1 then
				o = offset
				b = biomes
			else
				o = flower_forest_offset
				b = { "FlowerForest" }
			end

			minetest.register_decoration({
				deco_type = "schematic",
				schematic = {
					size = {x = 1, y = 3, z = 1},
					data = {
						{name = "air", prob = 0},
						{name = "mcl_flowers:" .. name, param1 = 255, },
						{name = "mcl_flowers:" .. name .. "_top", param1 = 255, },
					},
				},
				place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},

				sidelen = 16,
				noise_params = {
					offset = o,
					scale = 0.01,
					spread = {x = 300, y = 300, z = 300},
					seed = seed,
					octaves = 5,
					persist = 0.62,
				},
				y_min = 1,
				y_max = mcl_vars.mg_overworld_max,
				flags = "",
				biomes = b,
			})
		end
	end

	local register_large_flower = mcl_biomes.register_large_flower

	register_large_flower("rose_bush", {"Forest"}, 9350, -0.008, 0.003)
	register_large_flower("peony", {"Forest"}, 10450, -0.008, 0.003)
	register_large_flower("lilac", {"Forest"}, 10600, -0.007, 0.003)
	register_large_flower("sunflower", {"SunflowerPlains"}, 2940, 0.01)

	-- Jungle bush

	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.0196,
			scale = 0.015,
			spread = {x = 250, y = 250, z = 250},
			seed = 2930,
			octaves = 4,
			persist = 0.6,
		},
		biomes = {"Jungle"},
		y_min = 3,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_bush_oak_leaves.mts",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.0196,
			scale = 0.005,
			spread = {x = 250, y = 250, z = 250},
			seed = 2930,
			octaves = 4,
			persist = 0.6,
		},
		biomes = {"Jungle"},
		y_min = 3,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_bush_oak_leaves_2.mts",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.05,
			scale = 0.025,
			spread = {x = 250, y = 250, z = 250},
			seed = 2930,
			octaves = 4,
			persist = 0.6,
		},
		biomes = {"JungleM"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_bush_oak_leaves.mts",
		flags = "place_center_x, place_center_z",
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
		sidelen = 80,
		noise_params = {
			offset = 0.0085,
			scale = 0.025,
			spread = {x = 250, y = 250, z = 250},
			seed = 2930,
			octaves = 4,
			persist = 0.6,
		},
		biomes = { "BambooJungle", "JungleEdge", "JungleEdgeM"},
		y_min = 3,
		y_max = mcl_vars.mg_overworld_max,
		schematic = mod_mcl_core.."/schematics/mcl_core_jungle_bush_oak_leaves.mts",
		flags = "place_center_x, place_center_z",
	})

	-- Lily pad

	local lily_schem = {
		{ name = "mcl_core:water_source" },
		{ name = "mcl_flowers:waterlily" },
	}

	-- Spawn them in shallow water at ocean level in Swampland.
	-- Tweak lilydepth to change the maximum water depth
	local lilydepth = 2

	for d=1, lilydepth do
		local height = d + 2
		local y = 1 - d
		table.insert(lily_schem, 1, { name = "air", prob = 0 })

		minetest.register_decoration({
			deco_type = "schematic",
			schematic = {
				size = { x=1, y=height, z=1 },
				data = lily_schem,
			},
			place_on = "mcl_core:dirt",
			sidelen = 16,
			noise_params = {
				offset = 0,
				scale = 0.3,
				spread = {x = 100, y = 100, z = 100},
				seed = 503,
				octaves = 6,
				persist = 0.7,
			},
			y_min = y,
			y_max = y,
			biomes = { "Swampland_shore" },
			rotation = "random",
		})
	end

	-- Melon
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = -0.01,
			scale = 0.006,
			spread = {x = 250, y = 250, z = 250},
			seed = 333,
			octaves = 3,
			persist = 0.6
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_farming:melon",
		biomes = { "Jungle" },
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.006,
			spread = {x = 250, y = 250, z = 250},
			seed = 333,
			octaves = 3,
			persist = 0.6
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_farming:melon",
		biomes = { "JungleM" },
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = -0.005,
			scale = 0.006,
			spread = {x = 250, y = 250, z = 250},
			seed = 333,
			octaves = 3,
			persist = 0.6
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_farming:melon",
		biomes = { "BambooJungle", "JungleEdge", "JungleEdgeM" },
	})

	-- Lots of melons in Jungle Edge M
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:grass_block_no_snow"},
		sidelen = 80,
		noise_params = {
			offset = 0.013,
			scale = 0.006,
			spread = {x = 125, y = 125, z = 125},
			seed = 333,
			octaves = 3,
			persist = 0.6
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_farming:melon",
		biomes = { "JungleEdgeM" },
	})

	-- Pumpkin
	minetest.register_decoration({
		deco_type = "simple",
		decoration = "mcl_farming:pumpkin",
		param2 = 0,
		param2_max = 3,
		place_on = {"group:grass_block_no_snow"},
		sidelen = 16,
		noise_params = {
			offset = -0.016,
			scale = 0.01332,
			spread = {x = 125, y = 125, z = 125},
			seed = 666,
			octaves = 6,
			persist = 0.666
		},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
	})

	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"mcl_core:dirt_with_grass"},
		fill_ratio = 0.6,
		biomes = {"CherryGrove"},
		y_min = mcl_vars.mg_overworld_min,
		y_max = mcl_vars.mg_overworld_max,
		decoration = "mcl_cherry_blossom:pink_petals",
	})

	-- Grasses and ferns
	local grass_forest = {"Plains", "Taiga", "Forest", "FlowerForest", "BirchForest", "BirchForestM", "RoofedForest", "Swampland" }
	local grass_mpf = {"MesaPlateauF_grasstop"}
	local grass_plains = {"Plains", "SunflowerPlains", "BambooJungle", "JungleEdge", "JungleEdgeM", "MangroveSwamp", "CherryGrove" }
	local grass_savanna = {"Savanna", "SavannaM"}
	local grass_sparse = {"ExtremeHills", "ExtremeHills+", "ExtremeHills+_snowtop", "ExtremeHillsM", "Jungle" }
	local grass_mpfm = {"MesaPlateauFM_grasstop" }

	register_grass_decoration("tallgrass", -0.03,  0.09, grass_forest)
	register_grass_decoration("tallgrass", -0.015, 0.075, grass_forest)
	register_grass_decoration("tallgrass", 0,      0.06, grass_forest)
	register_grass_decoration("tallgrass", 0.015,  0.045, grass_forest)
	register_grass_decoration("tallgrass", 0.03,   0.03, grass_forest)
	register_grass_decoration("tallgrass", -0.03, 0.09, grass_mpf)
	register_grass_decoration("tallgrass", -0.015, 0.075, grass_mpf)
	register_grass_decoration("tallgrass", 0, 0.06, grass_mpf)
	register_grass_decoration("tallgrass", 0.01, 0.045, grass_mpf)
	register_grass_decoration("tallgrass", 0.01, 0.05, grass_forest)
	register_grass_decoration("tallgrass", 0.03, 0.03, grass_plains)
	register_grass_decoration("tallgrass", 0.05, 0.01, grass_plains)
	register_grass_decoration("tallgrass", 0.07, -0.01, grass_plains)
	register_grass_decoration("tallgrass", 0.09, -0.03, grass_plains)
	register_grass_decoration("tallgrass", 0.18, -0.03, grass_savanna)
	register_grass_decoration("tallgrass", 0.05, -0.03, grass_sparse)
	register_grass_decoration("tallgrass", 0.05, 0.05, grass_mpfm)

	local fern_minimal = { "Jungle", "JungleM", "BambooJungle", "JungleEdge", "JungleEdgeM", "Taiga", "MegaTaiga", "MegaSpruceTaiga", "ColdTaiga", "MangroveSwamp" }
	local fern_low = { "Jungle", "JungleM", "BambooJungle", "JungleEdge", "JungleEdgeM", "Taiga", "MegaTaiga", "MegaSpruceTaiga" }
	local fern_Jungle = { "Jungle", "JungleM", "BambooJungle", "JungleEdge", "JungleEdgeM" }
	--local fern_JungleM = { "JungleM" },

	register_grass_decoration("fern", -0.03,  0.09, fern_minimal)
	register_grass_decoration("fern", -0.015, 0.075, fern_minimal)
	register_grass_decoration("fern", 0,      0.06, fern_minimal)
	register_grass_decoration("fern", 0.015,  0.045, fern_low)
	register_grass_decoration("fern", 0.03,   0.03, fern_low)
	register_grass_decoration("fern", 0.01, 0.05, fern_Jungle)
	register_grass_decoration("fern", 0.03, 0.03, fern_Jungle)
	register_grass_decoration("fern", 0.05, 0.01, fern_Jungle)
	register_grass_decoration("fern", 0.07, -0.01, fern_Jungle)
	register_grass_decoration("fern", 0.09, -0.03, fern_Jungle)
	register_grass_decoration("fern", 0.12, -0.03, {"JungleM"})

	local b_seagrass = {"ColdTaiga_ocean","ExtremeHills_ocean","ExtremeHillsM_ocean","ExtremeHills+_ocean","Taiga_ocean","MegaTaiga_ocean","MegaSpruceTaiga_ocean","StoneBeach_ocean","Plains_ocean","SunflowerPlains_ocean","Forest_ocean","FlowerForest_ocean","BirchForest_ocean","BirchForestM_ocean","RoofedForest_ocean","Swampland_ocean","Jungle_ocean","JungleM_ocean","BambooJungle_ocean", "JungleEdge_ocean","JungleEdgeM_ocean","MushroomIsland_ocean","Desert_ocean","Savanna_ocean","SavannaM_ocean","Mesa_ocean","MesaBryce_ocean","MesaPlateauF_ocean","MesaPlateauFM_ocean",
"ColdTaiga_deep_ocean","ExtremeHills_deep_ocean","ExtremeHillsM_deep_ocean","ExtremeHills+_deep_ocean","Taiga_deep_ocean","MegaTaiga_deep_ocean","MegaSpruceTaiga_deep_ocean","StoneBeach_deep_ocean","Plains_deep_ocean","SunflowerPlains_deep_ocean","Forest_deep_ocean","FlowerForest_deep_ocean","BirchForest_deep_ocean","BirchForestM_deep_ocean","RoofedForest_deep_ocean","Swampland_deep_ocean","Jungle_deep_ocean","JungleM_deep_ocean","JungleEdge_deep_ocean","JungleEdgeM_deep_ocean","MushroomIsland_deep_ocean","Desert_deep_ocean","Savanna_deep_ocean","SavannaM_deep_ocean","Mesa_deep_ocean","MesaBryce_deep_ocean","MesaPlateauF_deep_ocean","MesaPlateauFM_deep_ocean",
"Mesa_sandlevel","MesaBryce_sandlevel","MesaPlateauF_sandlevel","MesaPlateauFM_sandlevel","Swampland_shore","Jungle_shore","JungleM_shore","Savanna_beach","FlowerForest_beach","ColdTaiga_beach_water","ExtremeHills_beach"}
	local b_kelp = {"ExtremeHillsM_ocean","ExtremeHills+_ocean","MegaTaiga_ocean","MegaSpruceTaiga_ocean","Plains_ocean","SunflowerPlains_ocean","Forest_ocean","FlowerForest_ocean","BirchForest_ocean","BirchForestM_ocean","RoofedForest_ocean","Swampland_ocean","Jungle_ocean","JungleM_ocean","JungleEdge_ocean","JungleEdgeM_ocean","MushroomIsland_ocean","BambooJungle_ocean",
"ExtremeHillsM_deep_ocean","ExtremeHills+_deep_ocean","MegaTaiga_deep_ocean","MegaSpruceTaiga_deep_ocean","Plains_deep_ocean","SunflowerPlains_deep_ocean","Forest_deep_ocean","FlowerForest_deep_ocean","BirchForest_deep_ocean","BirchForestM_deep_ocean","RoofedForest_deep_ocean","Swampland_deep_ocean","Jungle_deep_ocean","JungleM_deep_ocean","JungleEdge_deep_ocean","JungleEdgeM_deep_ocean","MushroomIsland_deep_ocean"
}

	register_seagrass_decoration("seagrass", 0, 0.5, b_seagrass)
	register_seagrass_decoration("kelp", -0.5, 1, b_kelp)

	-- Place tall grass on snow in Ice Plains and Extreme Hills+
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block"},
		sidelen = 16,
		noise_params = {
			offset = -0.08,
			scale = 0.09,
			spread = {x = 15, y = 15, z = 15},
			seed = 420,
			octaves = 3,
			persist = 0.6,
		},
		biomes = {"IcePlains"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = {
			size = { x=1, y=2, z=1 },
			data = {
				{ name = "mcl_core:dirt_with_grass", force_place=true, },
				{ name = "mcl_flowers:tallgrass", param2 = minetest.registered_biomes["IcePlains"]._mcl_palette_index },
			},
		},
	})
	minetest.register_decoration({
		deco_type = "schematic",
		place_on = {"group:grass_block"},
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.09,
			spread = {x = 15, y = 15, z = 15},
			seed = 420,
			octaves = 3,
			persist = 0.6,
		},
		biomes = {"ExtremeHills+_snowtop"},
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		schematic = {
			size = { x=1, y=2, z=1 },
			data = {
				{ name = "mcl_core:dirt_with_grass", force_place=true, },
				{ name = "mcl_flowers:tallgrass", param2 = minetest.registered_biomes["ExtremeHills+_snowtop"]._mcl_palette_index },
			},
		},
	})


	-- Dead bushes
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:sand", "mcl_core:podzol", "mcl_core:dirt", "mcl_core:dirt_with_grass", "mcl_core:coarse_dirt", "group:hardened_clay"},
		sidelen = 16,
		noise_params = {
			offset = 0.0,
			scale = 0.035,
			spread = {x = 100, y = 100, z = 100},
			seed = 1972,
			octaves = 3,
			persist = 0.6
		},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		biomes = {"Desert", "Mesa", "Mesa_sandlevel", "MesaPlateauF", "MesaPlateauF_sandlevel", "MesaPlateauF_grasstop","MesaBryce", "MegaTaiga", "MegaSpruceTaiga"},
		decoration = "mcl_core:deadbush",
		height = 1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:sand", "mcl_core:dirt", "mcl_core:dirt_with_grass", "mcl_core:coarse_dirt"},
		sidelen = 16,
		noise_params = {
			offset = 0.1,
			scale = 0.035,
			spread = {x = 100, y = 100, z = 100},
			seed = 1972,
			octaves = 3,
			persist = 0.6
		},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		biomes = {"MesaPlateauFM_grasstop"},
		decoration = "mcl_core:deadbush",
		height = 1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:sand"},
		sidelen = 16,
		noise_params = {
			offset = 0.045,
			scale = 0.055,
			spread = {x = 100, y = 100, z = 100},
			seed = 1972,
			octaves = 3,
			persist = 0.6
		},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		biomes = {"MesaPlateauFM","MesaPlateauFM_sandlevel"},
		decoration = "mcl_core:deadbush",
		height = 1,
	})
	minetest.register_decoration({
		deco_type = "simple",
		place_on = {"group:hardened_clay"},
		sidelen = 16,
		noise_params = {
			offset = 0.010,
			scale = 0.035,
			spread = {x = 100, y = 100, z = 100},
			seed = 1972,
			octaves = 3,
			persist = 0.6
		},
		y_min = 4,
		y_max = mcl_vars.mg_overworld_max,
		biomes = {"MesaPlateauFM", "MesaPlateauFM_sandlevel", "MesaPlateauFM_grasstop"},
		decoration = "mcl_core:deadbush",
		height = 1,
	})


	-- Small Mushrooms
	local mushrooms = {"mcl_mushrooms:mushroom_red", "mcl_mushrooms:mushroom_brown"}
	local mseeds = { 7133, 8244 }
	for m=1, #mushrooms do
		-- Mushrooms in mushroom biome
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"mcl_core:mycelium"},
			sidelen = 80,
			fill_ratio = 0.009,
			biomes = {"MushroomIsland", "MushroomIslandShore"},
			noise_threshold = 2.0,
			y_min = mcl_vars.mg_overworld_min,
			y_max = mcl_vars.mg_overworld_max,
			decoration = mushrooms[m],
		})
		-- Mushrooms in Taiga
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"mcl_core:podzol"},
			sidelen = 80,
			fill_ratio = 0.003,
			biomes = {"MegaTaiga", "MegaSpruceTaiga"},
			y_min = mcl_vars.mg_overworld_min,
			y_max = mcl_vars.mg_overworld_max,
			decoration = mushrooms[m],
		})
		-- Mushrooms next to trees
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_core:podzol", "mcl_core:mycelium", "mcl_core:stone", "mcl_core:andesite", "mcl_core:diorite", "mcl_core:granite"},
			sidelen = 16,
			noise_params = {
				offset = 0,
				scale = 0.003,
				spread = {x = 250, y = 250, z = 250},
				seed = mseeds[m],
				octaves = 3,
				persist = 0.66,
			},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			decoration = mushrooms[m],
			spawn_by = { "mcl_trees:tree_oak", "mcl_trees:tree_spruce", "mcl_trees:tree_dark_oak", "mcl_trees:tree_birch" },
			num_spawn_by = 1,
		})

		-- More mushrooms in Swampland
		minetest.register_decoration({
			deco_type = "simple",
			place_on = {"group:grass_block_no_snow", "mcl_core:dirt", "mcl_core:podzol", "mcl_core:mycelium", "mcl_core:stone", "mcl_core:andesite", "mcl_core:diorite", "mcl_core:granite"},
			sidelen = 16,
			noise_params = {
				offset = 0.05,
				scale = 0.003,
				spread = {x = 250, y = 250, z = 250},
				seed = mseeds[m],
				octaves = 3,
				persist = 0.6,
			},
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			decoration = mushrooms[m],
			biomes = { "Swampland"},
			spawn_by = { "mcl_trees:tree_oak", "mcl_trees:tree_spruce", "mcl_trees:tree_dark_oak", "mcl_trees:tree_birch" },
			num_spawn_by = 1,
		})
	end

	function mcl_biomes.register_flower(name, biomes, seed, is_in_flower_forest)
		if is_in_flower_forest == nil then
			is_in_flower_forest = true
		end
		if biomes then
			minetest.register_decoration({
				deco_type = "simple",
				place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
				sidelen = 16,
				noise_params = {
					offset = 0.0008,
					scale = 0.006,
					spread = {x = 100, y = 100, z = 100},
					seed = seed,
					octaves = 3,
					persist = 0.6
				},
				y_min = 1,
				y_max = mcl_vars.mg_overworld_max,
				biomes = biomes,
				decoration = "mcl_flowers:"..name,
			})
		end
		if is_in_flower_forest then
			minetest.register_decoration({
				deco_type = "simple",
				place_on = {"group:grass_block_no_snow", "mcl_core:dirt"},
				sidelen = 80,
				noise_params= {
					offset = 0.0008*40,
					scale = 0.003,
					spread = {x = 100, y = 100, z = 100},
					seed = seed,
					octaves = 3,
					persist = 0.6,
				},
				y_min = 1,
				y_max = mcl_vars.mg_overworld_max,
				biomes = {"FlowerForest"},
				decoration = "mcl_flowers:"..name,
			})
		end
	end

	local register_flower = mcl_biomes.register_flower

	local flower_biomes1 = {"Plains", "SunflowerPlains", "RoofedForest", "Forest", "BirchForest", "BirchForestM", "Taiga", "ColdTaiga", "Jungle", "JungleM", "BambooJungle", "JungleEdge", "JungleEdgeM", "Savanna", "SavannaM", "ExtremeHills", "ExtremeHillsM", "ExtremeHills+", "ExtremeHills+_snowtop", "CherryGrove" }

	register_flower("dandelion", flower_biomes1, 8)
	register_flower("poppy", flower_biomes1, 9439)

	local flower_biomes2 = {"Plains", "SunflowerPlains"}
	register_flower("tulip_red", flower_biomes2, 436)
	register_flower("tulip_orange", flower_biomes2, 536)
	register_flower("tulip_pink", flower_biomes2, 636)
	register_flower("tulip_white", flower_biomes2, 736)
	register_flower("azure_bluet", flower_biomes2, 800)
	register_flower("oxeye_daisy", flower_biomes2, 3490)

	register_flower("allium", nil, 0) -- flower Forest only
	register_flower("blue_orchid", {"Swampland"}, 64500, false)

	register_flower("lily_of_the_valley", nil, 325)
	register_flower("cornflower", flower_biomes2, 486)
end
