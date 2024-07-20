
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

mcl_tools = {}

mcl_tools.set = {
	["axe"] = {
		longdesc = S("An axe is your tool of choice to cut down trees, wood-based blocks and other blocks. Axes deal a lot of damage as well, but they are rather slow."),
		groups = { axe = 1, tool = 1 },
		diggroups = { axey = {} }
	},
	["hoe"] = {
		longdesc = S("Hoes are essential tools for growing crops. They are used to create farmland in order to plant seeds on it. Hoes can also be used as very weak weapons in a pinch."),
		groups = { hoe = 1, tool = 1 },
		diggroups = { hoey = {} }
	},
	["pick"] = {
		longdesc = S("Pickaxes are mining tools to mine hard blocks, such as stone. A pickaxe can also be used as weapon, but it is rather inefficient."),
		groups = { pickaxe = 1, tool = 1 },
		diggroups = { pickaxey = {} }
	},
	["shovel"] = {
		longdesc = S("Shovels are tools for digging coarse blocks, such as dirt, sand and gravel. They can also be used to turn grass blocks to grass paths. Shovels can be used as weapons, but they are very weak."),
		groups = { shovel = 1, tool = 1 },
		diggroups = { shovely = {} }
	},
	["sword"] = {
		longdesc = S("Swords are great in melee combat, as they are fast, deal high damage and can endure countless battles. Swords can also be used to cut down a few particular blocks, such as cobwebs."),
		groups = { sword = 1, weapon = 1 },
		diggroups = { swordy = {}, swordy_cobweb = {} }
	}
}

local shears_longdesc = S("Shears are tools to shear sheep and to mine a few block types. Shears are a special mining tool and can be used to obtain the original item from grass, leaves and similar blocks that require cutting.")
local shears_use = S("To shear sheep or carve faceless pumpkins, use the “place” key on them. Faces can only be carved at the side of faceless pumpkins. Mining works as usual, but the drops are different for a few blocks.")

local wield_scale = mcl_vars.tool_wield_scale

local function on_tool_place(itemstack, placer, pointed_thing, tool)
	if pointed_thing.type ~= "node" then return end

	local node = minetest.get_node(pointed_thing.under)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return
	end

	if not placer:get_player_control().sneak and ndef.on_rightclick then
		return minetest.item_place(itemstack, placer, pointed_thing)
	end
	if minetest.is_protected(pointed_thing.under, placer:get_player_name()) then
		minetest.record_protection_violation(pointed_thing.under, placer:get_player_name())
		return itemstack
	end

	if itemstack and type(ndef["_on_"..tool.."_place"]) == "function" then
		local itemstack, no_wear = ndef["_on_"..tool.."_place"](itemstack, placer, pointed_thing)
		if minetest.is_creative_enabled(placer:get_player_name()) or no_wear or not itemstack then
			return itemstack
		end

		-- Add wear using the usages of the tool defined in
		-- _mcl_diggroups. This assumes the tool only has one diggroups
		-- (which is the case in Mineclone).
		local tdef = minetest.registered_tools[itemstack:get_name()]
		if tdef and tdef._mcl_diggroups then
			for group, _ in pairs(tdef._mcl_diggroups) do
				itemstack:add_wear(mcl_autogroup.get_wear(itemstack:get_name(), group))
				return itemstack
			end
		end
		return itemstack
	end

	mcl_offhand.place(placer, pointed_thing)

	return itemstack
end

mcl_tools.tool_place_funcs = {}

for _,tool in pairs({"shovel","shears","axe","sword","pick"}) do
	mcl_tools.tool_place_funcs[tool] = function(itemstack,placer,pointed_thing)
		return on_tool_place(itemstack,placer,pointed_thing,tool)
	end
end

local function get_tool_diggroups(material, toolname)
	local diggroups = mcl_tools.set[toolname].diggroups

	for _, diggroup in pairs(diggroups) do
		diggroup.speed = material.speed
		diggroup.level = material.level
		diggroup.uses = material.uses
	end

	return diggroups
end

---Need comments
---@param material table
---@param tools table
---@param overrides table|nil
function mcl_tools.register_set(material, tools, overrides)
	local mod = minetest.get_current_modname()
	local toolname, punch_attack_uses

	for tool, defs in pairs(tools) do
		toolname = mod..":"..tool.."_"..material.name

		if tool == "sword" then
			punch_attack_uses = material.uses
		else
			punch_attack_uses = material.uses / 2
		end

		table.merge(defs.tool_capabilities, {
			max_drop_level = material.max_drop_level,
			punch_attack_uses = punch_attack_uses
		})

		minetest.register_tool(toolname, table.merge({
			_doc_items_longdesc = mcl_tools.set[tool].longdesc,
			wield_scale = wield_scale,
			groups = table.merge(mcl_tools.set[tool].groups, material.groups),
			sound = { breaks = "default_tool_breaks" },
			on_place = mcl_tools.tool_place_funcs[tool],
			_repair_material = material.material,
			_mcl_toollike_wield = true,
			_mcl_diggroups = get_tool_diggroups(material, tool),
		}, defs, overrides))

		if material.craftable then
			if tool == "pick" then
				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material, material.material, material.material },
						{ "", "mcl_core:stick", "" },
						{ "", "mcl_core:stick", "" }
					}
				})
			elseif tool == "sword" then
				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material },
						{ material.material },
						{ "mcl_core:stick" }
					}
				})
			elseif tool == "axe" then
				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material, material.material },
						{ material.material, "mcl_core:stick" },
						{ "", "mcl_core:stick" }
					},
				})

				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material, material.material, },
						{ "mcl_core:stick", material.material },
						{ "mcl_core:stick", "" }
					}
				})
			elseif tool == "shovel" then
				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material },
						{ "mcl_core:stick" },
						{ "mcl_core:stick" }
					}
				})
			elseif tool == "hoe" then
				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material, material.material },
						{ "", "mcl_core:stick" },
						{ "", "mcl_core:stick" }
					},
				})

				minetest.register_craft({
					output = toolname,
					recipe = {
						{ material.material, material.material, },
						{ "mcl_core:stick", "" },
						{ "mcl_core:stick", "" }
					}
				})
			end
		end
	end
end

--Shears
minetest.register_tool("mcl_tools:shears", {
	description = S("Shears"),
	_doc_items_longdesc = shears_longdesc,
	_doc_items_usagehelp = shears_use,
	inventory_image = "default_tool_shears.png",
	wield_image = "default_tool_shears.png",
	stack_max = 1,
	groups = { tool=1, shears=1, dig_speed_class=4, enchantability=-1, },
	tool_capabilities = {
			full_punch_interval = 0.5,
			max_drop_level=1,
	},
	on_place = mcl_tools.tool_place_funcs.shears,
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		shearsy = { speed = 1.5, level = 1, uses = 238 },
		shearsy_wool = { speed = 5, level = 1, uses = 238 },
		shearsy_cobweb = { speed = 15, level = 1, uses = 238 }
	},
})

minetest.register_craft({
	output = "mcl_tools:shears",
	recipe = {
		{ "mcl_core:iron_ingot", "" },
		{ "", "mcl_core:iron_ingot", },
	}
})

minetest.register_craft({
	output = "mcl_tools:shears",
	recipe = {
		{ "", "mcl_core:iron_ingot" },
		{ "mcl_core:iron_ingot", "" },
	}
})

dofile(modpath.."/mace.lua")
dofile(modpath.."/register.lua")
