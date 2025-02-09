local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize
local F = minetest.formspec_escape

local dyerecipes = {}
local preview_item_prefix = "mcl_banners_preview_"

for name,pattern in pairs(mcl_banners.patterns) do
	if not pattern.signature and table.indexof(dyerecipes,name) == -1 then
		local added = false
		for i = 1,3 do
			for j = 1,3 do
				if pattern[i] and pattern[i][j] == "group:dye" then
					table.insert(dyerecipes,name)
					added = true
					break
				end
			end
			if added then break end
		end
	end
end
table.sort(dyerecipes)

local selected_pattern_by_pos = {}

function get_formspec_preview_button (x, y, layers, base_unicolor, unicolor, pattern_id)
	local name = "item_button_" .. preview_item_prefix .. pattern_id
	local new_layers = layers and table.copy(layers) or {}
	table.insert(new_layers, { color = "unicolor_"..unicolor, pattern = pattern_id })
	local it = core.formspec_escape(mcl_banners.make_banner_texture("unicolor_"..base_unicolor, new_layers, "item"))
	local result = string.format("image_button[%f,%f;%f,%f;%s;%s;%s]",x,y,1.1,1.1, it, name, "")
	result = result .. string.format("tooltip[%s;%s]", name, mcl_banners.make_pattern_name("unicolor_"..unicolor, pattern_id))
	return result
end

local function get_formspec(pos)
	local patterns = {}
	local max_y = -2.2 -- Pattern container content height 3.5, minus border 0.2, minus first row 1.1
	local preview_texture = "blank.png"
	if pos then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("banner") then
			local banner = inv:get_stack("banner", 1)
			local layers = mcl_banners.read_layers(banner:get_meta())
			if #layers < mcl_banners.max_craftable_layers then
				local selected_preview = selected_pattern_by_pos[tostring(pos)] or ""
				local color
				local dye_name = inv:get_stack("dye", 1):get_name()
				local dye_def = minetest.registered_items[dye_name]
				if dye_def and core.get_item_group(dye_name, "dye") > 0 and dye_def._color then
					color = mcl_dyes.colors[dye_def._color].unicolor
					if color then
						local pitem = inv:get_stack("pattern", 1):get_name()
						local pdef = minetest.registered_items[pitem]
						local light_colours = { "white", "grey", "green", "light_red" } -- If white / light-grey / lime / pink,
						local base_color = table.indexof( light_colours, color ) > 0 and "darkgrey" or "grey" -- Make base dark grey
						if pdef and pdef._pattern then
							table.insert(patterns, get_formspec_preview_button(0.1, 0.1, nil, base_color, color, pdef._pattern))
							selected_preview = pdef._pattern
							selected_pattern_by_pos[tostring(pos)] = selected_preview
						else
							local x_len = 0.1
							local y_len = 0.1
							local found_preview = false
							for _, v in ipairs(dyerecipes) do
								if x_len > 5 then
									max_y = max_y + 1.1
									y_len = y_len + 1.1
									x_len = 0.1
								end
								table.insert(patterns, get_formspec_preview_button(x_len, y_len, nil, base_color, color, v))
								x_len = x_len + 1.1
								if v == selected_preview then
									found_preview = true
								end
							end
							if not found_preview then
								selected_preview = ""
							end
						end
						if selected_preview ~= "" then
							local banner_color = banner:get_definition()._unicolor
							local preview_layers = table.copy( layers )
							table.insert( preview_layers, { color = "unicolor_"..color, pattern = selected_preview } )
							preview_texture = mcl_banners.make_banner_texture(banner_color, preview_layers, "item")
							preview_texture = "[combine:30x48:-9,0=" .. mcl_banners.escape_texture(preview_texture)
							preview_texture = core.formspec_escape(preview_texture)
						end
					end
				end
			end
		end
	end
	if max_y < 0 then max_y = 0 else max_y = math.ceil(max_y * 10) end

	local formspec = "formspec_version[4]"..
	"size[11.75,10.425]"..
	"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Loom"))) .. "]"..

	mcl_formspec.get_itemslot_bg_v4(0.375,0.75,1,1)..
	mcl_formspec.get_itemslot_bg_v4(0.375,0.75,1,1,0,"mcl_loom_itemslot_bg_banner.png")..
	"list[context;banner;0.34,0.75;1,1;]"..
	mcl_formspec.get_itemslot_bg_v4(0.375,2.0,1,1)..
	mcl_formspec.get_itemslot_bg_v4(0.375,2.0,1,1,0,"mcl_loom_itemslot_bg_dye.png")..
	"list[context;dye;0.375,2.0;1,1;]"..
	mcl_formspec.get_itemslot_bg_v4(0.375,3.25,1,1)..
	mcl_formspec.get_itemslot_bg_v4(0.375,3.25,1,1,0,"mcl_loom_itemslot_bg_pattern.png")..
	"list[context;pattern;0.375,3.25;1,1;]"..

	"box[1.575,0.7;5.7,3.6;"..mcl_colors.DARK_GRAY.."]"..
	"scroll_container[1.575,0.7;6,3.6;pattern_scroll;vertical;0.1]"..
	table.concat(patterns)..
	"scroll_container_end[]"..
	"scrollbaroptions[arrows=show;thumbsize=30;min=0;max="..max_y.."]"..
	"scrollbar[7.25,0.7;0.4,3.6;vertical;pattern_scroll;]"..

	"image_button[7.85,0.7;2.25,3.6;"..preview_texture..";item_button_loom_craft_banner;]"..

	mcl_formspec.get_itemslot_bg_v4(10.375,2,1,1)..
	"list[context;output;10.375,2;1.1,1.1;]"..

	"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]"..
	mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3)..
	"list[current_player;main;0.375,5.1;9,3;9]"..

	mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1)..
	"list[current_player;main;0.375,9.05;9,1;]"..

	"listring[context;output]"..
	"listring[current_player;main]"..
	"listring[context;sorter]"..
	"listring[current_player;main]"..
	"listring[context;banner]"..
	"listring[current_player;main]"..
	"listring[context;dye]"..
	"listring[current_player;main]"..
	"listring[context;pattern]"..
	"listring[current_player;main]"
	return formspec
end

local function update_formspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", get_formspec(pos))
end

local function create_banner(stack, pattern, color)
	local im = stack:get_meta()
	local layers = mcl_banners.read_layers(im)
	table.insert(layers,{
		pattern = pattern,
		color = "unicolor_"..mcl_dyes.colors[color].unicolor
	})
	mcl_banners.write_layers(im, layers)
	tt.reload_itemstack_description(stack)
	return stack
end

local function sort_stack(stack)
	for group, list in pairs({ banner = "banner", dye = "dye", banner_pattern = "pattern" }) do
		if minetest.get_item_group(stack:get_name(), group) > 0 then return list end
	end
end

local function allow_put(pos, listname, index, stack, player) ---@diagnostic disable-line: unused-local
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	elseif listname == "output" then return 0
	elseif listname == "banner" and minetest.get_item_group(stack:get_name(),"banner") == 0 then return 0
	elseif listname == "dye" and minetest.get_item_group(stack:get_name(),"dye") == 0 then return 0
	elseif listname == "pattern" and minetest.get_item_group(stack:get_name(),"banner_pattern") == 0 then return 0
	elseif listname == "sorter" then
		local inv = minetest.get_meta(pos):get_inventory()
		local trg = sort_stack(stack)
		if trg then
			local stack1 = ItemStack(stack):take_item()
			if inv:room_for_item(trg, stack) then
				return stack:get_count()
			elseif inv:room_for_item(trg, stack1) then
				return stack:get_stack_max() - inv:get_stack(trg, 1):get_count()
			end
		end
		return 0
	else
		return stack:get_count()
	end
end

minetest.register_node("mcl_loom:loom", {
	description = S("Loom"),
	_tt_help = S("Used to create banner designs"),
	_doc_items_longdesc = S("This is the shepherd villager's work station. It is used to create banner designs."),
	tiles = {
		"loom_top.png", "loom_bottom.png",
		"loom_side.png", "loom_side.png",
		"loom_side.png", "loom_front.png"
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = { axey = 2, handy = 1, deco_block = 1, material_wood = 1, flammable = 1 },
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5,
	_mcl_burntime = 15,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("sorter", 1)
		inv:set_size("banner", 1)
		inv:set_size("dye", 1)
		inv:set_size("pattern", 1)
		inv:set_size("output", 1)
		meta:set_string("formspec", get_formspec(pos))
	end,
	after_dig_node = function(pos, _, old_meta)
		selected_pattern_by_pos[tostring(pos)] = nil
		mcl_util.drop_items_from_meta_container({"banner", "dye", "pattern", "output"})(pos, nil, old_meta)
	end,
	on_rightclick = update_formspec,
	on_receive_fields = function(pos, formname, fields, sender) ---@diagnostic disable-line: unused-local
		local sender_name = sender:get_player_name()
		if minetest.is_protected(pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local pos_str = tostring(pos)
		local pattern_id = selected_pattern_by_pos[pos_str]
		if not inv:is_empty("banner") and not inv:is_empty("dye") then
			for k, _ in pairs(fields or {}) do
				if tostring(k) ~= "" and k:find("^item_button_"..preview_item_prefix) then
					local str = k:gsub("^item_button_"..preview_item_prefix,"")
					selected_pattern_by_pos[pos_str] = str
				elseif k == "item_button_loom_craft_banner" and pattern_id then
					local pattern = inv:get_stack("pattern",1)
					local dye = inv:get_stack("dye",1)
					local cdef = minetest.registered_items[dye:get_name()]
					if not inv:is_empty("pattern") then
						local pdef = minetest.registered_items[pattern:get_name()]
						pattern_id = pdef._pattern
					elseif not mcl_dyes.colors[cdef._color] or table.indexof(dyerecipes,pattern_id) == -1 then
						pattern_id = nil
					end
					if pattern_id then
						local banner = inv:get_stack("banner",1)
						local cbanner = banner:peek_item()
						local new_banner = create_banner(cbanner,pattern_id,cdef._color)
						if not inv:is_empty("output") then
							local output_stack = inv:get_stack("output",1)
							if output_stack:get_free_space() > 0 then
								local max_layers = mcl_banners.max_craftable_layers
								local out_desc, _, out_name = mcl_banners.update_description(output_stack, max_layers)
								local new_desc, _, new_name = mcl_banners.update_description(new_banner, max_layers)
								if out_desc == new_desc and out_name == new_name then
									new_banner:set_count(output_stack:get_count() + 1)
								else
									pattern_id = nil
								end
							else
								pattern_id = nil
							end
						end
						if pattern_id then
							dye:take_item()
							inv:set_stack("dye", 1, dye)
							banner:take_item()
							inv:set_stack("banner", 1, banner)
							if not inv:is_empty("pattern") then
								pattern:take_item()
								inv:set_stack("pattern", 1, pattern)
							end
							inv:set_stack("output", 1, new_banner)
						end
					end
				end
			end
		end
		update_formspec(pos)
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player) ---@diagnostic disable-line: unused-local
		if listname == "sorter" then return 0 end
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player) ---@diagnostic disable-line: unused-local
		if from_list == "sorter" or to_list == "sorter" then return 0 end
		local inv = minetest.get_meta(pos):get_inventory()
		local stack = inv:get_stack(from_list,from_index)
		return allow_put(pos, to_list, to_index, stack, player)
	end,
	allow_metadata_inventory_put = allow_put,
	on_metadata_inventory_move = update_formspec,
	on_metadata_inventory_put = function(pos, listname, index, stack, player) ---@diagnostic disable-line: unused-local
		if listname == "sorter" then
			local inv = minetest.get_meta(pos):get_inventory()
			inv:add_item(sort_stack(stack), stack)
			inv:set_stack("sorter", 1, ItemStack(""))
		end
		update_formspec(pos)
	end,
	on_metadata_inventory_take = update_formspec
})

minetest.register_craft({
	output = "mcl_loom:loom",
	recipe = {
		{ "", "", "" },
		{ "mcl_mobitems:string", "mcl_mobitems:string", "" },
		{ "group:wood", "group:wood", "" },
	}
})

minetest.register_lbm({
	label = "Update Loom formspecs and invs to allow new sneak+click behavior",
	name = "mcl_loom:update_coolsneak",
	nodenames = { "mcl_loom:loom" },
	run_at_every_load = false,
	action = function(pos)
		minetest.get_meta(pos):get_inventory():set_size("sorter", 1)
		update_formspec(pos)
	end,
})