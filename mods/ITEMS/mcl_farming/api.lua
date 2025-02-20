local S = core.get_translator(core.get_current_modname())

local tpl_crop = {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    _on_bone_meal = mcl_farming.bone_meal_crop,
    drawtype = "plantlike",
    paramtype = "light",
    paramtype2 = "meshoptions",
    place_param2 = 3,
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    walkable = false
}

local tpl_stem = {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    _on_bone_meal = mcl_farming.bone_meal_stem,
    drawtype = "plantlike",
    paramtype = "light",
    paramtype2 = "color",
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    walkable = false
}

local tpl_stem_connected = {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "color",
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    use_texture_alpha = "clip",
    walkable = false
}

local nodeboxes = {
    {-0.5, -0.5, 0, 0.5, 0.5, 0},
    {-0.5, -0.5, 0, 0.5, 0.5, 0},
    {0, -0.5, -0.5, 0, 0.5, 0.5},
    {0, -0.5, -0.5, 0, 0.5, 0.5}
}

local selectionboxes = {
    {-0.1, -0.5, -0.1, 0.5, 0.2, 0.1},
    {-0.5, -0.5, -0.1, 0.1, 0.2, 0.1},
    {-0.1, -0.5, -0.1, 0.1, 0.2, 0.5},
    {-0.1, -0.5, -0.5, 0.1, 0.2, 0.1}
}

local function get_connected_stem_tiles(texture, index)
    local textures = {
        {"blank.png", "blank.png", "blank.png", "blank.png", texture, texture .. "^[transform:FX"},
        {"blank.png", "blank.png", "blank.png", "blank.png", texture .. "^[transform:FX", texture},
        {"blank.png", "blank.png", texture .. "^[transform:FX", texture, "blank.png", "blank.png"},
        {"blank.png", "blank.png", texture, texture .. "^[transform:FX", "blank.png", "blank.png"}
    }

    return textures[index]
end

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
    local enough_stagegroup = defs.groups_per_stage and #defs.groups_per_stage == defs.stages
    local enough_textures = #defs.textures == defs.stages

    if not defs.drops then defs.drops = {} end

    for i = 1, defs.stages do
        if not enough_selheights then
            defs.sel_heights[i] = get_indexed_parameter(defs.sel_heights, i)
        end

        if not enough_selwidths and not defs.single_sel_width then
            defs.sel_widths[i] = get_indexed_parameter(defs.sel_widths, i)
        end

        if not enough_stagegroup and defs.groups_per_stage then
            defs.groups_per_stage[i] = get_indexed_parameter(defs.groups_per_stage, i)
        end

        if not enough_textures then
            defs.textures[i] = get_indexed_parameter(defs.textures, i)
        end

        local mature, premature = i == defs.stages, i == 1
        local desc = not mature and S("@1 (Stage @2)", defs.premature_desc, i) or defs.mature_desc
        local longdesc = premature and defs.premature_longdesc or mature and defs.mature_longdesc
        local sel_height = defs.sel_heights[i]
        local sel_width = defs.single_sel_width or defs.sel_widths[i]
        local subname = (not mature and "_" .. (defs.initial_stage_zero and i - 1 or i) or "")
        local name = mod .. ":" .. id .. subname
        local texture = defs.textures[i]

        if mature and defs.last_stage_index then
            name = mod .. ":" .. id .. "_" .. defs.last_stage_index
        end

        if not enough_drops then
            defs.drops[i] = get_indexed_parameter(defs.drops, i)
        end

        core.register_node(name, table.merge(tpl_crop, {
            _doc_items_create_entry = mature or premature,
            _doc_items_entry_name = premature and defs.premature_desc or nil,
            _doc_items_longdesc = longdesc,
            _mcl_baseitem = defs.seed,
            _mcl_fortune_drop = mature and defs.fortune_drop,
            description = desc,
            drop = defs.drops[i] or premature and defs.seed or defs.mature_drop,
            groups = table.merge(defs.groups or {}, {
                attached_node = 3, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
                dig_immediate = 1, not_in_creative_inventory = 1, plant = 1, unsticky = 1, [id] = i
            }, defs.groups_per_stage and defs.groups_per_stage[i] or {}),
            inventory_image = texture,
            selection_box = {
                fixed = {-sel_width, -0.5, -sel_width, sel_width, sel_height, sel_width},
                type = "fixed"
            },
            tiles = {texture},
            wield_image = texture
        }, overrides or {}))

        if not (mature or premature) then
            doc.add_entry_alias("nodes", id_orig, "nodes", name)
        end
    end
end

local function get_stem_drops(seed, index)
    local rarity = {
        {6, 3, 3, 2, 2, 2, 3, 3},
		{81, 22, 10, 6, 5, 3, 3, 3},
		{3333, 417, 125, 53, 27, 16, 10, 10}
    }

    return {
        {items = {seed}, rarity = rarity[1][index]},
        {items = {seed .. " 2"}, rarity = rarity[2][index]},
        {items = {seed .. " 3"}, rarity = rarity[3][index]}
    }
end

function mcl_farming.register_stems(id, defs, overrides)
    local mod = core.get_current_modname()
    local id_orig = mod .. ":" .. id .. "_1"

    for i = 1, 8 do
        local mature, premature = i == 8, i == 1
        local desc = not mature and S("@1 (Stage @2)", defs.premature_desc, i) or defs.mature_desc
        local longdesc = premature and defs.premature_longdesc or mature and defs.mature_longdesc
        local name = mod .. ":" .. id .. "_" .. mature and "unconnect" or i
        local texture = "[combine:16x16:0," .. (8 - i) * 2 .. "=" .. defs.texture

        core.register_node(name, table.merge(tpl_stem, {
            _doc_items_create_entry = mature or premature,
            _doc_items_entry_name = premature and defs.premature_desc or nil,
            _doc_items_longdesc = longdesc,
            _mcl_baseitem = defs.seed,
            _mcl_farming_gourd = defs.gourd,
            description = desc,
            drop = {
                items = get_stem_drops(defs.seed, i),
                max_items = 1
            },
            groups = table.merge(defs.groups or {}, {
                attached_node = 3, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
                dig_immediate = 3, not_in_creative_inventory = 1, plant = 1, [id] = i
            }),
            inventory_image = texture,
            palette = "mcl_farming_" .. id .. "_palette.png",
            place_param2 = i - 1,
            selection_box = {
                fixed = {
                    -0.1875, -0.5, -0.1875, 0.1875, -0.5 + i / 8, 0.1875
                },
                type = "fixed"
            },
            tiles = {texture},
            wield_image = texture
        }, overrides or {}))

        if not (mature or premature) then
            doc.add_entry_alias("nodes", id_orig, "nodes", name)
        end

        local dir = {"_r", "_l", "_t", "_b"}

        for i = 1, 4 do
            local name = mod .. ":" .. id .. "_linked_" .. dir[i]

            core.register_node(name, table.merge(tpl_stem_connected, {
                _doc_items_create_entry = false,
                drop = get_stem_drops(defs.seed, 8),
                groups = {
                    attached_node = 3, destroy_by_lava_flow = 1, dig_by_piston = 1,
                    dig_by_water = 1, dig_immediate = 3, not_in_creative_inventory = 1, plant = 1
                },
                node_box = {fixed = nodeboxes[i], type = "fixed"},
                selection_box = {fixed = selectionboxes[i], type = "fixed"},
                tiles = get_connected_stem_tiles(defs.connected_stem_texture, i)
            }))

            doc.add_entry_alias("nodes", mod .. ":" .. id .. "_unconnect", "nodes", name)
        end
    end
end

function mcl_farming.place_plant(itemstack, placer, pointed_thing)
    if pointed_thing.type ~= "node" then return end

    local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)

    if rc then return rc end

    local idefs = itemstack:get_definition()
    local plant = idefs and idefs._mcl_places_plant
    local above = pointed_thing.above
    local anode = core.get_node(above)
    local unode = core.get_node(pointed_thing.under)

    if unode.name:find("mcl_farming:soil") and anode.name:find("air") then
        local spec = core.registered_nodes[plant].sounds.place
        core.place_node(above, {name = plant})
        core.sound_play(spec, {max_hear_distance = 16, pos = above}, true)

        if not core.is_creative_enabled(placer:get_player_name()) then
            itemstack:take_item()
        end
    elseif core.get_item_group(itemstack:get_name(), "food") > 0 then
        local hp = core.get_item_group(itemstack:get_name(), "eatable")
        local replacement = idefs._mcl_farming_eat_replacement

        return core.do_item_eat(hp, replacement, itemstack, placer, pointed_thing)
    end

    return itemstack
end

function mcl_farming.carve_pumpkin(itemstack, placer, pointed_thing)
    if pointed_thing.type ~= "node" then return end

    local above, under = pointed_thing.above, pointed_thing.under
    if above.y ~= under.y then return end

    if not core.is_creative_enabled(placer:get_player_name()) then
		local toolname = itemstack:get_name()
		local wear = mcl_autogroup.get_wear(toolname, "shearsy")

		itemstack:add_wear(wear)
	end

    core.sound_play("default_grass_footstep", {max_hear_distance = 16, pos = above}, true)

    local dir = vector.subtract(under, above)
	local param2 = core.dir_to_facedir(dir)

    core.set_node(under, {name = "mcl_farming:pumpkin_face", param2 = param2})
	core.add_item(above, "mcl_farming:pumpkin_seeds 4")

    return itemstack, true
end

mcl_farming.pumpkin_hud = {}

function mcl_farming.add_pumpkin_hud(player)
	pumpkin_hud[player] = {
        --this is a fake crosshair, because hotbar and crosshair doesn't support z_index
		--TODO: remove this and add correct z_index values
		fake_crosshair = player:hud_add({
			position = {x = 0.5, y = 0.5},
			scale = {x = 1, y = 1},
			text = "crosshair.png",
			type = "image",
            z_index = -100
		}),
		pumpkin_blur = player:hud_add({
			position = {x = 0.5, y = 0.5},
			scale = {x = -101, y = -101},
			text = "mcl_farming_pumpkin_hud.png",
			type = "image",
            z_index = -200
		})
	}
end

function mcl_farming.remove_pumpkin_hud(player)
    if pumpkin_hud[player] then
        player:hud_remove(pumpkin_hud[player].pumpkin_blur)
        player:hud_remove(pumpkin_hud[player].fake_crosshair)
        pumpkin_hud[player] = nil
    end
end
