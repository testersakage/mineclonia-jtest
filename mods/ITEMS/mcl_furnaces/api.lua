local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize
local F = minetest.formspec_escape
mcl_formspec.label_color = "#111111"

local function get_anim(texture,time_total,time_elapsed)
	local time_left = time_total - ( time_elapsed or 0 )
	local frame = 11 - math.ceil(time_left * 10 / time_total)
	local rate = time_total * 100
	return texture..";"..texture..";10;"..rate..";"..frame.."]"
end


local function active_formspec(name,fire_anim,arrow_anim)
	return table.concat({
		"formspec_version[6]",
		"size[11.75,10.425]",
		"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Furnace"))) .. "]",
		mcl_formspec.get_itemslot_bg_v4(3.5, 0.75, 1, 1),
		"list[context;src;3.5,0.75;1,1;]",

		"animated_image[3.5,2;1,1;"..fire_anim,

		mcl_formspec.get_itemslot_bg_v4(3.5, 3.25, 1, 1),
		"list[context;fuel;3.5,3.25;1,1;]",

		"animated_image[5.25,2;1.5,1;"..arrow_anim,

		mcl_formspec.get_itemslot_bg_v4(7.875, 2, 1, 1, 0.2),
		"list[context;dst;7.875,2;1,1;]",

		"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",

		"image_button[7.85,0.6;1,1;craftguide_book.png;craftguide;]"..
		"tooltip[craftguide;"..minetest.formspec_escape(S("Recipe book")).."]"..

		"listring[context;dst]",
		"listring[current_player;main]",
		"listring[context;src]",
		"listring[current_player;main]",
		"listring[context;fuel]",
		"listring[current_player;main]",
	})
end

local inactive_formspec = table.concat({
	"formspec_version[6]",
	"size[11.75,10.425]",
	"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Furnace"))) .. "]",
	mcl_formspec.get_itemslot_bg_v4(3.5, 0.75, 1, 1),
	"list[context;src;3.5,0.75;1,1;]",

	"image[3.5,2;1,1;default_furnace_fire_bg.png]",

	mcl_formspec.get_itemslot_bg_v4(3.5, 3.25, 1, 1),
	"list[context;fuel;3.5,3.25;1,1;]",

	"image[5.25,2;1.5,1;gui_furnace_arrow_bg.png^[transformR270]",

	mcl_formspec.get_itemslot_bg_v4(7.875, 2, 1, 1, 0.2),
	"list[context;dst;7.875,2;1,1;]",

	"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
	mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
	"list[current_player;main;0.375,5.1;9,3;9]",

	mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
	"list[current_player;main;0.375,9.05;9,1;]",

	"image_button[7.85,0.6;1,1;craftguide_book.png;craftguide;]"..
	"tooltip[craftguide;"..minetest.formspec_escape(S("Recipe book")).."]"..

	"listring[context;dst]",
	"listring[current_player;main]",
	"listring[context;src]",
	"listring[current_player;main]",
	"listring[context;fuel]",
	"listring[current_player;main]",
})

local function give_xp(pos, player)
	local meta = minetest.get_meta(pos)
	local dir = vector.divide(minetest.facedir_to_dir(minetest.get_node(pos).param2),-1.95)
	local xp = meta:get_int("xp")
	if xp > 0 then
		if player then
			mcl_experience.add_xp(player, xp)
		else
			mcl_experience.throw_xp(vector.add(pos, dir), xp)
		end
		meta:set_int("xp", 0)
	end
end

local function is_fuel(stack,factor)
	local teststack = ItemStack(stack)
	teststack:set_count(1)
	local output, _ = minetest.get_craft_result({method="fuel", width=1, items={teststack}})
	if output.time ~= 0 then
		return output.time / (factor or 1)
	end
end

local function is_cookable(stack,factor)
	local teststack = ItemStack(stack)
	teststack:set_count(1)
	local output = minetest.get_craft_result({method = "cooking", width = 1, items = {teststack}})
	if output.time ~= 0 then
		return output.time / (factor or 1),output.item
	end
end

local function get_cook_factor(item,fgroups)
	if not fgroups then return 1 end
	for fg,ff in pairs(fgroups) do
		if minetest.get_item_group(item:get_name(),fg) > 0 then return ff end
	end
end

local function get_furnace_stacks(inv)
	if inv then
		return { ["fuel"]=inv:get_stack("fuel", 1),["src"]=inv:get_stack("src", 1),["dst"]= inv:get_stack("dst", 1) }
	end
end

local function furnace_activate(pos)
	local node = minetest.get_node(pos)
	if node.name:find("_active") then return end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local f = get_furnace_stacks(inv)
	local cookable, item = is_cookable(f.src)
	if item and cookable and is_fuel(f.fuel) and inv:room_for_item("dst",item) then
		node.name=node.name.."_active"
		if minetest.registered_nodes[node.name] then
			minetest.swap_node(pos,node)
			minetest.get_node_timer(pos):start(0)
		end
	end
end

local function furnace_deactivate(pos)
	local node = minetest.get_node(pos)
	node.name=node.name:gsub("_active","")
	if minetest.registered_nodes[node.name] then
		local meta = minetest.get_meta(pos)
		meta:set_string("action","")
		meta:set_int("burning_elapsed",0)
		meta:set_int("cooking_elapsed",0)
		meta:set_string("fuel_item","")
		meta:set_string("formspec", inactive_formspec)
		minetest.get_node_timer(pos):stop()
		minetest.swap_node(pos,node)
	end
end

--[[
local function furnace_is_active(pos)
	local node = minetest.get_node(pos)
	if node.name:find("_active") then return true end
end
--]]

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		-- Special case: empty bucket (not a fuel, but used for sponge drying)
		if stack:get_name() == "mcl_buckets:empty" then
			if inv:get_stack(listname, index):get_count() == 0 then
				return 1
			else
				return 0
			end
		end
		if is_fuel(stack) then
			return stack:get_count()
		end
		return 0
	elseif listname == "src" then
		local def = minetest.registered_nodes[minetest.get_node(pos).name]
		if not get_cook_factor(stack,def._mcl_furnace_groups) then return 0 end
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	end
	return stack:get_count()
end

local function on_metadata_inventory_take(pos, listname, index, stack, player)
	if listname == "dst" then
		furnace_activate(pos)
		give_xp(pos, player)
		if stack:get_name() == "mcl_core:iron_ingot" then
			awards.unlock(player:get_player_name(), "mcl:acquireIron")
		elseif stack:get_name() == "mcl_mobitems:cod_cooked" then
			awards.unlock(player:get_player_name(), "mcl:cookFish")
		end
	end
end

local function on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if from_list == "dst" then
		give_xp(pos, player)
	end
end

local function update_formspec(pos,node)
	local meta = minetest.get_meta(pos)
	local def = minetest.registered_nodes[node.name]
	local inv = meta:get_inventory()
	local f = get_furnace_stacks(inv)
	local factor = get_cook_factor(f.src,def._mcl_furnace_groups)
	local fuel_time = is_fuel(ItemStack(meta:get_string("fuel_item")),factor)
	local cook_time, _ = is_cookable(f.src,factor)
	local burning_elapsed = meta:get_int("burning_elapsed")
	local cooking_elapsed = meta:get_int("cooking_elapsed")
	if cook_time and fuel_time then
		local fire_anim = get_anim("mcl_furnaces_fire_animated.png",fuel_time,burning_elapsed)
		local arrow_anim = get_anim("mcl_furnaces_arrow_animated.png",cook_time,cooking_elapsed)
		meta:set_string("fire_anim",fire_anim)
		meta:set_string("arrow_anim",arrow_anim)
		meta:set_string("formspec", active_formspec(def.description:split("\n")[1],fire_anim,arrow_anim))
	end
end

mcl_furnaces.tpl_furnace = {
	description = S("Furnace"),
	_tt_help = S("Uses fuel to smelt or cook items"),
			S([[
				Use the furnace to open the furnace menu.
				Place a furnace fuel in the lower slot and the source material in the upper slot.
				The furnace will slowly use its fuel to smelt the item.
				The result will be placed into the output slot at the right side.
			]]).."\n"..
			S("Use the recipe book to see what you can smelt, what you can use as fuel and how long it will burn."),
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png", "default_stone.png^mcl_furnaces_furnace_front.png",
	},
	paramtype2 = "facedir",
	paramtype = "light",
	groups = {pickaxey=1, container=4, deco_block=1, material_stone=1},
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if node.name:find("_active") then
			update_formspec(pos,node)
		end
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta
		meta:from_table(oldmetadata)
		local inv =meta:get_inventory()
		for _, listname in ipairs({"src", "dst", "fuel"}) do
			local stack = inv:get_stack(listname, 1)
			if not stack:is_empty() then
				local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2:to_table())
	end,
	on_destruct = function(pos)
		give_xp(pos)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not minetest.get_node(pos).name:find("_active") then
			furnace_activate(pos)
		end
	end,
	on_metadata_inventory_move = on_metadata_inventory_move,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.craftguide then
			mcl_craftguide.show(sender:get_player_name())
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", inactive_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("fuel", 1)
		inv:set_size("dst", 1)
	end,
	on_rotate = screwdriver.rotate_simple,
	after_rotate = function(pos)
		local node = minetest.get_node(pos)
		if node.name == "mcl_furnaces:furnace" then
			return
		end
	end,
	_mcl_blast_resistance = 3.5,
	_mcl_hardness = 3.5,
}

mcl_furnaces.tpl_furnace_active = table.merge(mcl_furnaces.tpl_furnace,{
	groups = table.merge(mcl_furnaces.tpl_furnace.groups,{not_in_creative_inventory=1}),
	light_source = 13,
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png", "mcl_stone_stone.png^mcl_furnaces_furnace_front_active.png",
	},
	on_timer = function(pos, elapsed)
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local f = get_furnace_stacks(inv)
		local factor = get_cook_factor(f.src,def._mcl_furnace_groups)
		local cook_time, _ = is_cookable(f.src,factor)
		local burning_elapsed = meta:get_int("burning_elapsed")
		local cooking_elapsed = meta:get_int("cooking_elapsed")
		local new_time
		local action = meta:get_string("action")
		local fuel = ItemStack(meta:get_string("fuel_item"))
		local fuel_time = is_fuel(fuel,factor)
		if cook_time and not fuel_time then
			if is_fuel(f.fuel) then
				meta:set_string("fuel_item",f.fuel:get_name())
				fuel_time = is_fuel(f.fuel)
				action = "fuel"
			end
		end
		if not factor or not fuel_time then
			furnace_deactivate(pos)
			return false
		end
		if action == "fuel" then
			if f.src:is_empty() then
				furnace_deactivate(pos,node)
				return false
			end
			if cook_time and fuel_time then
				burning_elapsed = 0
				cooking_elapsed = cooking_elapsed + elapsed
				meta:set_int("cooking_elapsed",cooking_elapsed)
				meta:set_int("burning_elapsed",burning_elapsed)
				if cook_time - cooking_elapsed < fuel_time then
					new_time = cook_time - cooking_elapsed
					meta:set_string("action","cook")
				else
					new_time = fuel_time
					meta:set_string("action","fuel")
				end
				meta:set_string("fuel_item",f.fuel:get_name())
				f.fuel:take_item()
				inv:set_stack("fuel",1,f.fuel)
			else
				meta:set_string("action","")
			end
		elseif action == "cook" then
			local cooked,after = minetest.get_craft_result({method = "cooking", width = 1, items = {f.src}})
			if inv:room_for_item("dst",cooked.item) then
				inv:add_item("dst", cooked.item)
				inv:set_stack("src", 1, after.items[1])
				f.src:take_item()
			end
			if cook_time and fuel_time then
				cooking_elapsed = 0
				burning_elapsed = burning_elapsed + elapsed
				meta:set_int("burning_elapsed",burning_elapsed)
				meta:set_int("cooking_elapsed",cooking_elapsed)
				if cook_time < fuel_time - burning_elapsed then
					new_time = cook_time
					meta:set_string("action","cook")
				else
					new_time = fuel_time - burning_elapsed
					meta:set_string("action","fuel")
				end
			else
				meta:set_string("action","")
			end
		elseif fuel_time and cook_time then
			if cook_time < fuel_time then
				new_time = cook_time
				meta:set_string("action","cook")
			else
				new_time = fuel_time
				meta:set_string("action","fuel")
			end
		end
		if new_time then
			meta:set_int("xp", meta:get_int("xp") + math.floor(elapsed))
			local timer = minetest.get_node_timer(pos)
			timer:start(new_time)
			update_formspec(pos,node)
			return false
		end
		update_formspec(pos,node)
		return true --if all failed restart the last timer so it can sort itsself out
	end,
})

function mcl_furnaces.register_furnace(name,overrides)
	overrides = overrides or {}
	local normal = table.copy(overrides.normal or {})
	local active = table.copy(overrides.active or {})
	overrides.normal = nil
	overrides.active = nil
	minetest.register_node("mcl_furnaces:"..name,table.merge(mcl_furnaces.tpl_furnace,overrides,normal or {}))
	minetest.register_node("mcl_furnaces:"..name.."_active",table.merge(mcl_furnaces.tpl_furnace_active,overrides,active or {}))
end
