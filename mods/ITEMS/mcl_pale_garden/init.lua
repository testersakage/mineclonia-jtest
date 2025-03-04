local S = core.get_translator(core.get_current_modname())

mcl_trees.register_wood("pale_oak",{
    readable_name = "Pale Oak",
    sign_color = "#ECDDE3",
    tree = {
        tiles = {
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak.png"
        }
    },
    stripped = {
        tiles = {
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_side.png"
        }
    },
    wood = {tiles = {"mcl_pale_garden_planks_pale_oak.png"}}
})

mcl_flowers.register_simple_flower("closed_eyeblossom", {
    desc = S("Closed Eyeblossom"),
    image = "mcl_pale_garden_closed_eyeblossom.png",
    selection_box = {-0.25, -0.5, -0.25, 0.25, 0.25, 0.25},
    potted = true,
    _mcl_crafting_output = {single = {output = "mcl_dyes:grey"}}
})

mcl_flowers.register_simple_flower("open_eyeblossom", {
    desc = S("Open Eyeblossom"),
    image = "mcl_pale_garden_open_eyeblossom.png",
    selection_box = {-0.25, -0.5, -0.25, 0.25, 0.25, 0.25},
    potted = true,
    _mcl_crafting_output = {single = {output = "mcl_dyes:orange"}}
})
