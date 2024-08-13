local S = minetest.get_translator("mcl_bundles")

local function use_bundle(itemstack, placer, pointed_thing)
end

minetest.register_craftitem("mcl_bundles:bundle", {
    description = S("Bundle"),
    --_doc_items_longdesc = S(""),
    --_doc_items_usagehelp = S(""),
    groups = { tool = 1 },
    pointabilities = {},
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    tiles = { "mcl_bundles_bundle.png" },
    stack_max = 16
})

minetest.register_craftitem("mcl_bundles:bundle_filled", {
    description = S("Bundle"),
    groups = { not_in_creative_inventory = 1 },
    pointabilities = {},
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    tiles = { "mcl_bundles_bundle_filled.png" },
    stack_max = 1
})
