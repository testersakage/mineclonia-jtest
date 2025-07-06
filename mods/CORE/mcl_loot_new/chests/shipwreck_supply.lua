    mcl_loot_new.register_loot_table("chest/shipwreck_supply", {
    pools = {
        {
            rolls = {min=3, max=10},
            entries = {
                {
                    type = "item",
                    name = "mcl_sus_stew:stew",
                    weight = 10,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_core:paper",
                    weight = 8,
                    functions = {{["function"] = "set_count", count={min=1, max=12}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:wheat_item",
                    weight = 7,
                    functions = {{["function"] = "set_count", count={min=8, max=21}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:carrot_item",
                    weight = 7,
                    functions = {{["function"] = "set_count", count={min=4, max=8}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:potato_item_poison",
                    weight = 7,
                    functions = {{["function"] = "set_count", count={min=2, max=6}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:potato_item",
                    weight = 7,
                    functions = {{["function"] = "set_count", count={min=2, max=6}}}
                },
                {
                    type = "item",
                    name = "mcl_lush_caves:moss",
                    weight = 7,
                    functions = {{["function"] = "set_count", count={min=1, max=4}}}
                },
                {
                    type = "item",
                    name = "mcl_core:coal_lump",
                    weight = 6,
                    functions = {{["function"] = "set_count", count={min=2, max=8}}}
                },
                {
                    type = "item",
                    name = "mcl_mobitems:rotten_flesh",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=5, max=24}}}
                },
                {
                    type = "item",
                    name = "mcl_mobitems:gunpowder",
                    weight = 3,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:helmet_leather",
                    weight = 3,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:chestplate_leather",
                    weight = 3,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:leggings_leather",
                    weight = 3,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:boots_leather",
                    weight = 3,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_bamboo:bamboo_shoot",
                    weight = 2,
                    functions = {{["function"] = "set_count", count={min=1, max=3}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:pumpkin",
                    weight = 2,
                    functions = {{["function"] = "set_count", count={min=1, max=3}}}
                },
                {
                    type = "item",
                    name = "mcl_tnt:tnt",
                    weight = 1,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
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