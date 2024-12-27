mcl_farming.registered_crops = {}

local S = minetest.get_translator(minetest.get_current_modname())
local doc_mod = minetest.get_modpath("doc")

function mcl_farming.register_crop(id, crop_defs)
    if not mcl_farming.registered_crops[id] then
        mcl_farming.registered_crops[id] = crop_defs
    end

    local i = 0
    local description, new_groups, longdesc
    local stages = crop_defs.stages
    local n_descriptions = #crop_defs.descriptions
    local enought_descs, only_two = n_descriptions == stages, n_descriptions == 2

    if not stages or type(stages) ~= "number" or stages <= 1 then
        return
    end

    if not crop_defs.groups or type(crop_defs.groups) == "table" then
        new_groups = table.merge(crop_defs.groups or {}, {
            attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
            dig_immediate = 3, not_in_creative_inventory = 1, plant = 1
        })
    end

    for _ = 0, stages - 1 do
        if i == 0 then
            longdesc = crop_defs.premature_longdesc
        elseif i == stages - 1 then
            longdesc = crop_defs.mature_longdesc
        end

        if not enought_descs and only_two then
            if i < stages - 1 then
                description = S(crop_defs.descriptions[1], i + 1)
            else
                description = S(crop_defs.descriptions[2])
            end
        else
            description = crop_defs.descriptions[i + 1]
        end

        local subname = i < stages - 1 and "_" .. i or ""
        local texture = crop_defs.tiles and crop_defs.tiles[i + 1]

        core.register_node(":mcl_farming:" .. id .. subname, table.merge({
            _doc_items_longdesc = longdesc,
            _doc_items_create_entry = (i == 0 or i == stages - 1),
            _doc_items_entry_name = i == 0 and crop_defs.entry_name,
            _mcl_baseitem = crop_defs.baseitem or crop_defs.seed,
            _mcl_blast_resistance = 0,
            _mcl_fortune_drop = i == stages - 1 and crop_defs.fortune_drop,
            _mcl_hardness = 0,
            _on_bone_meal = crop_defs.on_bone_meal,
            description = description,
            drawtype = "plantlike",
            drop = i == stages - 1 and crop_defs.full_grow_drop or crop_defs.seed,
            groups = new_groups,
            inventory_image = texture or ("mcl_farming_" .. id .. "_" .. i .. ".png"),
            paramtype = "light",
            paramtype2 = "meshoptions",
            place_param2 = crop_defs.place_param2 or 3,
            selection_box = {type = "fixed", fixed = crop_defs.boxes[i + 1]},
            sounds = mcl_sounds.node_sound_leaves_defaults(),
            sunlight_propagates = true,
            tiles = {texture or ("mcl_farming_" .. id .. "_" .. i .. ".png")},
            walkable = false,
            wield_image = texture or ("mcl_farming_" .. id .. "_" .. i .. ".png")
        }, crop_defs.overrides or {}))

        if doc_mod and i > 0 and i < stages - 1 then
            doc.add_entry_alias("nodes", "mcl_farming:"..id.."_0", "nodes", "mcl_farming:"..id.."_"..i)
        end

        i = i + 1
    end
end
