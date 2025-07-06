mcl_loot_new.register_loot_table("chest/ruined_portal", {
    pools = {
        {
            rolls = {min=4, max=8},
            entries = {
                {
                    type = "item",
                    name = "mcl_core:iron_nugget",
                    weight = 40,
                    functions = {{["function"] = "set_count", count={min=9, max=18}}}
                },
                {
                    type = "item",
                    name = "mcl_core:flint",
                    weight = 40,
                    functions = {{["function"] = "set_count", count={min=1, max=4}}}
                },
                {
                    type = "item",
                    name = "mcl_core:obsidian",
                    weight = 40,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
                },
                {
                    type = "item",
                    name = "mcl_fire:fire_charge",
                    weight = 40,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_fire:flint_and_steel",
                    weight = 40,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_core:gold_nugget",
                    weight = 15,
                    functions = {{["function"] = "set_count", count={min=4, max=24}}}
                },
                {
                    type = "item",
                    name = "mcl_core:apple_gold",
                    weight = 15,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_tools:axe_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:hoe_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_tools:pick_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_tools:shovel_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_tools:sword_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:helmet_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:chestplate_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:leggings_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_armor:boots_gold",
                    weight = 15,
                    functions = {{["function"] = "enchant_randomly", options={"infinity","punch","frost_walker","luck_of_the_sea","projectile_protection","blast_protection","fire_protection","protection","flame","fortune","silk_touch","feather_falling","piercing","thorns","curse_of_binding","fire_aspect","power","quick_charge","lure","efficiency","respiration","breach","density","smite","multishot","wind_burst","bane_of_arthropods","sharpness","unbreaking","mending","knockback","curse_of_vanishing","depth_strider","looting"}}}
                },
                {
                    type = "item",
                    name = "mcl_potions:speckled_melon",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=4, max=12}}}
                },
                {
                    type = "item",
                    name = "mcl_farming:carrot_item_gold",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=4, max=12}}}
                },
                {
                    type = "item",
                    name = "mcl_core:gold_ingot",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=2, max=8}}}
                },
                {
                    type = "item",
                    name = "mcl_clock:clock",
                    weight = 5,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_pressureplates:pressure_plate_light_off",
                    weight = 5,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_mobitems:gold_horse_armor",
                    weight = 5,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_core:goldblock",
                    weight = 1,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
                },
                {
                    type = "item",
                    name = "mcl_bells:bell",
                    weight = 1,
                    functions = {{["function"] = "set_count", count=1}}
                },
                {
                    type = "item",
                    name = "mcl_core:apple_gold_enchanted",
                    weight = 1,
                    functions = {{["function"] = "set_count", count=1}}
                },
            }
        },
        {
            rolls = 1,
            entries = {
                {
                    type = "item",
                    name = "mcl_compass:lodestone",
                    weight = 2,
                    functions = {{["function"] = "set_count", count={min=1, max=2}}}
                },
                {
                    type = "empty",
                    weight = 1,
                },
            }
        }
    }
})