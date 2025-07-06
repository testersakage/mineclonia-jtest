local modpath = core.get_modpath(core.get_current_modname())
local filepath = modpath .. "/chests/"

mcl_loot_new.register_loot_table("test_loot", {
    pools = {
        {
            rolls = 10,
            entries = {
                {
                    type = "item",
                    name = "mcl_core:barrier",
                    functions = {
                        {
                            ["function"] = "set_count",
                            count = 1
                        }
                    }
                },
            }
        }
    }
})

dofile(filepath.."shipwreck_treasure.lua")
dofile(filepath.."shipwreck_supply.lua")
dofile(filepath.."shipwreck_map.lua")
dofile(filepath.."buried_treasure.lua")
dofile(filepath.."ruined_portal.lua")


--chests/shipwreck_map
--chests/shipwreck_supply
--chests/shipwreck_treasure