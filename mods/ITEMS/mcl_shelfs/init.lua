mcl_shelfs = {}

local S = core.get_translator(core.get_current_modname())

local box = {
    type = "fixed",
    fixed = {-0.5, -0.5, 0.5, 0.5, 0.5, 0.1875}
}

local groups = {
    axey = 1, unmovable_by_piston = 1
}

function mcl_shelfs.register_shelf(id, defs)
    local original = "mcl_shelfs:shelf_" .. id
    local tpl_shelf = {
        description = defs.description,
        drawtype = "mesh",
        is_ground_content = false,
        paramtype = "light",
        paramtype2 = "4dir",
        sounds = mcl_sounds.node_sound_wood_defaults(),
        selection_box = box,
        collision_box = box,
        tiles = defs.tiles,
        drop = original,
        _mcl_baseitem = original,
        _mcl_blast_resistance = 3,
        _mcl_hardness = 2
    }

    core.register_node(":" .. original, table.merge(tpl_shelf, {
        _doc_items_longdesc = S("A shelf is a block that can store and display up to three stacks of items. A shelf can be used to swap its slots with the slots in the player's hotbar."),
        groups = table.merge(groups, {deco_block = 1}),
        mesh = "mcl_shelfs_shelf.obj"
    }))

    core.register_node(":mcl_shelfs:shelf_powered_" .. id, table.merge(tpl_shelf, {
        _doc_items_create_entry = false,
        groups = table.merge(groups, {not_in_creative_inventory = 1}),
        mesh = "mcl_shelfs_shelf_powered.obj",
    }))

    core.register_node(":mcl_shelfs:shelf_powered_left_" .. id, table.merge(tpl_shelf, {
        _doc_items_create_entry = false,
        groups = table.merge(groups, {not_in_creative_inventory = 1}),
        mesh = "mcl_shelfs_shelf_powered_left.obj"
    }))

    core.register_node(":mcl_shelfs:shelf_powered_middle_" .. id, table.merge(tpl_shelf, {
        _doc_items_create_entry = false,
        groups = table.merge(groups, {not_in_creative_inventory = 1}),
        mesh = "mcl_shelfs_shelf_powered_middle.obj"
    }))

    core.register_node(":mcl_shelfs:shelf_powered_right_" .. id, table.merge(tpl_shelf, {
        _doc_items_create_entry = false,
        groups = table.merge(groups, {not_in_creative_inventory = 1}),
        mesh = "mcl_shelfs_shelf_powered_right.obj"
    }))

    doc.add_entry_alias("nodes", "mcl_shelfs:shelf_" .. id, "nodes", "mcl_shelfs:shelf_powered_" .. id)
    doc.add_entry_alias("nodes", "mcl_shelfs:shelf_" .. id, "nodes", "mcl_shelfs:shelf_powered_left_" .. id)
    doc.add_entry_alias("nodes", "mcl_shelfs:shelf_" .. id, "nodes", "mcl_shelfs:shelf_powered_middle" .. id)
    doc.add_entry_alias("nodes", "mcl_shelfs:shelf_" .. id, "nodes", "mcl_shelfs:shelf_powered_right_" .. id)
end
