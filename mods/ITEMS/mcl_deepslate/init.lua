local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

mcl_deepslate = {}
mcl_deepslate.translator = minetest.get_translator(modname)
local S = mcl_deepslate.translator

function mcl_deepslate.register_deepslate_ore(item, desc, extra, basename)
	local nodename = "mcl_deepslate:deepslate_with_"..item
	local basename = basename or "mcl_core:stone_with_" .. item

	local def = table.copy(minetest.registered_nodes[basename])
	def._doc_items_longdesc = S("@1 is a variant of @2 that can generate in deepslate and tuff blobs.", desc, def.description)
	def.description = desc
	def.tiles = { "mcl_deepslate_" .. item .. "_ore.png" }

	table.update(def,extra or {})

	minetest.register_node(nodename, def)

	local result = minetest.get_craft_result({
		method = "cooking",
		width = 1,
		items = {basename},
	})

	if not result.item:is_empty() then
		minetest.register_craft({
			type = "cooking",
			output = result.item:to_string(),
			recipe = nodename,
			cooktime = result.time,
		})
	end
end

function mcl_deepslate.register_deepslate_variant(name, defs)
	local main_itemstring = "mcl_deepslate:deepslate_"..name
	local main_def = {
		_doc_items_hidden = false,
		tiles = { "mcl_deepslate_"..name..".png" },
		is_ground_content = false,
		groups = { pickaxey = 1, building_block = 1, material_stone = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3.5,
		_mcl_silk_touch_drop = true,
	}
	if defs.node then
		defs.node.groups = table.merge(main_def.groups, defs.node.groups)
		minetest.register_node(main_itemstring, table.merge(main_def, defs.node))
	end

	if defs.cracked then
		minetest.register_node(main_itemstring.."_cracked", table.merge(main_def, {
			_doc_items_longdesc = S("@1 are a cracked variant.", defs.cracked.description),
			tiles = { "mcl_deepslate_"..name.."_cracked.png" },
		}, defs.cracked))
	end
	if defs.stair then
		mcl_stairs.register_stair("deepslate_"..name, {
			description = defs.stair.description,
			baseitem = main_itemstring,
			overrides = defs.stair
		})
	end
	if defs.slab then
		mcl_stairs.register_slab("deepslate_"..name, {
			description = defs.slab.description,
			baseitem = main_itemstring,
			overrides = defs.slab
		})
	end

	if defs.wall then
		mcl_walls.register_wall("mcl_deepslate:deepslate"..name.."wall", defs.wall.description, main_itemstring, nil, nil, nil, nil, defs.wall)
	end
end

function mcl_deepslate.register_tuff_variant(name, defs)
	local main_itemstring = "mcl_deepslate:tuff"
	local subname = "tuff"

	if name ~= "" then main_itemstring = main_itemstring.."_"..name end
	if name ~= "" then subname = subname.."_"..name end

	local main_def = {
		_doc_items_hidden = false,
		tiles = { "mcl_deepslate_tuff_"..name..".png" },
		is_ground_content = false,
		groups = { pickaxey = 1, building_block = 1, material_stone = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3.5,
		_mcl_silk_touch_drop = true,
	}
	if defs.node then
		defs.node.groups = table.merge(main_def.groups, defs.node.groups)
		minetest.register_node(main_itemstring, table.merge(main_def, defs.node))
	end

	if defs.cracked then
		minetest.register_node(main_itemstring.."_cracked", table.merge(main_def, {
			_doc_items_longdesc = S("@1 are a cracked variant.", defs.cracked.description),
			tiles = { "mcl_deepslate_tuff_"..name.."_cracked.png" },
		}, defs.cracked))
	end
	if defs.stair then
		mcl_stairs.register_stair(subname, {
			description = defs.stair.description,
			baseitem = main_itemstring,
			overrides = defs.stair
		})
	end
	if defs.slab then
		mcl_stairs.register_slab(subname, {
			description = defs.slab.description,
			baseitem = main_itemstring,
			overrides = defs.slab
		})
	end

	if defs.wall then
		mcl_walls.register_wall("mcl_deepslate:tuff"..subname.."wall", defs.wall.description, main_itemstring, nil, nil, nil, nil, defs.wall)
	end
end

dofile(modpath.."/deepslate.lua")
dofile(modpath.."/tuff.lua")
