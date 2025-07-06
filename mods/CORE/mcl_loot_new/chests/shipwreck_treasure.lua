mcl_loot_new.register_loot_table("chest/shipwreck_treasure", {
    pools = {
        {
            rolls = {min=3, max=6},
            entries = {
                {
                    type = "item",
                    name = "mcl_core:iron_ingot",
                    weight = 90,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_core:emerald",
                    weight = 40,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_core:gold_ingot",
                    weight = 10,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_experience:bottle",
                    weight = 5,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_core:diamond",
                    weight = 5,
                    functions = {{["function"] = "set_count", count=1}}
                },
            }
        },
        {
            rolls = {min=2, max=5},
            entries = {
                {
                    type = "item",
                    name = "mcl_core:iron_nugget",
                    weight = 50,
                    functions = {{["function"] = "set_count", count={min=1, max=10}}}
                },
                {
                    type = "item",
                    name = "mcl_core:lapis",
                    weight = 20,
                    functions = {{["function"] = "set_count", count={min=1, max=10}}}
                },
                {
                    type = "item",
                    name = "mcl_core:gold_nugget",
                    weight = 10,
                    functions = {{["function"] = "set_count", count={min=1, max=10}}}
                },
            }
        },
        {
            rolls = 1,
            entries = {
                {
                    type = "item",
                    name = "mcl_armor:coast",
                    weight = 1,
                    functions = {{["function"] = "set_count", count=2}}
                },
                {
                    type = "empty",
                    weight = 5
                }
            }
        }
    }
})