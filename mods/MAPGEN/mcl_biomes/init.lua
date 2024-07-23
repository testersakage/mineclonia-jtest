local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

mcl_biomes = {
	stonelike = {"mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite"},
}

dofile(modpath.."/biomes.lua")
dofile(modpath.."/decorations.lua")


if not mcl_vars.superflat then
	mcl_biomes.register_biomes()
	mcl_biomes.register_biomelike_ores()
	mcl_biomes.register_biome_ores()
	mcl_biomes.register_decorations()
else
	-- Implementation of Minecraft's Superflat mapgen, classic style:
	-- * Perfectly flat land, 1 grass biome, no decorations, no caves
	-- * 4 layers, from top to bottom: grass block, dirt, dirt, bedrock
	minetest.clear_registered_biomes()
	minetest.clear_registered_decorations()
	minetest.clear_registered_schematics()
	mcl_biomes.register_classic_superflat_biome()
end


dofile(modpath.."/nether.lua")
dofile(modpath.."/end.lua")

local deco_id_chorus_plant = minetest.get_decoration_id("mcl_biomes:chorus_plant")
minetest.set_gen_notify({decoration=true}, { deco_id_chorus_plant })


local deco_ids_fungus ={
	minetest.get_decoration_id("mcl_biomes:crimson_tree1"),
	minetest.get_decoration_id("mcl_biomes:crimson_tree2"),
	minetest.get_decoration_id("mcl_biomes:crimson_tree3"),
	minetest.get_decoration_id("mcl_biomes:warped_tree1"),
	minetest.get_decoration_id("mcl_biomes:warped_tree2"),
	minetest.get_decoration_id("mcl_biomes:warped_tree3")
}
local deco_ids_trees = {
	minetest.get_decoration_id("mcl_biomes:mangrove_tree_1"),
	minetest.get_decoration_id("mcl_biomes:mangrove_tree_2"),
	minetest.get_decoration_id("mcl_biomes:mangrove_tree_3"),
}
for _,f in pairs(deco_ids_fungus) do
	minetest.set_gen_notify({decoration=true}, { f })
end
for _,f in pairs(deco_ids_trees) do
	minetest.set_gen_notify({decoration=true}, { f })
end

local function mangrove_roots_gen(gennotify, pr)
	for _, f in pairs(deco_ids_trees) do
		for _, pos in ipairs(gennotify["decoration#" .. f] or {}) do
			local nn = minetest.find_nodes_in_area(vector.offset(pos, -8, -1, -8), vector.offset(pos, 8, 0, 8), {"mcl_mangrove:mangrove_roots"})
			for _, v in pairs(nn) do
				local l = pr:next(2, 16)
				local n = minetest.get_node(vector.offset(v, 0, -1, 0)).name
				if minetest.get_item_group(n, "water") > 0 then
					local wl = "mcl_mangrove:water_logged_roots"
					if n:find("river") then
						wl = "mcl_mangrove:river_water_logged_roots"
					end
					mcl_util.bulk_swap_node(minetest.find_nodes_in_area(vector.offset(v, 0, 0, 0), vector.offset(v, 0, -l, 0), {"group:water"}), {name = wl})
				elseif n == "mcl_mud:mud" then
					mcl_util.bulk_swap_node(minetest.find_nodes_in_area(vector.offset(v, 0, 0, 0), vector.offset(v, 0, -l, 0), {"mcl_mud:mud"}), {name = "mcl_mangrove:mangrove_mud_roots"})
				elseif n == "air" then
					mcl_util.bulk_swap_node(minetest.find_nodes_in_area(vector.offset(v, 0, 0, 0), vector.offset(v, 0, -l, 0), {"air"}), {name = "mcl_mangrove:mangrove_roots"})
				end
			end
		end
	end
end

local function chorus_gen (gennotify, pr)
	for _, pos in ipairs(gennotify["decoration#" .. deco_id_chorus_plant] or {}) do
		local x, y, z = pos.x, pos.y, pos.z
		if x < -10 or x > 10 or z < -10 or z > 10 then
			local realpos = {x = x, y = y + 1, z = z}
			local node = minetest.get_node(realpos)
			if node and node.name == "mcl_end:chorus_flower" then
				mcl_end.grow_chorus_plant(realpos, node, pr)
			end
		end
	end
end

local function crimson_warped_gen(gennotify)
	for _, f in pairs(deco_ids_fungus) do
		for _, pos in ipairs(gennotify["decoration#" .. f] or {}) do
			minetest.fix_light(vector.offset(pos, -8, -8, -8), vector.offset(pos, 8, 8, 8))
		end
	end
end

if deco_id_chorus_plant or deco_ids_fungus or deco_ids_trees then
	mcl_mapgen_core.register_generator("chorus_grow", nil, function(minp, maxp, blockseed)
		local gennotify = minetest.get_mapgen_object("gennotify")
		local pr = PseudoRandom(blockseed + 14)
		if not (maxp.y < mcl_vars.mg_overworld_min or minp.y > mcl_vars.mg_overworld_max) then
			local biomemap = minetest.get_mapgen_object("biomemap")
			-- get_mapgen_object returns nil with lua mapgens
			if biomemap then
				local swamp_biome_id = minetest.get_biome_id("MangroveSwamp")
				local swamp_shore_id = minetest.get_biome_id("MangroveSwamp_shore")
				local is_swamp = table.indexof(biomemap, swamp_biome_id) ~= -1
				local is_swamp_shore = table.indexof(biomemap, swamp_shore_id) ~= -1

				if is_swamp or is_swamp_shore then
					mangrove_roots_gen(gennotify, pr)
				end
			end
		end

		if not (maxp.y < mcl_vars.mg_end_min or minp.y > mcl_vars.mg_end_max) then
			chorus_gen(gennotify, pr)
		end

		if not (maxp.y < mcl_vars.mg_nether_min or minp.y > mcl_vars.mg_nether_max) then
			crimson_warped_gen(gennotify)
		end
	end)
end
