local S = core.get_translator(core.get_current_modname())

local tpl_crop = {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    drawtype = "plantlike",
    paramtype = "light",
    paramtype2 = "meshoptions",
    place_param2 = 3,
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    walkable = false
}

function mcl_farming.register_simple_crop(id, defs, overrides)
    for i = 1, defs.stages do
        local mature, premature = i == defs.stages, i == 1
        local desc = premature and S("@1 (Stage @2)", defs.premature_desc, i) or defs.mature_desc
        local subname = id .. not mature and "_" .. i or ""

        if type(defs.drops) == "nil" or not defs.drops[i] then
            defs.drops[i] = premature and defs.seed or defs.mature_drop
        end

        core.register_node(":mcl_farming:" .. subname, table.merge(tpl_crop, {
            _doc_items_create_entry = mature or premature,
            _doc_items_longdesc = premature and defs.premature_longdesc or defs.mature_longdesc,
            _mcl_baseitem = defs.seed,
            _mcl_fortune_drop = mature and defs.fortune_drops,
            description = desc,
            drop = defs.drops[i],
            groups = table.merge(defs.groups_per_stage[i] or defs.groups or {}, {
                attached_node = 3, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
                dig_immediate = 1, not_in_creative_inventory = 1, plant = 1, unsticky = 1
            }),
            inventory_image = "",
            selection_box = {
                fixed = {},
                type = "fixed"
            },
            tiles = {},
            wield_image = ""
        }, overrides or {}))
    end
end
