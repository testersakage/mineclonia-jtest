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
        local subname = id .. not mature and "_" .. i or ""

        if not defs.drops and defs.mature_drop then
            defs.drops[i] = premature and defs.seed or defs.mature_drop
        end

        core.register_node(":mcl_farming:" .. subname, table.merge(tpl_crop, {
            _doc_items_create_entry = mature or premature,
            _mcl_baseitem = defs.seed,
            _mcl_fortune_drop = mature and defs.fortune_drops,
            drop = defs.drops[i],
        }, overrides or {}))
    end
end
