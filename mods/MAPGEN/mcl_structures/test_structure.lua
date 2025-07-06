local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

mcl_structures.register_structure("test_struct",{
	place_on = {"group:sand","group:grass_block","mcl_core:water_source","group:dirt"},
	flags = "place_center_x, place_center_z, liquid_surface, force_placement",
	sidelen = 2,
	chunk_probability = 1,
    fill_ratio = 1,
	y_max = mcl_vars.mg_overworld_max,
	y_min = -4,
	y_offset = 0,
	biomes = { "Swampland", "Swampland_ocean", "Swampland_shore", "Plains" },
	filenames = { {main=modpath.."/schematics/test_schematic.mts", meta=modpath.."/schematics/test_meta.zst"} },
    construct_nodes = {"mcl_chests:chest_small"}
})
