local S = core.get_translator("mcl_candles")

local candle_boxes = {
	{-0.0625, -0.5, -0.0625, 0.0625, -0.125, 0.0625},
	{-0.15625, -0.5, -0.09375, 0.15625, -0.125, 0.09375},
	{-0.15625, -0.5, -0.15625, 0.15625, -0.125, 0.21875},
	{-0.1875, -0.5, -0.15625, 0.21875, -0.125, 0.21875}
}

local function set_candle_properties(stack, properties)
	stack:get_meta():set_string("description", properties.description)
	stack:get_meta():set_int("palette_index", properties.palette_index)
	stack:get_meta():set_string("inventory_overlay", properties.image)
	stack:get_meta():set_string("wield_overlay", properties.image)
end

local tpl_candle = {
	_mcl_blast_resistance = 0.1,
	_mcl_hardness = 0.1,
	_on_dye_place = function(pos, color)
		local node = core.get_node(pos)
		node.param2 = mcl_dyes.colors[color].palette_index
		core.swap_node(pos, node)
	end,
	_on_ignite = function(player, pointed_thing)
		local n = core.get_node(pointed_thing.under)
		local g = core.get_item_group(n.name, "candles")
		if g > 0 then
			n.name = "mcl_candles:candle_lit_"..tostring(g)
			core.swap_node(pointed_thing.under, n)
			return true
		end
	end,
	_on_set_item_entity = function (stack)
		return stack, {wield_item = stack:to_string()}
	end,
	after_dig_node = function (pos, oldnode, oldmeta)
		local group = core.get_item_group(oldnode.name, "candles")
		local item = ItemStack("mcl_candles:candle_1 " .. group)
		local color_index = oldnode.param2 > 0 and oldnode.param2
		local color = mcl_dyes.palette_index_to_color(tonumber(color_index) - 1)
		if color then
			local color_defs = mcl_dyes.colors[color]
			set_candle_properties(item, {
				description = S("@1 Candle", color_defs.readable_name),
				palette_index = color_defs.palette_index,
				image = "mcl_candles_item_" .. color .. ".png"
			})
		end
		return core.add_item(pos, item)
	end,
	description = S("Candle"),
	drawtype = "mesh",
	drop = "",
	groups = {
		axey = 1, candles = 1, deco_block = 1, dig_by_piston = 1, handy = 1, not_solid = 1, pickaxey = 1,
		shearsy = 1, shovely = 1, swordy = 1, unlit_candles = 1
	},
	inventory_image = "mcl_candles_item.png",
	is_ground_content = false,
	node_placement_prediction = "",
	palette = "mcl_candles_palette.png",
	paramtype = "light",
	paramtype2 = "color",
	sounds = mcl_sounds.node_sound_defaults(),
	sunlight_propagates = true,
	tiles = {"mcl_candles_candle.png", "blank.png"},
	use_texture_alpha = "blend",
	wield_image = "mcl_candles_item.png"
}

local tpl_lit_candle = {
	description = S("Lit Candle"),
	groups = {
		axey = 1, candles = 1, dig_by_piston = 1, handy = 1, lit_candles = 1,
		not_in_creative_inventory = 1, not_solid = 1, pickaxey = 1, shearsy = 1,
		shovely = 1, swordy = 1
	},
    tiles = {
        "mcl_candles_candle.png",
        {
            animation = {
                aspect_h = 16,
				aspect_w = 16,
				length = 5.5,
				type = "vertical_frames"
            },
			color = "white",
			name = "fire_basic_flame_animated.png"
        }
    }
}

function tpl_candle.on_place(itemstack, placer, pointed_thing)
	if not placer then return end

	if mcl_util.check_position_protection(pointed_thing.under, placer) then return end

	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)

	if rc ~= nil then return rc end

	local unode = core.get_node(pointed_thing.under)
	local group = core.get_item_group(unode.name, "candles")

	if group > 0 then
		if group < #candle_boxes then
			local param2 = tonumber(itemstack:get_meta():get("palette_index")) or 0
			unode.name = "mcl_candles:candle_" .. math.min(4, group + 1)
			if param2 == unode.param2 then
				core.swap_node(pointed_thing.under, unode)
			end

			if not core.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		end
	else
		return core.item_place_node(itemstack, placer, pointed_thing)
	end

	return itemstack
end

function extinguish(pos, node, clicker, itemstack, pointed_thing)
	if not clicker then
		return
	end

	if mcl_util.check_position_protection(pos, clicker) then
		return
	end

	local g = core.get_item_group(node.name, "lit_candles")
	if g > 0 then
		node.name = "mcl_candles:candle_"..tostring(g)
		core.swap_node(pos, node)
	end
end

for i = 1, #candle_boxes do
	local candle_n = {
		collision_box = {fixed = candle_boxes[i], type = "fixed"},
		mesh = "mcl_candles_candle_"..tostring(i)..".obj",
		selection_box = {fixed = candle_boxes[i], type = "fixed"}
	}
	local creative_group
	if i ~= 1 then creative_group = {not_in_creative_inventory = 1} end
	core.register_node("mcl_candles:candle_"..i, table.merge(tpl_candle, candle_n, {
		_get_all_virtual_items = function ()
			local output = {deco = {}}
			if i == 1 then
				for color, color_defs in pairs(mcl_dyes.colors) do
					local stack = ItemStack("mcl_candles:candle_1")
					local image = "mcl_candles_item_" .. color .. ".png"
					set_candle_properties(stack, {
						description = S("@1 Candle", color_defs.readable_name),
						palette_index = color_defs.palette_index + 1,
						image = image
					})
					table.insert(output.deco, stack:to_string())
				end
			end
			return output
		end,
		groups = table.merge(tpl_candle.groups, {candles = i, unlit_candles = i}, creative_group),
	}))
	core.register_node("mcl_candles:candle_lit_"..i, table.merge(tpl_candle, tpl_lit_candle, candle_n, {
		_on_ignite = nil,
		_on_wind_charge_hit = function (pos)
			local node = core.get_node(pos)
			local group = core.get_item_group(node.name, "lit_candles")
			node.name = "mcl_candles:candle_" .. group
			core.swap_node(pos, node)
		end,
		groups = table.merge(tpl_lit_candle.groups, {candles = i, lit_candles = i}),
		light_source = 3 * i,
		on_rightclick = extinguish,
	}))
end

local function candle_craft(itemstack, player, old_craft_grid, craft_inv)
	local i = 0
	local dye, candle
	for _, stack in pairs(old_craft_grid) do
		if core.get_item_group(stack:get_name(), "candles") > 0 then
			candle = stack
			i = i + 1
		elseif core.get_item_group(stack:get_name(), "dye") > 0 then
			dye = stack
			i = i + 1
		end
	end
	if dye and candle and i == 2 then
		local cdef = mcl_dyes.colors[dye:get_definition()._color]
		local r = ItemStack(core.itemstring_with_palette(candle, cdef.palette_index + 1))
		r:get_meta():set_string("description", S("@1 Candle", cdef.readable_name))
		return r
	end
end

core.register_craft_predict(candle_craft)
core.register_on_craft(candle_craft)

core.register_craft({
	output = "mcl_candles:candle_1",
	recipe = {
		{"mcl_mobitems:string"},
		{"mcl_honey:honeycomb"}
	}
})

core.register_craft({
	type = "shapeless",
	output = "mcl_candles:candle_1",
	recipe = {
		"group:candles",
		"group:dye",
	}
})
