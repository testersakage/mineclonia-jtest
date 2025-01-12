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

local craft_defs = {
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

for i = 1, 8 do
	-- 5 or less dyes
	if i <= 5 then
		-- 2 effect modifiers, 1 shape modifier and gunpowder
		core.register_craft(table.merge(craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier",
				"group:firework_effect_modifier",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 6 or less dyes
	if i <= 6 then
		-- 1 effect modifier, 1 shape modifiers and gunpowder
		core.register_craft(table.merge(craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier",
				"group:firework_effect_modifier"
			})
		}))
		-- 2 effect modifiers and gunpowder
		core.register_craft(table.merge(craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_effect_modifier",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 7 or less dyes
	if i <= 7 then
		-- 1 shape modifier and gunpowder
		core.register_craft(table.merge(craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_shape_modifier"
			})
		}))
		-- 1 effect modifier and gunpowder
		core.register_craft(table.merge(craft_defs, {
			recipe = insert_dyes(i, {
				"mcl_mobitems:gunpowder",
				"group:firework_effect_modifier"
			})
		}))
	end
	-- 8 or less dyes (only dyes and gunpowder)
	core.register_craft(table.merge(craft_defs, {
		recipe = insert_dyes(i, {"mcl_mobitems:gunpowder"})
	}))
end
--[[
local function firework_craft(_, _, old_craft_grid, _)
	local shape
	local colors = {}

	for _, stack in pairs(old_craft_grid) do
		local shape_index = core.get_item_group(stack:get_name(), "firework_shape_modifier")

		if shape then return end

		if shape_index > 0 then
			shape = mcl_fireworks.registered_shapes[shape_index]
		else
			shape = "default"
		end

		if core.get_item_group(stack:get_name(), "dye") > 0 then
			table.insert(colors, stack:get_definition().rgb)
		end
	end
end

core.register_on_craft(firework_craft)
core.register_craft_predict(firework_craft)
]]
