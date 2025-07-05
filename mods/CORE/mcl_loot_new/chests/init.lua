local modpath = core.get_modpath(core.get_current_modname())
local filepath = modpath .. "/chests/"

mcl_loot_new.register_loot_table("test_loot", {
    pools = {
        {
            rolls = 1,
            entries = {
                {
                    type = "item",
                    name = "mcl_core:obsidian",
                    functions = {
                        {
                            ["function"] = "set_count",
                            count = {min=4, max=10}
                        }
                    }
                },
                {
                    type = "item",
                    name = "mcl_core:wood",
                    functions = {
                        {
                            ["function"] = "set_count",
                            count = 1
                        }
                    }
                }
            }
        }
    }
})

dofile(filepath.."shipwreck_treasure.lua")


--chests/shipwreck_map
--chests/shipwreck_supply
--chests/shipwreck_treasure