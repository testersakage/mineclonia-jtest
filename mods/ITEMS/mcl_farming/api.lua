mcl_farming.registered_crops = {}

function mcl_farming.register_crop(id, crop_defs)
    local new_groups
    local stages = crop_defs.stages

    if not stages or type(stages) ~= "number" and stages < 0 and stages % 1 ~= 0 then
        return
    end

    if type(crop_defs.groups) == "table" then
        new_groups = table.merge(crop_defs.groups, {
            attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
            dig_immediate = 3, not_in_creative_inventory = 1, plant = 1
        })
    end

    for i = 0, stages do
        core.register_node(":mcl_farming:" .. id .. "_" .. i, table.merge({
            --_doc_items_longdesc = nil,
            _mcl_baseitem = crop_defs.baseitem or crop_defs.seed,
            _mcl_blast_resistance = 0,
            _mcl_fortune_drop = i == stages and crop_defs.fortune_drop,
            _mcl_hardness = 0,
            description = crop_defs.descriptions[i + 1],
            drawtype = "plantlike",
            drop = i == stages and crop_defs.full_grow_drop or crop_defs.seed,
            groups = new_groups,
            paramtype = "light",
            paramtype2 = "meshoptions",
            place_param2 = crop_defs.place_param2 or 3,
            selection_box = {type = "fixed", fixed = crop_defs.boxes[i + 1]},
            sounds = mcl_sounds.node_sound_leaves_defaults(),
            sunlight_propagates = true,
            tiles = crop_defs.tiles[i + 1] or {"mcl_farming_" .. id .. "_" .. i .. ".png"},
            walkable = false,
        }, crop_defs.overrides or {}))
    end
end
