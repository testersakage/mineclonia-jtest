local S = core.get_translator("mcl_tripwire_hooks")

local tpl_hook = {
    drawtype = "mesh",
    paramtype = "light",
    selection_box = {fixed = {-0.25, -0.125, -0.5, 0.25, 0.25, 0}, type = "fixed"},
    sounds = mcl_sounds.node_sound_wood_defaults(),
    sunlight_propagates = true,
    tiles = {"default_stone.png", "default_wood.png"},
}

core.register_node("mcl_tripwire_hooks:hook", table.merge(tpl_hook, {
    description = S("Tripwire Hook"),
    groups = {
        attached_node = 1, handy = 1, redstone = 1
    },
    inventory_image = "mcl_tripwire_hooks_item.png",
    mesh = "mcl_tripwire_hooks_hook.obj",
    --on_place = function(itemstack, placer, pointed_thing) end,
    --paramtype2 = "4dir",
    wield_image = "mcl_tripwire_hooks_item.png",
}))

core.register_node("mcl_tripwire_hooks:hook_powered", table.merge(tpl_hook, {
    description = S("Tripwire Hook Powered"),
    drop = "mcl_tripwire_hooks:hook",
    groups = {
        attached_node = 1, handy = 1, not_in_creative_inventory = 1, redstone = 1
    },
    mesh = "mcl_tripwire_hooks_hook_powered.obj",
}))

core.register_craft({
    output = "mcl_tripwire_hooks:hook 2",
    recipe = {
        {"mcl_core:iron_ingot"},
        {"mcl_core:stick"},
        {"group:planks"}
    }
})
