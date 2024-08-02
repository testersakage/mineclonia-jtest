minetest.register_craft({
	output = "mcl_copper:block_raw",
	recipe = {
		{ "mcl_copper:raw_copper", "mcl_copper:raw_copper", "mcl_copper:raw_copper" },
		{ "mcl_copper:raw_copper", "mcl_copper:raw_copper", "mcl_copper:raw_copper" },
		{ "mcl_copper:raw_copper", "mcl_copper:raw_copper", "mcl_copper:raw_copper" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block",
	recipe = {
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_cut 4",
	recipe = {
		{ "mcl_copper:block", "mcl_copper:block" },
		{ "mcl_copper:block", "mcl_copper:block" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_cut_preserved 4",
	recipe = {
		{ "mcl_copper:block_preserved", "mcl_copper:block_preserved" },
		{ "mcl_copper:block_preserved", "mcl_copper:block_preserved" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_cut 4",
	recipe = {
		{ "mcl_copper:block_exposed", "mcl_copper:block_exposed" },
		{ "mcl_copper:block_exposed", "mcl_copper:block_exposed" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_cut_preserved 4",
	recipe = {
		{ "mcl_copper:block_exposed_preserved", "mcl_copper:block_exposed_preserved" },
		{ "mcl_copper:block_exposed_preserved", "mcl_copper:block_exposed_preserved" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_cut 4",
	recipe = {
		{ "mcl_copper:block_oxidized", "mcl_copper:block_oxidized" },
		{ "mcl_copper:block_oxidized", "mcl_copper:block_oxidized" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_cut_preserved 4",
	recipe = {
		{ "mcl_copper:block_oxidized_preserved", "mcl_copper:block_oxidized_preserved" },
		{ "mcl_copper:block_oxidized_preserved", "mcl_copper:block_oxidized_preserved" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_cut 4",
	recipe = {
		{ "mcl_copper:block_weathered", "mcl_copper:block_weathered" },
		{ "mcl_copper:block_weathered", "mcl_copper:block_weathered" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_cut_preserved 4",
	recipe = {
		{ "mcl_copper:block_weathered_preserved", "mcl_copper:block_weathered_preserved" },
		{ "mcl_copper:block_weathered_preserved", "mcl_copper:block_weathered_preserved" },
	},
})

minetest.register_craft({
	output = "mcl_copper:block_grate 4",
	recipe = {
		{ "", "mcl_copper:block", "" },
		{ "mcl_copper:block", "", "mcl_copper:block" },
		{ "", "mcl_copper:block", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_grate_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_preserved", "" },
		{ "mcl_copper:block_preserved", "", "mcl_copper:block_preserved" },
		{ "", "mcl_copper:block_preserved", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_grate 4",
	recipe = {
		{ "", "mcl_copper:block_exposed", "" },
		{ "mcl_copper:block_exposed", "", "mcl_copper:block_exposed" },
		{ "", "mcl_copper:block_exposed", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_grate_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_exposed_preserved", "" },
		{ "mcl_copper:block_exposed_preserved", "", "mcl_copper:block_exposed_preserved" },
		{ "", "mcl_copper:block_exposed_preserved", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_grate 4",
	recipe = {
		{ "", "mcl_copper:block_weathered", "" },
		{ "mcl_copper:block_weathered", "", "mcl_copper:block_weathered" },
		{ "", "mcl_copper:block_weathered", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_grate_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_weathered_preserved", "" },
		{ "mcl_copper:block_weathered_preserved", "", "mcl_copper:block_weathered_preserved" },
		{ "", "mcl_copper:block_weathered_preserved", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_grate 4",
	recipe = {
		{ "", "mcl_copper:block_oxidized", "" },
		{ "mcl_copper:block_oxidized", "", "mcl_copper:block_oxidized" },
		{ "", "mcl_copper:block_oxidized", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_grate_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_oxidized_preserved", "" },
		{ "mcl_copper:block_oxidized_preserved", "", "mcl_copper:block_oxidized_preserved" },
		{ "", "mcl_copper:block_oxidized_preserved", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_chiseled",
	recipe = {
		{ "mcl_stairs:slab_copper_cut" },
		{ "mcl_stairs:slab_copper_cut" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_chiseled_preserved",
	recipe = {
		{ "mcl_stairs:slab_copper_cut_preserved" },
		{ "mcl_stairs:slab_copper_cut_preserved" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_chiseled",
	recipe = {
		{ "mcl_stairs:slab_copper_exposed_cut" },
		{ "mcl_stairs:slab_copper_exposed_cut" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_exposed_chiseled_preserved",
	recipe = {
		{ "mcl_stairs:slab_copper_exposed_cut_preserved" },
		{ "mcl_stairs:slab_copper_exposed_cut_preserved" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_chiseled",
	recipe = {
		{ "mcl_stairs:slab_copper_weathered_cut" },
		{ "mcl_stairs:slab_copper_weathered_cut" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_weathered_chiseled_preserved",
	recipe = {
		{ "mcl_stairs:slab_copper_weathered_cut_preserved" },
		{ "mcl_stairs:slab_copper_weathered_cut_preserved" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_chiseled",
	recipe = {
		{ "mcl_stairs:slab_copper_oxidized_cut" },
		{ "mcl_stairs:slab_copper_oxidized_cut" }
	}
})

minetest.register_craft({
	output = "mcl_copper:block_oxidized_chiseled_preserved",
	recipe = {
		{ "mcl_stairs:slab_copper_oxidized_cut_preserved" },
		{ "mcl_stairs:slab_copper_oxidized_cut_preserved" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_off 4",
	recipe = {
		{ "", "mcl_copper:block", "" },
		{ "mcl_copper:block", "mcl_mobitems:blaze_rod", "mcl_copper:block" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_off_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_preserved", "" },
		{ "mcl_copper:block_preserved", "mcl_mobitems:blaze_rod", "mcl_copper:block_preserved" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_exposed_off 4",
	recipe = {
		{ "", "mcl_copper:block_exposed", "" },
		{ "mcl_copper:block_exposed", "mcl_mobitems:blaze_rod", "mcl_copper:block_exposed" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_exposed_off_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_exposed_preserved", "" },
		{ "mcl_copper:block_exposed_preserved", "mcl_mobitems:blaze_rod", "mcl_copper:block_exposed_preserved" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_weathered_off 4",
	recipe = {
		{ "", "mcl_copper:block_weathered", "" },
		{ "mcl_copper:block_weathered", "mcl_mobitems:blaze_rod", "mcl_copper:block_weathered" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_weathered_off_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_weathered_preserved", "" },
		{ "mcl_copper:block_weathered_preserved", "mcl_mobitems:blaze_rod", "mcl_copper:block_weathered_preserved" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_oxidized_off 4",
	recipe = {
		{ "", "mcl_copper:block_oxidized", "" },
		{ "mcl_copper:block_oxidized", "mcl_mobitems:blaze_rod", "mcl_copper:block_oxidized" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:bulb_oxidized_off_preserved 4",
	recipe = {
		{ "", "mcl_copper:block_oxidized_preserved", "" },
		{ "mcl_copper:block_oxidized_preserved", "mcl_mobitems:blaze_rod", "mcl_copper:block_oxidized_preserved" },
		{ "", "mesecons:redstone", "" }
	}
})

minetest.register_craft({
	output = "mcl_copper:door 3",
	recipe = {
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" }
	}
})

minetest.register_craft({
	output = "mcl_copper:trapdoor 2",
	recipe = {
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
		{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" }
	}
})

local waxable_blocks = { "block", "block_cut", "block_exposed", "block_exposed_cut", "block_weathered", "block_weathered_cut", "block_oxidized", "block_oxidized_cut" }

for _, w in ipairs(waxable_blocks) do
	minetest.register_craft({
		output = "mcl_copper:"..w.."_preserved",
		recipe = {
			{ "mcl_copper:"..w, "mcl_honey:honeycomb" },
		},
	})
end

minetest.register_craft({
	output = "mcl_copper:copper_ingot 9",
	recipe = {
		{ "mcl_copper:block" },
	},
})

minetest.register_craft({
	output = "mcl_copper:raw_copper 9",
	recipe = {
		{ "mcl_copper:block_raw" },
	},
})
