local S = minetest.get_translator(minetest.get_current_modname())

local function refresh_cartography(pos, player)
	local formspec = "size[9,8.75]"..
	"label[0,4;"..minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))).."]"..
	"label[0,-0;"..minetest.formspec_escape(minetest.colorize("#313131", S("Cartography Table"))).."]"..
	"list[current_player;main;0,4.5;9,3;9]"..
	mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
	"list[current_player;main;0,7.74;9,1;]"..
	mcl_formspec.get_itemslot_bg(0,7.74,9,1)..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input;0.5,0.7;1,1;1]"..
	mcl_formspec.get_itemslot_bg(0.5,0.7,1,1)..
	"image[0.1,1.3;2,2;craftguide_zoomin_icon.png^[colorize:grey]"..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input;0.5,2.7;1,1;]"..
	"image[1.7,1.7;1.5,1;gui_crafting_arrow.png]"..
	mcl_formspec.get_itemslot_bg(0.5,2.7,1,1)..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;7.5,1.7;1,1;]"..
	"image[7.3,1.5;1.5,1.5;mcl_formspec_itemslot.png]"..
	"listring[]"
	local inv = minetest.get_meta(pos):get_inventory()
	local map = inv:get_stack("input", 2)
	local texture = mcl_maps.load_map_item(map)
	local marker = inv:get_stack("input", 1):get_name()
	if marker == "mcl_maps:empty_map" then
		if texture then
			formspec = formspec .. "image[4.3,0.5;3,3;mcl_maps_map_background.png] image[4.5,0.7;2.5,2.5;"..texture.."] image[3.3,1.5;3,3;mcl_maps_map_background.png] image[3.5,1.7;2.5,2.5;"..texture.."]"
		else
			formspec = formspec .. "image[4.3,0.5;3,3;mcl_maps_map_background.png] image[3.3,1.5;3,3;mcl_maps_map_background.png]"
		end
		if not map:is_empty() then map:set_count(2) inv:set_stack("output", 1, map) end
	else
		formspec = formspec .. "image[3.3,0.5;4,4;mcl_maps_map_background.png]"
		if texture then formspec = formspec .. "image[3.5,0.7;3.5,3.5;"..texture.."]" end
		if marker == "xpanes:pane_natural_flat" and not map:is_empty() then
			if map:get_meta():get_int("locked") == 1 then
				formspec = formspec .. "image[1.7,1.7;1,1;mcl_core_barrier.png] image[5.8,3.2;0.5,0.5;mcl_core_barrier.png]"
			else
				map:get_meta():set_string("locked", 1)
				inv:set_stack("output", 1, map)
			end
		end
	end
	minetest.show_formspec(player:get_player_name(), "mcl_cartography_table", formspec)
end

local allowed_to_put = {
	--["mcl_core:paper"] = true, Requires missing features with increasing map size
	["mcl_maps:empty_map"] = true,
	["xpanes:pane_natural_flat"] = true
}

minetest.register_node("mcl_cartography_table:cartography_table", {
	description = S("Cartography Table"),
	_tt_help = S("Used to create or copy maps"),
	_doc_items_longdesc = S("Is used to create or copy maps for use.."),
	tiles = {
		"cartography_table_top.png", "cartography_table_side3.png",
		"cartography_table_side3.png", "cartography_table_side2.png",
		"cartography_table_side3.png", "cartography_table_side1.png"
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = { axey = 2, handy = 1, deco_block = 1, material_wood = 1, flammable = 1 },
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5,
	on_construct = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		inv:set_size("input", 2)
		inv:set_size("output", 1)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) or listname == "output" then
			return 0
		else
			if index == 2 and not stack:get_name():find("filled_map") then return 0 end
			if index == 1 and not allowed_to_put[stack:get_name()] then return 0 end
			return stack:get_count()
		end
	end,
	on_metadata_inventory_put = function(pos, _, _, _, player)
		refresh_cartography(pos, player)
	end,
	on_metadata_inventory_take = function(pos, listname, _, _, player)
		local inv = minetest.get_meta(pos):get_inventory()
		if listname == "output" then
			local first = inv:get_stack("input", 2); first:take_item(); inv:set_stack("input", 2, first)
			local second = inv:get_stack("input", 1); second:take_item(); inv:set_stack("input", 1, second)
		else
			inv:set_stack("output", 1, "")
		end
		refresh_cartography(pos, player)
	end,
	allow_metadata_inventory_move = function() return 0 end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return 0 and minetest.is_protected(pos, player:get_player_name()) or stack:get_count()
	end,
	on_rightclick = function(pos, node, player, itemstack)
		if not player:get_player_control().sneak then refresh_cartography(pos, player) end
	end,
	-- TODO: Drop items on dig
})

minetest.register_craft({
	output = "mcl_cartography_table:cartography_table",
	recipe = {
		{ "mcl_core:paper", "mcl_core:paper", "" },
		{ "group:wood", "group:wood", "" },
		{ "group:wood", "group:wood", "" },
	}
})
