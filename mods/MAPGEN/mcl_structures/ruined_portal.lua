local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

local function get_replacements(b,c,pr)
	local r = {}
	if not b then return r end
	for _, v in pairs(b) do
		if pr:next(1,100) < c then table.insert(r,v) end
	end
	return r
end

local def = {
	place_on = {"group:grass_block","group:dirt","mcl_core:dirt_with_grass","group:grass_block","group:sand","group:grass_block_snow","mcl_core:snow"},
	flags = "place_center_x, place_center_z, all_floors",
	solid_ground = true,
	make_foundation = true,
	chunk_probability = 20,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	sidelen = 10,
	y_offset = -5,
	filenames = {
		{main = modpath.."/schematics/mcl_structures_ruined_portal_1.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_1.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_2.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_2.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_3.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_3.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_4.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_4.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_5.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_5.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_6.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_6.zst"},
		{main = modpath.."/schematics/mcl_structures_ruined_portal_99.mts", meta = modpath.."/metadata/mcl_structures_ruined_portal_99.zst"},
	},
	after_place = function(pos, _, pr)
		local p1 = vector.offset(pos,-9, -1, -9)
		local p2 = vector.offset(pos,9, 16 ,9)
		local gold = core.find_nodes_in_area(p1,p2,{"mcl_core:goldblock"})
		local lava = core.find_nodes_in_area(p1,p2,{"mcl_core:lava_source"})
		local rack = core.find_nodes_in_area(p1,p2,{"mcl_nether:netherrack"})
		local brick = core.find_nodes_in_area(p1,p2,{"mcl_core:stonebrick"})
		local obby = core.find_nodes_in_area(p1,p2,{"mcl_core:obsidian"})
		mcl_util.bulk_swap_node(get_replacements(gold,30,pr),{name="air"})
		mcl_util.bulk_swap_node(get_replacements(lava,20,pr),{name="mcl_nether:magma"})
		mcl_util.bulk_swap_node(get_replacements(rack,7,pr),{name="mcl_nether:magma"})
		mcl_util.bulk_swap_node(get_replacements(obby,15,pr),{name="mcl_core:crying_obsidian"})
		mcl_util.bulk_swap_node(get_replacements(obby,10,pr),{name="air"})
		mcl_util.bulk_swap_node(get_replacements(brick,50,pr),{name="mcl_core:stonebrickcracked"})
		brick = core.find_nodes_in_area(p1,p2,{"mcl_core:stonebrick"})
		mcl_util.bulk_swap_node(get_replacements(brick,50,pr),{name="mcl_core:stonebrickmossy"})
	end,
	construct_nodes = {"mcl_chests:chest_small"}
}
mcl_structures.register_structure("ruined_portal_overworld",def)
mcl_structures.register_structure("ruined_portal_nether",table.merge(def,{
	y_min = mcl_vars.mg_lava_nether_max +10,
	y_max = mcl_vars.mg_nether_max - 15,
	place_on = {"mcl_nether:netherrack","group:soul_block","mcl_blackstone:basalt,mcl_blackstone:blackstone","mcl_crimson:crimson_nylium","mcl_crimson:warped_nylium"}
}))
