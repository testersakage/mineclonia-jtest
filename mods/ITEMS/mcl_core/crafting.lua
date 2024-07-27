-- mods/default/crafting.lua

--
-- Crafting definition
--

local function craft_planks(output, input)
	minetest.register_craft({
		output = "mcl_core:"..output.."wood 4",
		recipe = {
			{"mcl_core:"..input},
		}
	})
end

local planks = {
	{"", "oak"},
	{"dark", "dark_oak"},
	{"jungle", "jungle"},
	{"acacia", "acacia"},
	{"spruce", "spruce"},
	{"birch", "birch"}
}

for _, p in pairs(planks) do
	craft_planks(p[1], p[1].."tree")
	craft_planks(p[1], p[1].."tree_bark")
	craft_planks(p[1], "stripped_"..p[2])
	craft_planks(p[1], "stripped_"..p[2].."_bark")
end

minetest.register_craft({
	type = "shapeless",
	output = "mcl_core:mossycobble",
	recipe = { "mcl_core:cobble", "mcl_core:vine" },
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_core:stonebrickmossy",
	recipe = { "mcl_core:stonebrick", "mcl_core:vine" },
})

minetest.register_craft({
	output = "mcl_core:coarse_dirt 4",
	recipe = {
		{"mcl_core:dirt", "mcl_core:gravel"},
		{"mcl_core:gravel", "mcl_core:dirt"},
	}
})
minetest.register_craft({
	output = "mcl_core:coarse_dirt 4",
	recipe = {
		{"mcl_core:gravel", "mcl_core:dirt"},
		{"mcl_core:dirt", "mcl_core:gravel"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_core:granite",
	recipe = {"mcl_core:diorite", "mcl_nether:quartz"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_core:andesite 2",
	recipe = {"mcl_core:diorite", "mcl_core:cobble"},
})

minetest.register_craft({
	output = "mcl_core:diorite 2",
	recipe = {
		{"mcl_core:cobble", "mcl_nether:quartz"},
		{"mcl_nether:quartz", "mcl_core:cobble"},
	}
})
minetest.register_craft({
	output = "mcl_core:diorite 2",
	recipe = {
		{"mcl_nether:quartz", "mcl_core:cobble"},
		{"mcl_core:cobble", "mcl_nether:quartz"},
	}
})

minetest.register_craft({
	output = "mcl_core:stick 4",
	recipe = {
		{"group:wood"},
		{"group:wood"},
	}
})

minetest.register_craft({
	output = "mcl_core:paper 3",
	recipe = {
		{"mcl_core:reeds", "mcl_core:reeds", "mcl_core:reeds"},
	}
})

minetest.register_craft({
	output = "mcl_core:ladder 3",
	recipe = {
		{"mcl_core:stick", "", "mcl_core:stick"},
		{"mcl_core:stick", "mcl_core:stick", "mcl_core:stick"},
		{"mcl_core:stick", "", "mcl_core:stick"},
	}
})

minetest.register_craft({
	output = "mcl_core:apple_gold",
	recipe = {
		{"mcl_core:gold_ingot", "mcl_core:gold_ingot", "mcl_core:gold_ingot"},
		{"mcl_core:gold_ingot", "mcl_core:apple", "mcl_core:gold_ingot"},
		{"mcl_core:gold_ingot", "mcl_core:gold_ingot", "mcl_core:gold_ingot"},
	}
})

minetest.register_craft({
	output = "mcl_core:sugar",
	recipe = {
		{"mcl_core:reeds"},
	}
})

minetest.register_craft({
	output = "mcl_core:bowl 4",
	recipe = {
		{"group:wood", "", "group:wood"},
		{"", "group:wood", ""},
	}
})

minetest.register_craft({
	output = "mcl_core:snow 6",
	recipe = {
		{"mcl_core:snowblock", "mcl_core:snowblock", "mcl_core:snowblock"},
	}
})

minetest.register_craft({
	output = 'mcl_core:packed_ice 1',
	recipe = {
		{'mcl_core:ice', 'mcl_core:ice', 'mcl_core:ice'},
		{'mcl_core:ice', 'mcl_core:ice', 'mcl_core:ice'},
		{'mcl_core:ice', 'mcl_core:ice', 'mcl_core:ice'},
	}
})

--
-- Crafting (tool repair)
--
minetest.register_craft({
	type = "toolrepair",
	additional_wear = -mcl_core.repair,
})
