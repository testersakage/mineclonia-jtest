local S = core.get_translator("mcl_copper")

mcl_armor.register_set({
        name = "copper",
        descriptions = {
                head = S("Copper Helmet"),
                torso = S("Copper Chestplate"),
                legs = S("Copper Leggings"),
                feet = S("Copper Boots"),
        },
        durability = 176,
        enchantability = 8,
        points = {
                head = 2,
                torso = 4,
                legs = 3,
                feet = 1,
        },
        craft_material = "mcl_copper:copper_ingot",
        cook_material = "mcl_core:copper_nugget",
        sound_equip = "mcl_armor_equip_iron",
        sound_unequip = "mcl_armor_unequip_iron",
})
