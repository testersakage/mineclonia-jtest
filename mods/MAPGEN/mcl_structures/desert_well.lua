local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

vl_structures.register_structure("desert_well",{
	place_on = {"group:sand"},
	flags = "place_center_x, place_center_z",
	chunk_probability = 15,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	y_offset = -2,
	biomes = { "Desert" },
	filenames = { modpath.."/schematics/mcl_structures_desert_well.mts" },
	after_place = function(pos,def,pr,p1,p2)
		if minetest.registered_nodes["mcl_sus_nodes:sand"] then
			-- p1.y-3 to p1.y+2 is not a typo
			local sus_poss = minetest.find_nodes_in_area(vector.new(p1.x,p1.y-3,p1.z), vector.new(p2.x,p1.y+2,p2.z), {"mcl_core:sand","mcl_core:sandstone","mcl_core:redsand","mcl_core:redsandstone"})
			if #sus_poss > 0 then
				table.shuffle(sus_poss)
				for i = 1,pr:next(1,#sus_poss) do
					minetest.set_node(sus_poss[i],{name="mcl_sus_nodes:sand"})
					local meta = minetest.get_meta(sus_poss[i])
					meta:set_string("structure","desert_well")
				end
			end
		end
	end,
	loot = {
		["SUS"] = {
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_pottery_sherds:arms_up", weight = 2, },
				{ itemstring = "mcl_pottery_sherds:brewer", weight = 2, },
				{ itemstring = "mcl_core:brick", weight = 1 },
				{ itemstring = "mcl_core:emerald", weight = 1 },
				{ itemstring = "mcl_core:stick", weight = 1 },
				{ itemstring = "mcl_sus_stew:stew", weight = 1 },

			}
		}},
	},
})

