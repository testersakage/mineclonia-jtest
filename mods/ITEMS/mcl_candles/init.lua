local S = minetest.get_translator("mcl_candles")

local candleboxes = {
	{-0.0625, -0.5, -0.0625, 0.0625, -0.125, 0.0625},
	{-0.15625, -0.5, -0.09375, 0.15625, -0.125, 0.09375},
	{-3/16, -8/16, -3/16, 2/16, -2/16, 2/16},
	{-3/16, -8/16, -3/16, 3/16, -2/16, 3/16}
}

local tpl_candle = {
	_mcl_blast_resistance = 0.1,
	_mcl_hardness = 0.1,
	_on_dye_place = function(pos, color)
		local node = minetest.get_node(pos)
		node.param2 = mcl_dyes.colors[color].palette_index
		minetest.swap_node(pos, node)
	end,
	_on_ignite = function(player, pointed_thing)
		local n = minetest.get_node(pointed_thing.under)
		local g = minetest.get_item_group(n.name, "candles")
		if g > 0 then
			n.name = "mcl_candles:candle_lit_"..tostring(g)
			minetest.swap_node(pointed_thing.under, n)
			return true
		end
	end,
	description = S("Candle"),
	drawtype = "mesh",
	groups = {
		axey = 1, candles = 1, deco_block = 1, dig_by_piston = 1, handy = 1, not_solid = 1, pickaxey = 1,
		shearsy = 1, shovely = 1, swordy = 1, unlit_candles = 1
	},
	inventory_image = "mcl_candles_item.png",
	is_ground_content = false,
	node_placement_prediction = "",
	palette = "mcl_dyes_palette.png",
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
			name = "fire_basic_flame_animated.png"
        }
    }
}

function tpl_candle.on_place(itemstack, placer, pointed_thing)
	if not placer then return end
	if mcl_util.check_position_protection(pointed_thing.under, placer) then return end
	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if rc ~= nil then return rc end

	local unode = minetest.get_node(pointed_thing.under)

	local g = minetest.get_item_group(unode.name, "candles")
	if g > 0 then
		if g < #candleboxes then
			unode.name = "mcl_candles:candle_"..tostring(math.min(4, g + 1))
			unode.param2 = itemstack:get_meta():get("palette_index")
			minetest.swap_node(pointed_thing.under, unode)
			if not minetest.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		end
	else
		return minetest.item_place_node(itemstack, placer, pointed_thing)
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

	local g = minetest.get_item_group(node.name, "lit_candles")
	if g > 0 then
		node.name = "mcl_candles:candle_"..tostring(g)
		minetest.swap_node(pos, node)
	end
end

for i = 1, 2 do
	local candle_n = {
		collision_box = {fixed = candleboxes[i], type = "fixed"},
		drop = "mcl_candles:candle_1".." "..tostring(i),
		mesh = "mcl_candles_candle_"..tostring(i)..".obj",
		selection_box = {fixed = candleboxes[i], type = "fixed"}
	}
	local creative_group
	if i ~= 1 then creative_group = {not_in_creative_inventory = 1} end
	minetest.register_node("mcl_candles:candle_"..i, table.merge(tpl_candle, candle_n, {
		_get_all_virtual_items = function ()
			local output = {deco = {}}
			if i == 1 then
				for _, colordef in pairs(mcl_dyes.colors) do
					local stack = ItemStack("mcl_candles:candle_1")
					stack:get_meta():set_int("palette_index", colordef.palette_index)
					stack:get_meta():set_string("description", S("@1 Candle", colordef.readable_name))
					local str_meta = stack:to_string()
					table.insert(output.deco, str_meta)
				end
			end
			return output
		end,
		groups = table.merge(tpl_candle.groups, {candles = i, unlit_candles = i}, creative_group),
	}))
	minetest.register_node("mcl_candles:candle_lit_"..i, table.merge(tpl_candle, tpl_lit_candle, candle_n, {
		_on_ignite = nil,
		groups = table.merge(tpl_lit_candle.groups, {candles = i, lit_candles = i}),
		light_source = 3 * i,
		on_rightclick = extinguish,
	}))
end

local function candle_craft(itemstack, player, old_craft_grid, craft_inv)
	local i = 0
	local dye, candle
	for _, stack in pairs(old_craft_grid) do
		if minetest.get_item_group(stack:get_name(), "candles") > 0 then
			candle = stack
			i = i + 1
		elseif minetest.get_item_group(stack:get_name(), "dye") > 0 then
			dye = stack
			i = i + 1
		end
	end
	if dye and candle and i == 2 then
		local cdef = mcl_dyes.colors[dye:get_definition()._color]
		local r = ItemStack(minetest.itemstring_with_palette(candle, cdef.palette_index))
		r:get_meta():set_string("description", S("@1 Candle", cdef.readable_name))
		return r
	end
end

minetest.register_craft_predict(candle_craft)
minetest.register_on_craft(candle_craft)

minetest.register_craft({
	output = "mcl_candles:candle_1",
	recipe = {
		{"mcl_mobitems:string"},
		{"mcl_honey:honeycomb"}
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_candles:candle_1",
	recipe = {
		"group:candles",
		"group:dye",
	}
})
