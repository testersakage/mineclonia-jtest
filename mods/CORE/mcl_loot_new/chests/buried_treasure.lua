mcl_loot_new.register_loot_table("chest/buried_treasure", {
    pools = {
        {
            rolls = 1,
            entries = {
                {
                    type = "item",
                    name = "mcl_mobitems:heart_of_the_sea",
                    weight = 1
                }
            }
        },
        {
            rolls = {min=5, max=8},
            entries = {
                {
                    type = "item",
                    name = "mcl_core:iron_ingot",
                    weight = 20,
                    functions = {{["function"] = "set_count", count={min=1, max=4}}}
                },
                {
                    type = "item",
                    name = "mcl_core:gold_ingot",
                    weight = 10,
                    functions = {{["function"] = "set_count", count={min=1, max=4}}}
                },
                {
                    type = "item",
                    name = "mcl_tnt:tnt",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
                },
            }
        },
        {
            rolls = {min=1, max=4},
            entries = {
                {
                    type = "item",
                    name = "mcl_core:diamond",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
                },
                {
                    type = "item",
                    name = "mcl_ocean:prismarine_crystals",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_core:emerald",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=4, max=8}}}
                },
            }
        },
        {
            rolls = {min=0, max=1},
            entries = {
                {
                    type = "item",
                    name = "mcl_armor:chestplate_leather",
                    weight = 1,
                },
                {
                    type = "item",
                    name = "mcl_tools:sword_iron",
                    weight = 1,
                },
            }
        },
        {
            rolls = 2,
            entries = {
                {
                    type = "item",
                    -- TODO: Rename this to cooked cod???
                    name = "mcl_fishing:fish_cooked",
                    weight = 1,
                    functions = {{["function"] = "set_count", count={min=2, max=4}}}
                },
                {
                    type = "item",
                    name = "mcl_fishing:salmon_cooked",
                    weight = 1,
                    functions = {{["function"] = "set_count", count={min=2, max=4}}}
                },
            }
        },
        {
            rolls = {min=0, max=2},
            entries = {
                {
                    type = "item",
                    name = "mcl_potions:water_breathing",
                    weight = 1,
                }
            }
        }
    }
})


--                     functions = {{["function"] = "set_count", count={min=1, max=12}}}