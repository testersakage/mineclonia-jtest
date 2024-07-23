--local beach_skycolor = "#78A7FF" -- This is the case for all beach biomes except for the snowy ones! Those beaches will have their own colour instead of this one.
local ocean_skycolor = "#7BA4FF" -- This is the case for all ocean biomes except for non-deep frozen oceans! Those oceans will have their own colour instead of this one.
local overworld_fogcolor = "#C0D8FF"
local mg_seed = minetest.get_mapgen_setting("seed")


--[[ Special biome field: _mcl_biome_type:
Rough categorization of biomes: One of "snowy", "cold", "medium" and "hot"
Based off <https://minecraft.gamepedia.com/Biomes> ]]

function mcl_biomes.register_classic_superflat_biome()
	-- Classic Superflat: bedrock (not part of biome), 2 dirt, 1 grass block
	minetest.register_biome({
		name = "flat",
		node_top = "mcl_core:dirt_with_grass",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 3,
		node_stone = "mcl_core:dirt",
		y_min = mcl_vars.mg_overworld_min - 512,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = 50,
		heat_point = 50,
		_mcl_biome_type = "medium",
		_mcl_palette_index = 0,
		_mcl_skycolor = "#78A7FF",
		_mcl_fogcolor = overworld_fogcolor
	})
end

local tpl_biome = {}
local tpl_beach = {}
local tpl_ocean = table.merge(tpl_biome, {
	y_min = mcl_vars.mg_ocean_min,
	y_max = mcl_vars.mg_ocean_max,
})
local tpl_deep_ocean = table.merge(tpl_biome, {
	y_min = mcl_vars.mg_ocean_deep_min,
	y_max = mcl_vars.mg_ocean_deep_max,
	depth_top = 2,
	depth_filler = 3,
	depth_riverbed = 2,
	vertical_blend = 5,
	_mcl_skycolor = ocean_skycolor,
	_mcl_fogcolor = overworld_fogcolor
})
local tpl_underground = table.merge(tpl_biome, {
	y_min = mcl_vars.mg_overworld_min_old,
	y_max = mcl_vars.mg_ocean_deep_min - 1,
})
local tpl_deep_underground = table.merge(tpl_biome, {
	node_stone = "mcl_deepslate:deepslate",
	y_min = mcl_vars.mg_overworld_min,
	y_max = mcl_vars.mg_overworld_min_old,
})

function mcl_biomes.register_biomestack(name, def)
	local ocean = {
		node_top = (def.ocean or def.biome).node_top,
		node_filler = (def.ocean or def.biome).node_filler,
		node_riverbed = (def.ocean or def.biome).node_riverbed,
	}
	local def_copy =table.copy(def.biome)
	def_copy.node_top = nil
	minetest.register_biome(table.merge(def.biome, { name = name }))
	minetest.register_biome(table.merge(def_copy, tpl_ocean, ocean, def.ocean or {}, { name = name.."_ocean" }))
	minetest.register_biome(table.merge(def_copy, tpl_deep_ocean, ocean, def.deep_ocean or {}, { name = name.."_deep_ocean" }))
	minetest.register_biome(table.merge(def_copy, tpl_underground, def.underground or {}, { name = name.."_underground" }))
	minetest.register_biome(table.merge(def_copy, tpl_deep_underground, def.deep_underground or {}, { name = name.."_deep_underground" }))
	if def.beach then
		minetest.register_biome(table.merge(def.biome, tpl_beach, def.beach or {}, { name = name.."_beach" }))
	end
end

function mcl_biomes.register_cavebiome(name, groundcover, def, ceiling, place_on)
	def.name = def.name or name
	local flags = "all_floors"
	if ceiling then
		flags = flags..", all_ceilings"
	end
	minetest.register_biome(def)
	minetest.register_decoration({
		deco_type = "simple",
		place_on = place_on or { def.node_top, def.node_dust },
		sidelen = 16,
		fill_ratio = 10,
		biomes = { name },
		y_min = def.y_min or mcl_vars.mg_overworld_min,
		y_max = def.y_max or mcl_vars.mg_overworld_min_old,
		decoration = groundcover,
		flags = flags,
		param2 = 0,
	})
end

-- All mapgens except flat and singlenode
function mcl_biomes.register_biomes()
	--[[ OVERWORLD ]]

	--[[ These biomes try to resemble MC as good as possible. This means especially the floor cover and
	the type of plants and structures (shapes might differ). The terrain itself will be of course different
	and depends on the mapgen.
	Important: MC also takes the terrain into account while MT biomes don't care about the terrain at all
	(except height).
	MC has many “M” and “Hills” variants, most of which only differ in terrain compared to their original
	counterpart.
	In MT, any biome can occour in any terrain, so these variants are implied and are therefore
	not explicitly implmented in MCL2. “M” variants are only included if they have another unique feature,
	such as a different land cover.
	In MCL2, the MC Overworld biomes are split in multiple more parts (stacked by height):
	* The main part, this represents the land. It begins at around sea level and usually goes all the way up
	* _ocean: For the area covered by ocean water. The y_max may vary for various beach effects.
			  Has sand or dirt as floor.
	* _deep_ocean: Like _ocean, but deeper and has gravel as floor
	* _underground:
	* Other modifiers: Some complex biomes require more layers to improve the landscape.

	The following naming conventions apply:
	* The land biome name is equal to the MC biome name, as of Minecraft 1.11 (in camel case)
	* Height modifiers and sub-biomes are appended with underscores and in lowercase. Example: “_ocean”
	* Non-MC biomes are written in lowercase
	* MC dimension biomes are named after their MC dimension

	Intentionally missing biomes:
	* River (generated by valleys and v7)
	* Frozen River (generated by valleys and v7)
	* Hills biomes (shape only)
	* Plateau (shape only)
	* Plateau M (shape only)
	* Cold Taiga M (mountain only)
	* Taiga M (mountain only)
	* Roofed Forest M (mountain only)
	* Swampland M (mountain only)
	* Extreme Hills Edge (unused in MC)

	TODO:
	* Better beaches
	* Improve Extreme Hills M
	* Desert M

	]]

	mcl_biomes.register_biomestack("IcePlainsSpikes",{
		biome = {
			node_top = "mcl_core:snowblock",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_water_top = "mcl_core:ice",
			depth_water_top = 1,
			node_river_water = "mcl_core:ice",
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 24,
			heat_point = -5,
			_mcl_biome_type = "snowy",
			_mcl_palette_index = 2,
			_mcl_skycolor = "#7FA1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			node_filler = "mcl_core:gravel",
			node_river_water = "mcl_core:ice",
			node_riverbed = "mcl_core:sand",
		}
	})

	mcl_biomes.register_biomestack("ColdTaiga",{
		biome = {
			node_dust = "mcl_core:snow",
			node_top = "mcl_core:dirt_with_grass_snow",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 3,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 58,
			heat_point = 8,
			_mcl_biome_type = "snowy",
			_mcl_palette_index = 3,
			_mcl_skycolor = "#839EFF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			node_riverbed = "mcl_core:sand",
			y_max = -5,
		},
		beach = {
			node_dust = "mcl_core:snow",
			node_top = "mcl_core:sand",
			depth_top = 2,
			node_water_top = "mcl_core:ice",
			depth_water_top = 1,
			node_filler = "mcl_core:sandstone",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = 2,
		},
	})

	-- Water part of the beach. Added to prevent snow being on the ice.
	minetest.register_biome({
		name = "ColdTaiga_beach_water",
		node_top = "mcl_core:sand",
		depth_top = 2,
		node_water_top = "mcl_core:ice",
		depth_water_top = 1,
		node_filler = "mcl_core:sandstone",
		depth_filler = 2,
		node_riverbed = "mcl_core:sand",
		depth_riverbed = 2,
		y_min = -4,
		y_max = 0,
		humidity_point = 58,
		heat_point = 8,
		_mcl_biome_type = "snowy",
		_mcl_palette_index = 3,
		_mcl_skycolor = "#7FA1FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	mcl_biomes.register_biomestack("MegaTaiga",{
		biome = {
			node_top = "mcl_core:podzol",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 76,
			heat_point = 10,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 4,
			_mcl_skycolor = "#7CA3FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
		},
	})

	mcl_biomes.register_biomestack("MegaSpruceTaiga",{
		biome = {
			node_top = "mcl_core:podzol",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 100,
			heat_point = 8,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 5,
			_mcl_skycolor = "#7DA3FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			node_riverbed = "mcl_core:sand",
		}
	})

	mcl_biomes.register_biomestack("ExtremeHills",{
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 4,
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 10,
			heat_point = 45,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 6,
			_mcl_skycolor = "#7DA2FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 4,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -5,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 2,
			depth_water_top = 1,
			node_filler = "mcl_core:sandstone",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 4,
			y_min = -4,
			y_max = 3,
		}
	})

	mcl_biomes.register_biomestack("ExtremeHillsM",{
		biome = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:gravel",
			depth_riverbed = 3,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 0,
			heat_point = 25,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 7,
			_mcl_skycolor = "#7DA2FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 3,
		},
	})
	mcl_biomes.register_biomestack("ExtremeHills+",{
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 4,
			y_min = 1,
			y_max = 41,
			humidity_point = 24,
			heat_point = 25,
			vertical_blend = 6,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 8,
			_mcl_skycolor = "#7DA2FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 4,
		},
	})
	---- Sub-biome for Extreme Hills+ for those snow forests
	minetest.register_biome({
		name = "ExtremeHills+_snowtop",
		node_dust = "mcl_core:snow",
		node_top = "mcl_core:dirt_with_grass_snow",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 4,
		node_river_water = "mcl_core:ice",
		node_riverbed = "mcl_core:sand",
		depth_riverbed = 4,
		y_min = 42,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = 24,
		heat_point = 25,
		_mcl_biome_type = "cold",
		_mcl_palette_index = 8,
		_mcl_skycolor = "#7DA2FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	mcl_biomes.register_biomestack("StoneBeach",{
		biome = {
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 1,
			y_min = -7,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 0,
			heat_point = 8,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 9,
			_mcl_skycolor = "#7DA2FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 1,
			y_max = -8,
			vertical_blend = 2,
		}
	})

	mcl_biomes.register_biomestack("IcePlains",{
		biome = {
			node_dust = "mcl_core:snow",
			node_top = "mcl_core:dirt_with_grass_snow",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_water_top = "mcl_core:ice",
			depth_water_top = 2,
			node_river_water = "mcl_core:ice",
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 24,
			heat_point = 8,
			_mcl_biome_type = "snowy",
			_mcl_palette_index = 10,
			_mcl_skycolor = "#7FA1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		}
	})

	mcl_biomes.register_biomestack("Plains", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 3,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 39,
			heat_point = 58,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 0,
			_mcl_skycolor = "#78A7FF",
			_mcl_fogcolor = overworld_fogcolor,
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_max = -1,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 2,
			node_filler = "mcl_core:sandstone",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 0,
			y_max = 2,
		}
	})

	minetest.register_biome({
		name = "CherryGrove",
		node_top = "mcl_core:dirt_with_grass",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 2,
		node_riverbed = "mcl_core:sand",
		depth_riverbed = 2,
		y_min = 18,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = 41,
		heat_point = 55,
		_mcl_biome_type = "medium",
		_mcl_palette_index = 11,
		_mcl_skycolor = "#78A7FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	mcl_biomes.register_biomestack("SunflowerPlains", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 28,
			heat_point = 45,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 11,
			_mcl_skycolor = "#78A7FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:dirt",
			depth_riverbed = 2,
		}
	})

	mcl_biomes.register_biomestack("Taiga", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 58,
			heat_point = 22,
			_mcl_biome_type = "cold",
			_mcl_palette_index = 12,
			_mcl_skycolor = "#7DA3FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 2,
			node_filler = "mcl_core:sandstone",
			depth_filler = 1,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = 3,
		},
	})

	mcl_biomes.register_biomestack("Forest", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 61,
			heat_point = 45,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 13,
			_mcl_skycolor = "#79A6FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -2,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 2,
			node_filler = "mcl_core:sandstone",
			depth_filler = 1,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -1,
			y_max = 0,
		}
	})

	mcl_biomes.register_biomestack("FlowerForest", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 3,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 44,
			heat_point = 32,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 14,
			_mcl_skycolor = "#79A6FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -3,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 2,
			node_filler = "mcl_core:sandstone",
			depth_filler = 1,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -2,
			y_max = 2,
		}
	})

	mcl_biomes.register_biomestack("BirchForest", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 78,
			heat_point = 31,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 15,
			_mcl_skycolor = "#7AA5FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
	})

	mcl_biomes.register_biomestack("BirchForestM", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 77,
			heat_point = 27,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 16,
			_mcl_skycolor = "#7AA5FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		}
	})

	mcl_biomes.register_biomestack("Desert", {
		biome = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			node_stone = "mcl_core:sandstone",
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 26,
			heat_point = 94,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 17,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		}
	})

	mcl_biomes.register_biomestack("RoofedForest", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 94,
			heat_point = 27,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 18,
			_mcl_skycolor = "#79A6FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
	})

	mcl_biomes.register_biomestack("Mesa", {
		biome = {
			node_top = "mcl_colorblocks:hardened_clay",
			depth_top = 1,
			node_filler = "mcl_colorblocks:hardened_clay",
			node_riverbed = "mcl_core:redsand",
			depth_riverbed = 1,
			node_stone = "mcl_colorblocks:hardened_clay",
			y_min = 11,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 0,
			heat_point = 100,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 19,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 3,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -5,
			vertical_blend = 1,
		}
	})
	-- Helper biome for the red sand at the bottom of Mesas.
	minetest.register_biome({
		name = "Mesa_sandlevel",
		node_top = "mcl_core:redsand",
		depth_top = 1,
		node_filler = "mcl_colorblocks:hardened_clay_orange",
		depth_filler = 3,
		node_riverbed = "mcl_core:redsand",
		depth_riverbed = 1,
		node_stone = "mcl_colorblocks:hardened_clay_orange",
		y_min = -4,
		y_max = 10,
		humidity_point = 0,
		heat_point = 100,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 19,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	-- Mesa Bryce: Variant of Mesa, but with perfect strata and a much smaller red sand desert
	mcl_biomes.register_biomestack("MesaBryce", {
		biome = {
			node_top = "mcl_colorblocks:hardened_clay",
			depth_top = 1,
			node_filler = "mcl_colorblocks:hardened_clay",
			node_riverbed = "mcl_colorblocks:hardened_clay",
			depth_riverbed = 1,
			node_stone = "mcl_colorblocks:hardened_clay",
			y_min = 4,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = -5,
			heat_point = 100,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 20,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 3,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -5,
			vertical_blend = 1,
		},
	})
	minetest.register_biome({
		name = "MesaBryce_sandlevel",
		node_top = "mcl_core:redsand",
		depth_top = 1,
		node_filler = "mcl_colorblocks:hardened_clay_orange",
		depth_filler = 3,
		node_riverbed = "mcl_colorblocks:hardened_clay",
		depth_riverbed = 1,
		node_stone = "mcl_colorblocks:hardened_clay_orange",
		y_min = -4,
		y_max = 3,
		humidity_point = -5,
		heat_point = 100,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 20,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	-- Mesa Plateau F
	-- Identical to Mesa below Y=30. At Y=30 and above there is a "dry" oak forest
	mcl_biomes.register_biomestack("MesaPlateauF", {
		biome = {
			node_top = "mcl_colorblocks:hardened_clay",
			depth_top = 1,
			node_filler = "mcl_colorblocks:hardened_clay",
			node_riverbed = "mcl_core:redsand",
			depth_riverbed = 1,
			node_stone = "mcl_colorblocks:hardened_clay",
			y_min = 11,
			y_max = 29,
			humidity_point = 0,
			heat_point = 60,
			vertical_blend = 0, -- we want a sharp transition
			_mcl_biome_type = "hot",
			_mcl_palette_index = 21,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 3,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -6,
			vertical_blend = 1,
		},
	})
	-- The oak forest plateau of this biome.
	-- This is a plateau for grass blocks, dry shrubs, tall grass, coarse dirt and oaks.
	-- Strata don't generate here.
	minetest.register_biome({
		name = "MesaPlateauF_grasstop",
		node_top = "mcl_core:dirt_with_grass",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 1,
		node_riverbed = "mcl_core:redsand",
		depth_riverbed = 1,
		node_stone = "mcl_colorblocks:hardened_clay",
		y_min = 30,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = 0,
		heat_point = 60,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 21,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})
	minetest.register_biome({
		name = "MesaPlateauF_sandlevel",
		node_top = "mcl_core:redsand",
		depth_top = 2,
		node_filler = "mcl_colorblocks:hardened_clay_orange",
		depth_filler = 3,
		node_riverbed = "mcl_core:redsand",
		depth_riverbed = 1,
		node_stone = "mcl_colorblocks:hardened_clay_orange",
		y_min = -5,
		y_max = 10,
		humidity_point = 0,
		heat_point = 60,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 21,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	-- Mesa Plateau FM
	-- Dryer and more "chaotic"/"weathered down" variant of MesaPlateauF:
	-- oak forest is less dense, more coarse dirt, more erratic terrain, vertical blend, more red sand layers,
	-- red sand as ores, red sandstone at sandlevel
	mcl_biomes.register_biomestack("MesaPlateauFM", {
		biome = {
			node_top = "mcl_colorblocks:hardened_clay",
			depth_top = 1,
			node_filler = "mcl_colorblocks:hardened_clay",
			node_riverbed = "mcl_core:redsand",
			depth_riverbed = 2,
			node_stone = "mcl_colorblocks:hardened_clay",
			y_min = 12,
			y_max = 29,
			humidity_point = -5,
			heat_point = 60,
			vertical_blend = 5,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 22,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 3,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 3,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -8,
			vertical_blend = 2,
		},
	})
	-- Grass plateau
	minetest.register_biome({
		name = "MesaPlateauFM_grasstop",
		node_top = "mcl_core:dirt_with_grass",
		depth_top = 1,
		node_filler = "mcl_core:coarse_dirt",
		depth_filler = 2,
		node_riverbed = "mcl_core:redsand",
		depth_riverbed = 1,
		node_stone = "mcl_colorblocks:hardened_clay",
		y_min = 30,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = -5,
		heat_point = 60,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 22,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})
	minetest.register_biome({
		name = "MesaPlateauFM_sandlevel",
		node_top = "mcl_core:redsand",
		depth_top = 3,
		node_filler = "mcl_colorblocks:hardened_clay_orange",
		depth_filler = 3,
		node_riverbed = "mcl_core:redsand",
		depth_riverbed = 2,
		node_stone = "mcl_colorblocks:hardened_clay",
		-- red sand has wider reach than in other mesa biomes
		y_min = -7,
		y_max = 11,
		humidity_point = -5,
		heat_point = 60,
		vertical_blend = 4,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 22,
		_mcl_skycolor = "#6EB1FF",
		_mcl_fogcolor = overworld_fogcolor
	})

	mcl_biomes.register_biomestack("Savanna", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 36,
			heat_point = 79,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 1,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -2,
		},
		beach = {
			node_top = "mcl_core:sand",
			depth_top = 3,
			node_filler = "mcl_core:sandstone",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -1,
			y_max = 0,
		}
	})

	-- Savanna M
	-- Changes to Savanna: Coarse Dirt. No sand beach. No oaks.
	-- Otherwise identical to Savanna
	mcl_biomes.register_biomestack("SavannaM", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:coarse_dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 48,
			heat_point = 100,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 1,
			_mcl_skycolor = "#6EB1FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
	})

	mcl_biomes.register_biomestack("Jungle", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 88,
			heat_point = 81,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 24,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -3,
			vertical_blend = 1,
		},
		beach = {
			node_top = "mcl_core:dirt",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -2,
			y_max = 0,
		},
	})

	-- Jungle M
	-- Like Jungle but with even more dense vegetation
	mcl_biomes.register_biomestack("JungleM", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 92,
			heat_point = 81,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 25,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -3,
			vertical_blend = 1,
		},
		beach = {
			node_top = "mcl_core:dirt",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -2,
			y_max = 0,
		}
	})

	mcl_biomes.register_biomestack("BambooJungle", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 90,
			heat_point = 79,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 26,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
	})

	mcl_biomes.register_biomestack("JungleEdge", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 88,
			heat_point = 76,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 26,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 2,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
	})

	-- Jungle Edge M (very rare).
	-- Almost identical to Jungle Edge. Has deeper dirt. Melons spawn here a lot.
	-- This biome occours directly between Jungle M and Jungle Edge but also has a small border to Jungle.
	-- This biome is very small in general.
	mcl_biomes.register_biomestack("JungleEdgeM", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			humidity_point = 90,
			heat_point = 79,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 26,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 4,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		}
	})


	mcl_biomes.register_biomestack("MangroveSwamp", {
		biome = {
			node_top = "mcl_mud:mud",
			depth_top = 1,
			node_filler = "mcl_mud:mud",
			depth_filler = 3,
			node_riverbed = "mcl_core:dirt",
			depth_riverbed = 2,
			y_min = 1,
			-- Note: Limited in height!
			y_max = 27,
			humidity_point = 95,
			heat_point = 94,
			_mcl_biome_type = "hot",
			_mcl_palette_index = 27,
			_mcl_skycolor = "#78A7FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:dirt",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:gravel",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -6,
			vertical_blend = 1,
		},
		beach = {
			node_top = "mcl_mud:mud",
			depth_top = 1,
			node_filler = "mcl_mud:mud",
			depth_filler = 3,
			node_riverbed = "mcl_core:dirt",
			depth_riverbed = 2,
			y_min = -5,
			y_max = 0,
		},
	})
	mcl_biomes.register_biomestack("Swampland", {
		biome = {
			node_top = "mcl_core:dirt_with_grass",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			-- Note: Limited in height!
			y_max = 23,
			humidity_point = 90,
			heat_point = 50,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 28,
			_mcl_skycolor = "#78A7FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:sand",
			depth_top = 1,
			node_filler = "mcl_core:sand",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = mcl_vars.mg_ocean_min,
			y_max = -6,
			vertical_blend = 1,
		},
		beach = {
			node_top = "mcl_core:dirt",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = -5,
			y_max = 0,
		}
	})

	mcl_biomes.register_biomestack("MushroomIsland", {
		biome = {
			node_top = "mcl_core:mycelium",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 4,
			-- Note: Limited in height!
			y_max = 20,
			vertical_blend = 1,
			humidity_point = 106,
			heat_point = 50,
			_mcl_biome_type = "medium",
			_mcl_palette_index = 29,
			_mcl_skycolor = "#77A8FF",
			_mcl_fogcolor = overworld_fogcolor
		},
		ocean = {
			node_top = "mcl_core:gravel",
			depth_top = 1,
			node_filler = "mcl_core:gravel",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
		},
		beach = {
			node_top = "mcl_core:mycelium",
			depth_top = 1,
			node_filler = "mcl_core:dirt",
			depth_filler = 3,
			node_riverbed = "mcl_core:sand",
			depth_riverbed = 2,
			y_min = 1,
			y_max = 3,
		}
	})

	mcl_biomes.register_cavebiome("DeepDark", "mcl_sculk:sculk", {
		name = "DeepDark",
		node_top = "mcl_sculk:sculk",
		depth_top = 1,
		node_filler = "mcl_deepslate:deepslate",
		node_riverbed = "mcl_deepslate:deepslate",
		depth_riverbed = 1,
		node_stone = "mcl_deepslate:deepslate",
		y_min = mcl_vars.mg_overworld_min,
		y_max = mcl_vars.mg_overworld_min_old,
		humidity_point = 0,
		heat_point = 61,
		vertical_blend = 8,
		_mcl_biome_type = "hot",
		_mcl_palette_index = 21,
	}, false, {"mcl_core:stone", "mcl_deepslate:deepslate"})

	minetest.register_biome({
		name = "LushCaves",
		node_top = "mcl_core:dirt_with_grass",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 3,
		node_riverbed = "mcl_core:sand",
		node_cave_liquid = "mcl_core:water_source",
		depth_riverbed = 2,
		y_min = 2,
		y_max = 20,
		vertical_blend = 1,
		humidity_point = 83,
		heat_point = 57,
		_mcl_biome_type = "medium",
		_mcl_palette_index = 0,
	})

	minetest.register_biome({
		name = "LushCaves_ocean",
		node_top = "mcl_core:sand",
		depth_top = 1,
		node_filler = "mcl_core:sand",
		depth_filler = 3,
		node_riverbed = "mcl_core:sand",
		node_cave_liquid = "mcl_core:water_source",
		depth_riverbed = 2,
		y_min = -20,
		y_max = 0,
		vertical_blend = 1,
		humidity_point = 83,
		heat_point = 57,
		_mcl_biome_type = "medium",
		_mcl_palette_index = 0,
	})
	minetest.register_biome({
		name = "LushCaves_underground",
		node_top = "mcl_core:sand",
		depth_top = 1,
		node_filler = "mcl_core:sand",
		depth_filler = 3,
		node_riverbed = "mcl_core:sand",
		node_cave_liquid = "mcl_core:water_source",
		depth_riverbed = 2,
		y_min = -128,
		y_max = -21,
		vertical_blend = 1,
		humidity_point = 83,
		heat_point = 57,
		_mcl_biome_type = "medium",
		_mcl_palette_index = 0,
	})

end

-- Register ores which are limited by biomes. For all mapgens except flat and singlenode.
function mcl_biomes.register_biome_ores()
	-- Rarely replace stone with stone monster eggs.
	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_monster_eggs:monster_egg_stone",
		wherein        = "mcl_core:stone",
		clust_scarcity = 26 * 26 * 26,
		clust_num_ores = 3,
		clust_size     = 2,
		y_min          = mcl_vars.mg_overworld_min,
		y_max          = mcl_worlds.layer_to_y(61),
		biomes         = {
			"ExtremeHills", "ExtremeHills_beach", "ExtremeHills_ocean", "ExtremeHills_deep_ocean", "ExtremeHills_underground",
			"ExtremeHills+", "ExtremeHills+_ocean", "ExtremeHills+_deep_ocean", "ExtremeHills+_underground",
			"ExtremeHillsM", "ExtremeHillsM_ocean", "ExtremeHillsM_deep_ocean", "ExtremeHillsM_underground",
		},
	})

	--nether gold
	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_blackstone:blackstone_gilded",
		wherein        = "mcl_blackstone:blackstone",
		clust_scarcity = 4775,
		clust_num_ores = 2,
		clust_size     = 2,
		y_min          = mcl_vars.mg_nether_min,
		y_max          = mcl_vars.mg_nether_max,
	})
	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_blackstone:nether_gold",
		wherein        = "mcl_nether:netherrack",
		clust_scarcity = 830,
		clust_num_ores = 5,
		clust_size     = 3,
		y_min          = mcl_vars.mg_nether_min,
		y_max          = mcl_vars.mg_nether_max,
	})
	minetest.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_blackstone:nether_gold",
		wherein        = "mcl_nether:netherrack",
		clust_scarcity = 1660,
		clust_num_ores = 4,
		clust_size     = 2,
		y_min          = mcl_vars.mg_nether_min,
		y_max          = mcl_vars.mg_nether_max,
	})
end

-- Register “fake” ores directly related to the biomes. These are mostly low-level landscape alternations
function mcl_biomes.register_biomelike_ores()

	-- Random coarse dirt floor in Mega Taiga and Mesa Plateau F
	minetest.register_ore({
		ore_type	= "sheet",
		ore		= "mcl_core:coarse_dirt",
		wherein		= {"mcl_core:podzol", "mcl_core:dirt"},
		clust_scarcity	= 1,
		clust_num_ores	= 12,
		clust_size	= 10,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_threshold = 0.2,
		noise_params = {offset=0, scale=15, spread={x=130, y=130, z=130}, seed=24, octaves=3, persist=0.70},
		biomes = { "MegaTaiga" },
	})

	minetest.register_ore({
		ore_type	= "sheet",
		ore		= "mcl_core:coarse_dirt",
		wherein		= {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		column_height_max = 1,
		column_midpoint_factor = 0.0,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_threshold = 0.0,
		noise_params = {offset=0, scale=15, spread={x=250, y=250, z=250}, seed=24, octaves=3, persist=0.70},
		biomes = { "MesaPlateauF_grasstop" },
	})
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "mcl_core:coarse_dirt",
		wherein		= {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		clust_scarcity	= 1500,
		clust_num_ores	= 25,
		clust_size	= 7,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		},
		biomes = { "MesaPlateauF_grasstop" },
	})
	minetest.register_ore({
		ore_type	= "sheet",
		ore		= "mcl_core:coarse_dirt",
		wherein		= {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		column_height_max = 1,
		column_midpoint_factor = 0.0,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_threshold = -2.5,
		noise_params = {offset=1, scale=15, spread={x=250, y=250, z=250}, seed=24, octaves=3, persist=0.80},
		biomes = { "MesaPlateauFM_grasstop" },
	})
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "mcl_core:coarse_dirt",
		wherein		= {"mcl_core:dirt_with_grass", "mcl_core:dirt"},
		clust_scarcity	= 1800,
		clust_num_ores	= 65,
		clust_size	= 15,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		},
		biomes = { "MesaPlateauFM_grasstop" },
	})
	-- Occasionally dig out portions of MesaPlateauFM
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "air",
		wherein		= {"group:hardened_clay", "group:sand","mcl_core:coarse_dirt"},
		clust_scarcity	= 4000,
		clust_size	= 5,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		},
		biomes = { "MesaPlateauFM", "MesaPlateauFM_grasstop" },
	})
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "mcl_core:redsandstone",
		wherein		= {"mcl_colorblocks:hardened_clay_orange"},
		clust_scarcity	= 300,
		clust_size	= 8,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		},
		biomes = { "MesaPlateauFM_sandlevel" },
	})
	-- More red sand in MesaPlateauFM
	minetest.register_ore({
		ore_type	= "sheet",
		ore		= "mcl_core:redsand",
		wherein		= {"group:hardened_clay"},
		clust_scarcity	= 1,
		clust_num_ores	= 12,
		clust_size	= 10,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_threshold = 0.1,
		noise_params = {offset=0, scale=15, spread={x=130, y=130, z=130}, seed=95, octaves=3, persist=0.70},
		biomes = { "MesaPlateauFM" },
	})
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "mcl_core:redsand",
		wherein		= {"group:hardened_clay"},
		clust_scarcity	= 1500,
		clust_size	= 4,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		},
		biomes = { "MesaPlateauFM", "MesaPlateauFM_grasstop", "MesaPlateauFM_sandlevel" },
	})

	-- Small dirt patches in Extreme Hills M
	minetest.register_ore({
		ore_type	= "blob",
		ore		= "mcl_core:dirt",
		wherein		= {"mcl_core:gravel"},
		clust_scarcity	= 5000,
		clust_num_ores	= 12,
		clust_size	= 4,
		y_min		= mcl_vars.mg_overworld_min,
		y_max		= mcl_vars.mg_overworld_max,
		noise_threshold = 0.2,
		noise_params = {offset=0, scale=5, spread={x=250, y=250, z=250}, seed=64, octaves=3, persist=0.60},
		biomes = { "ExtremeHillsM" },
	})
	minetest.register_decoration({
		--this decoration "hack" replaces the top layer of the above ore with grass when under air.
		deco_type = "simple",
		place_on = {"mcl_core:dirt"},
		fill_ratio = 10,
		biomes = { "ExtremeHillsM" },
		decoration = "mcl_core:dirt_with_grass",
		place_offset_y = -1,
		flags = "force_placement",
	})
	-- For a transition from stone to hardened clay in mesa biomes that is not perfectly flat
	minetest.register_ore({
		ore_type = "stratum",
		ore = "mcl_core:stone",
		wherein = {"group:hardened_clay"},
		noise_params = {offset=-6, scale=2, spread={x=25, y=25, z=25}, octaves=1, persist=0.60},
		stratum_thickness = 8,
		biomes = {
			"Mesa_sandlevel", "Mesa_ocean",
			"MesaBryce_sandlevel", "MesaBryce_ocean",
			"MesaPlateauF_sandlevel", "MesaPlateauF_ocean",
			"MesaPlateauFM_sandlevel", "MesaPlateauFM_ocean",
		},
		y_min = -4,
		y_max = 0,

	})

	-- Mesa strata (registered as sheet ores)

	-- Helper function to create strata.
	local function stratum(y_min, height, color, seed, is_perfect)
		if not height then
			height = 1
		end
		if not seed then
			seed = 39
		end
		local y_max = y_min + height-1
		local perfect_biomes
		if is_perfect then
			-- "perfect" means no erosion
			perfect_biomes = { "MesaBryce", "Mesa", "MesaPlateauF", "MesaPlateauFM" }
		else
			perfect_biomes = { "MesaBryce" }
		end
		-- Full, perfect stratum
		minetest.register_ore({
			ore_type = "stratum",
			ore = "mcl_colorblocks:hardened_clay_"..color,
			-- Only paint uncolored so the biome can choose
			-- a color in advance.
			wherein = {"mcl_colorblocks:hardened_clay"},
			y_min = y_min,
			y_max = y_max,
			biomes = perfect_biomes,
		})
		if not is_perfect then
		-- Slightly eroded stratum, only minor imperfections
		minetest.register_ore({
			ore_type = "stratum",
			ore = "mcl_colorblocks:hardened_clay_"..color,
			wherein = {"mcl_colorblocks:hardened_clay"},
			y_min = y_min,
			y_max = y_max,
			biomes = { "Mesa", "MesaPlateauF" },
			noise_params = {
				offset = y_min+(y_max-y_min)/2,
				scale = 0,
				spread = {x = 50, y = 50, z = 50},
				seed = seed+4,
				octaves = 1,
				persist = 1.0
			},
			np_stratum_thickness = {
				offset = 1.28,
				scale = 1,
				spread = {x = 18, y = 18, z = 18},
				seed = seed+4,
				octaves = 3,
				persist = 0.8,
			},
		})
		-- Very eroded stratum, most of the color is gone
		minetest.register_ore({
			ore_type = "stratum",
			ore = "mcl_colorblocks:hardened_clay_"..color,
			wherein = {"mcl_colorblocks:hardened_clay"},
			y_min = y_min,
			y_max = y_max,
			biomes = { "MesaPlateauFM" },
			noise_params = {
				offset = y_min+(y_max-y_min)/2,
				scale = 0,
				spread = {x = 50, y = 50, z = 50},
				seed = seed+4,
				octaves = 1,
				persist = 1.0
			},
			np_stratum_thickness = {
				offset = 0.1,
				scale = 1,
				spread = {x = 28, y = 28, z = 28},
				seed = seed+4,
				octaves = 2,
				persist = 0.6,
			},
		})
		end

	end

	-- Hardcoded orange strata near sea level.

	-- For MesaBryce, since it has no sand at these heights
	stratum(4, 1, "orange", nil, true)
	stratum(7, 2, "orange", nil, true)

	-- 3-level stratum above the sandlevel (all mesa biomes)
	stratum(11, 3, "orange", nil, true)

	-- Create random strata for up to Y = 256.
	-- These strata are calculated based on the world seed and are global.
	-- They are thus different per-world.
	local mesapr = PcgRandom(mg_seed)

	--[[

	------ DANGER ZONE! ------

	The following code is sensitive to changes; changing any number may break
	mapgen consistency when the mapgen generates new mapchunks in existing
	worlds because the random generator will yield different results and the strata
	suddenly don't match up anymore. ]]

	-- Available Mesa colors:
	local mesa_stratum_colors = { "silver", "brown", "orange", "red", "yellow", "white" }

	-- Start level
	local y = 17

	-- Generate stratas
	repeat
		-- Each stratum has a color (duh!)
		local colorid = mesapr:next(1, #mesa_stratum_colors)

		-- … and a random thickness
		local heightrandom = mesapr:next(1, 12)
		local h
		if heightrandom == 12 then
			h = 4
		elseif heightrandom >= 10 then
			h = 3
		elseif heightrandom >= 8 then
			h = 2
		else
			h = 1
		end
		-- Small built-in bias: Only thin strata up to this Y level
		if y < 45 then
			h = math.min(h, 2)
		end

		-- Register stratum
		stratum(y, h, mesa_stratum_colors[colorid])

		-- Skip a random amount of layers (which won't get painted)
		local skiprandom = mesapr:next(1, 12)
		local skip
		if skiprandom == 12 then
			skip = 4
		elseif skiprandom >= 10 then
			skip = 3
		elseif skiprandom >= 5 then
			skip = 2
		elseif skiprandom >= 2 then
			skip = 1
		else
			-- If this happens, the next stratum will touch the previous one without gap
			skip = 0
		end

		-- Get height of next stratum or finish
		y = y + h + skip
	until y > 256

	--[[ END OF DANGER ZONE ]]
end

