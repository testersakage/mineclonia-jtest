mcl_farming = {}

-- IMPORTANT API AND HELPER FUNCTIONS --
-- Contain functions for planting seed, addind plant growth and gourds (melon/pumpkin-like)
dofile(minetest.get_modpath("mcl_farming").."/shared_functions.lua")

dofile(minetest.get_modpath("mcl_farming").."/soil.lua")
dofile(minetest.get_modpath("mcl_farming").."/hoes.lua")
dofile(minetest.get_modpath("mcl_farming").."/wheat.lua")
dofile(minetest.get_modpath("mcl_farming").."/pumpkin.lua")
dofile(minetest.get_modpath("mcl_farming").."/melon.lua")
dofile(minetest.get_modpath("mcl_farming").."/carrots.lua")
dofile(minetest.get_modpath("mcl_farming").."/potatoes.lua")
dofile(minetest.get_modpath("mcl_farming").."/beetroot.lua")
dofile(minetest.get_modpath("mcl_farming").."/sweet_berry.lua")

local S = minetest.get_translator(minetest.get_current_modname())

-- Developer Seeds
minetest.register_node("mcl_farming:plant_seed", {
    description = S("Plant Seeds (developers)"),
    name = "Plant Seeds(developers)",
    paramtype = "light",
    paramtype2 = "color",
    palette = "palette.png",
    longdesc = S(
        "Use it instead of other seed when you use styled seed (e. g. randomized by biomes), " ..
        "use param2 if you use more field in same mts - each have another color"),
    sunlight_propagates = true,
    walkable = false,
    drawtype = "plantlike",
    drop = "mcl_farming:plant_seed",
    tiles = { "mcl_farming_plant_seed.png" },
    inventory_image = "mcl_farming_plant_seed.png",
    wield_image = "mcl_farming_plant_seed.png",
    selection_box = {
        type = "fixed",
        fixed = {
            { -7 / 16, -0.5, -7 / 16, 7 / 16, 0, 7 / 16 }
        },
    },
    groups = {
        dig_immediate = 3,
        plant = 1,
        attached_node = 1,
        dig_by_water = 1,
        destroy_by_lava_flow = 1,
        dig_by_piston = 1
    },
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    _mcl_blast_resistance = 0,
    on_place = function(itemstack, placer, pointed_thing)
        return mcl_farming:place_seed(itemstack, placer, pointed_thing, "mcl_farming:plant_seed")
    end
})

mcl_farming:add_plant("plant_seed", "mcl_farming:plant_seed",
    { "mcl_farming:plant_seed" }, 25, 20)
