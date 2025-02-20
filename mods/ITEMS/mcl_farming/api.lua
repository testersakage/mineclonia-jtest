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

local function get_indexed_parameter(parameter, index)
    index = tostring(index)
    for k, v in pairs(parameter) do
        if type(k) == "string" then
            for current_index in k:gmatch("%d+") do
                if current_index == index then return v end
            end
        end
    end
end

function mcl_farming.register_simple_crop(id, defs, overrides)
    local mod = core.get_current_modname()
    local id_orig = mod .. ":" .. id .. "_" .. (defs.initial_stage_zero and 0 or 1)
    local enough_drops = defs.drops and #defs.drops == defs.stages
    local enough_selheights = #defs.sel_heights == defs.stages
    local enough_selwidths = defs.sel_widths and #defs.sel_widths == defs.stages
    local enough_textures = #defs.textures == defs.stages

    if not defs.drops then defs.drops = {} end

    for i = 1, defs.stages do
        if not enough_selheights then
            defs.sel_heights[i] = get_indexed_parameter(defs.sel_heights, i)
        end

        if not enough_textures then
            defs.textures[i] = get_indexed_parameter(defs.textures, i)
        end

        local mature, premature = i == defs.stages, i == 1
        local desc = not mature and S("@1 (Stage @2)", defs.premature_desc, i) or defs.mature_desc
        local longdesc = premature and defs.premature_longdesc or mature and defs.mature_longdesc
        local sel_height = defs.sel_heights[i]
        local sel_width = enough_selwidths and defs.sel_widths[i] or defs.single_sel_width
        local stage = (not mature and "_" .. (defs.initial_stage_zero and i - 1 or i) or "")
        local subname = id .. stage
        local texture = defs.textures[i]

        if not enough_drops then
            defs.drops[i] = get_indexed_parameter(defs.drops, i)
        end

        core.register_node(mod .. ":" .. subname, table.merge(tpl_crop, {
            _doc_items_create_entry = premature or mature,
            _doc_items_entry_name = premature and defs.premature_desc or nil,
            _doc_items_longdesc = longdesc,
            _mcl_baseitem = defs.seed,
            _mcl_fortune_drop = mature and defs.fortune_drop,
            _on_bone_meal = not mature and mcl_farming.bone_meal_crop,
            description = desc,
            drop = defs.drops[i] or premature and defs.seed or defs.mature_drop,
            groups = table.merge(defs.groups or {}, {
                attached_node = 3, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
                dig_immediate = 1, not_in_creative_inventory = 1, plant = 1, unsticky = 1, [id] = i
            }, defs.groups_per_stage and defs.groups_per_stage[i]),
            inventory_image = texture,
            selection_box = {
                fixed = {-sel_width, -0.5, -sel_width, sel_width, sel_height, sel_width},
                type = "fixed"
            },
            tiles = {texture},
            wield_image = texture
        }, overrides or {}))

        if not (mature or premature) then
            doc.add_entry_alias("nodes", id_orig, "nodes", mod .. ":" .. subname)
        end
    end
end
