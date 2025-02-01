mcl_farming = {}

local path = core.get_modpath(core.get_current_modname())

mcl_farming.tpl_plant = {
    _mcl_blast_resistance = 0,
    drawtype = "plantlike",
    paramtype = "light",
    paramtype2 = "meshoptions",
    place_param2 = 3,
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    walkable = false
}

mcl_farming.tpl_connected_stem = {
    _doc_items_create_entry = false,
    _mcl_blast_resistance = 0,
    drawtype = "nodebox",
    groups = {
        attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
        dig_immediate = 3, not_in_creative_inventory = 1, plant = 1
    },
    paramtype = "light",
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    use_texture_alpha = "clip",
    walkable = false,
}

-- IMPORTANT API AND HELPER FUNCTIONS --
-- Contain functions for planting seed, addind plant growth and gourds (melon/pumpkin-like)
dofile(path .. "/shared_functions.lua")

dofile(path .. "/soil.lua")
dofile(path .. "/hoes.lua")
dofile(path .. "/wheat.lua")
dofile(path .. "/pumpkin.lua")
dofile(path .. "/melon.lua")
dofile(path .. "/carrots.lua")
dofile(path .. "/potatoes.lua")
dofile(path .. "/beetroot.lua")
dofile(path .. "/sweet_berry.lua")
