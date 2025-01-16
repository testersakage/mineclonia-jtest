minetest.register_craft({
	type = "shapeless",
	output = "mcl_fireworks:rocket_1 3",
	recipe = {"mcl_core:paper", "mcl_mobitems:gunpowder"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_fireworks:rocket_2 3",
	recipe = {"mcl_core:paper", "mcl_mobitems:gunpowder", "mcl_mobitems:gunpowder"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_fireworks:rocket_3 3",
	recipe = {"mcl_core:paper", "mcl_mobitems:gunpowder", "mcl_mobitems:gunpowder", "mcl_mobitems:gunpowder"},
})

local star_craft_defs = {
	type = "shapeless",
	output = "mcl_fireworks:star"
}

local function insert_dyes(amount, recipe)
	local result = table.copy(recipe)

	for _ = 1, amount do
		table.insert(result, "group:dye")
	end

	return result
end

local function insert_stars(amount, recipe)
	local result = table.copy(recipe)

	for _ = 1, amount do
		table.insert(result, "mcl_fireworks:star")
	end

	return result
end

for i = 1, 8 do
	-- 5 or less stars/dyes
	if i <= 5 then
		-- Firework rocket
		core.register_craft({
			output = "mcl_fireworks:rocket_3 3",
			recipe = insert_stars(i, {
				"mcl_core:paper", "mcl_mobitems:gunpowder",
				"mcl_mobitems:gunpowder", "mcl_mobitems:gunpowder"
			}),
			type = "shapeless"
		})
		-- Firework star: 2 effect modifiers, 1 shape modifier and gunpowder
		core.register_craft(table.merge(star_craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier",
				"group:firework_effect_modifier",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 6 or less stars/dyes
	if i <= 6 then
		-- Firework rocket
		core.register_craft({
			output = "mcl_fireworks:rocket_2 3",
			recipe = insert_stars(i, {
				"mcl_core:paper", "mcl_mobitems:gunpowder", "mcl_mobitems:gunpowder"
			}),
			type = "shapeless"
		})
		-- Firework star: 1 effect modifier, 1 shape modifiers and gunpowder
		core.register_craft(table.merge(star_craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier",
				"group:firework_effect_modifier"
			})
		}))
		-- Firework star: 2 effect modifiers and gunpowder
		core.register_craft(table.merge(star_craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_effect_modifier",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 7 or less stars/dyes
	if i <= 7 then
		-- Firework rocket
		core.register_craft({
			output = "mcl_fireworks:rocket_1 3",
			recipe = insert_stars(i, {"mcl_core:paper", "mcl_mobitems:gunpowder"}),
			type = "shapeless",
		})
		-- Firework star: 1 shape modifier and gunpowder
		core.register_craft(table.merge(star_craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier"
			})
		}))
		-- Firework star: 1 effect modifier and gunpowder
		core.register_craft(table.merge(star_craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 8 or less dyes (only dyes and gunpowder)
	core.register_craft(table.merge(star_craft_defs, {
		recipe = insert_dyes(i, {"mcl_mobitems:gunpowder"})
	}))
end

local function calculate_color(first, last)
	local av = function(a, b) return (a + b) / 2 end
	return {
		r = av(first.r, last.r),
		g = av(first.g, last.g),
		b = av(first.b, last.b),
    }
end

local function cs_to_table(color)
	return {
		r = tonumber(color:sub(2,3), 16),
		g = tonumber(color:sub(4,5), 16),
		b = tonumber(color:sub(6,7), 16),
	}
end

local spec_to_string = core.colorspec_to_colorstring

local function colorize_overlay(itemstack, colors)
	local result

	for _, color in pairs(colors) do
		if not result then result = cs_to_table(color) end
		result = calculate_color(cs_to_table(spec_to_string(result)), cs_to_table(color))
	end

	result = spec_to_string(result)

	local image = "mcl_fireworks_star_overlay.png^[colorize:" .. result .. ":191"

	itemstack:get_meta():set_string("inventory_overlay", image)
	itemstack:get_meta():set_string("wield_overlay", image)
end

local function firework_craft(itemstack, _, old_craft_grid, _)
	local shape
	local colors, effects = {}, {}

	for _, stack in pairs(old_craft_grid) do
		local name =  stack:get_name()
		local shape_index = core.get_item_group(name, "firework_shape_modifier")
		local effect_index = core.get_item_group(name, "firework_effect_modifier")

		if shape_index > 0 then
			shape = mcl_fireworks.registered_shapes[shape_index]
		end

		if effect_index > 0 then
			table.insert(effects, mcl_fireworks.registered_effects[effect_index])
		end

		if core.get_item_group(name, "dye") > 0 then
			local rgb = mcl_dyes.colors[stack:get_definition()._color].rgb
			table.insert(colors, rgb)
		end
	end

	if not shape then shape = "default" end

	if #colors ~= 0 then
		colorize_overlay(itemstack, colors)
	end

	local meta = itemstack:get_meta()

	meta:set_string("mcl_fireworks:shape", shape)
	meta:set_string("mcl_fireworks:effects", core.serialize(effects))
	meta:set_string("mcl_fireworks:colors", core.serialize(colors))

	tt.reload_itemstack_description(itemstack)

	return itemstack
end

core.register_on_craft(firework_craft)
core.register_craft_predict(firework_craft)
