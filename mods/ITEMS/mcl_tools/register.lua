local S = minetest.get_translator("mcl_tools")

local shovel_use = S("To turn a grass block into a grass path, hold the shovel in your hand, then use (rightclick) the top or side of a grass block. This only works when there's air above the grass block.")

--Wood Set
mcl_tools.register_set({
    name = "wood",
    craftable = true,
    material = "group:wood",
    uses = 60,
    level = 1,
    speed = 2,
    max_drop_level = 1,
    groups = { dig_class_speed = 2, enchantability = 15 }
}, {
    ["pick"] = {
        description = S("Wooden Pickaxe"),
        image = "default_tool_woodpick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 2 }
        }
    },
    ["shovel"] = {
        description = S("Wooden Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_woodshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 2 }
        }
    },
    ["sword"] = {
        description = S("Wooden Sword"),
        image = "default_tool_woodsword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 4 }
        }
    },
    ["axe"] = {
        description = S("Wooden Axe"),
        image = "default_tool_woodaxe.png",
        toolcaps = {
            full_punch_interval = 1.25,
            damage_groups = { fleshy = 2 }
        }
    }
}, { _doc_items_hidden = false, _mcl_burntime = 10 })

--Stone Set
mcl_tools.register_set({
    name = "stone",
    craftable = true,
    material = "group:cobble",
    uses = 132,
    level = 3,
    speed = 4,
    groups = { dig_class_speed = 3, enchantability = 5 },
    max_drop_level = 3
}, {
    ["pick"] = {
        description = S("Stone Pickaxe"),
        image = "default_tool_stonepick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 3 }
        }
    },
    ["shovel"] = {
        description = S("Stone Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_stoneshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 3 }
        }
    },
    ["sword"] = {
        description = S("Stone Sword"),
        image = "default_tool_stonesword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 5 }
        }
    },
    ["axe"] = {
        description = S("Stone Axe"),
        image = "default_tool_stoneaxe.png",
        toolcaps = {
            full_punch_interval = 1.25,
            damage_groups = { fleshy = 9 }
        }
    }
})

--Iron Set
mcl_tools.register_set({
    name = "iron",
    craftable = true,
    material = "mcl_core:iron_ingot",
    uses = 251,
    level = 4,
    speed = 6,
    groups = { dig_class_speed = 4, enchantability = 14 },
    max_drop_level = 4
}, {
    ["pick"] = {
        description = S("Iron Pickaxe"),
        image = "default_tool_steelpick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 4 }
        }
    },
    ["shovel"] = {
        description = S("Iron Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_steelshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 4 }
        }
    },
    ["sword"] = {
        description = S("Iron Sword"),
        image = "default_tool_steelsword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 6 }
        }
    },
    ["axe"] = {
        description = S("Iron Axe"),
        image = "default_tool_steelaxe.png",
        toolcaps = {
            full_punch_interval = 1.11111111,
            damage_groups = { fleshy = 9 }
        }
    }
}, { _mcl_cooking_output = "mcl_core:iron_nugget" })

--Gold Set
mcl_tools.register_set({
    name = "gold",
    craftable = true,
    material = "mcl_core:gold_ingot",
    uses = 33,
    level = 2,
    speed = 12,
    groups = { dig_class_speed = 6, enchantability = 22 },
    max_drop_level = 2
}, {
    ["pick"] = {
        description = S("Golden Pickaxe"),
        image = "default_tool_goldpick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 2 }
        }
    },
    ["shovel"] = {
        description = S("Golden Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_goldshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 2 }
        }
    },
    ["sword"] = {
        description = S("Golden Sword"),
        image = "default_tool_goldsword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 4 }
        }
    },
    ["axe"] = {
        description = S("Golden Axe"),
        image = "default_tool_goldaxe.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 7 }
        }
    }
}, { _mcl_cooking_output = "mcl_core:gold_nugget" })

--Diamond Set
mcl_tools.register_set({
    name = "diamond",
    craftable = true,
    material = "mcl_core:diamond",
    uses = 1562,
    level = 5,
    speed = 8,
    groups = { dig_class_speed = 5, enchantability = 10 },
    max_drop_level = 5
}, {
    ["pick"] = {
        description = S("Diamond Pickaxe"),
        image = "default_tool_diamondpick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 5 }
        }
    },
    ["shovel"] = {
        description = S("Diamond Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_diamondshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 5 }
        }
    },
    ["sword"] = {
        description = S("Diamond Sword"),
        image = "default_tool_diamondsword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 7 }
        }
    },
    ["axe"] = {
        description = S("Diamond Axe"),
        image = "default_tool_diamondaxe.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 9 }
        }
    }
}, { _mcl_upgradable_with = "mcl_nether:netherite_ingot" })

--Netherite Set
mcl_tools.register_set({
    name = "netherite",
    craftable = false,
    material = "mcl_nether:netherite_ingot",
    uses = 2031,
    level = 6,
    speed = 9.5,
    groups = { dig_class_speed = 6, enchantability = 10, fire_immune = 1 },
    max_drop_level = 5
}, {
    ["pick"] = {
        description = S("Netherite Pickaxe"),
        image = "default_tool_netheritepick.png",
        toolcaps = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 6 }
        }
    },
    ["shovel"] = {
        description = S("Netherite Shovel"),
        _doc_items_usagehelp = shovel_use,
        image = "default_tool_netheriteshovel.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 6 }
        }
    },
    ["sword"] = {
        description = S("Netherite Sword"),
        image = "default_tool_netheritesword.png",
        toolcaps = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 9 }
        }
    },
    ["axe"] = {
        description = S("Netherite Axe"),
        image = "default_tool_netheriteaxe.png",
        toolcaps = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 10 }
        }
    }
})
