local S = core.get_translator("mcl_tripwire_hooks")

core.register_node("mcl_tripwire_hooks:tripwire_hook", {
    description = S("Tripwire Hook"),
    drawtype = "mesh",
    groups = {
        attached_node = 1, handy = 1, redstone = 1
    },
    inventory_image = "mcl_tripwire_hooks_item.png",
    mesh = "mcl_tripwire_hooks_hook.obj",
    --on_place = function(itemstack, placer, pointed_thing) end,
    paramtype = "light",
    --paramtype2 = "4dir",
    selection_box = {fixed = {-0.25, -0.125, -0.5, 0.25, 0.25, 0}, type = "fixed"},
    sounds = mcl_sounds.node_sound_wood_defaults(),
    sunlight_propagates = true,
    tiles = {"default_wood.png", "default_stone.png"},
    wield_image = "mcl_tripwire_hooks_item.png",
    use_texture_alpha = "clipe"
})

core.register_craft({
    output = "mcl_tripwire_hooks:tripwire_hook 2",
    recipe = {
        {"mcl_core:iron_ingot"},
        {"mcl_core:stick"},
        {"group:planks"}
    }
})
