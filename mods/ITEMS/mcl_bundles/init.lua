local S = minetest.get_translator("mcl_bundles")

local function use_bundle(itemstack, placer, pointed_thing)
    if pointed_thing.type ~= "object" then
        return
    end
    local player_inv = placer:get_inventory()
    local lentity = pointed_thing.ref:get_luaentity()
    local stack_name = itemstack:get_name()
    if lentity and lentity.name == "__builtin:item" then
        local data = {}
        table.insert(data, lentity.itemstring)
        lentity._removed = true
        if not stack_name:find("_filled") then
            local new_stack = ItemStack(stack_name.."_filled")
            new_stack:set_metadata(minetest.serialize(data))
            player_inv:add_item("main", new_stack)
            itemstack:take_item()
        end
    end
    return itemstack
end

minetest.register_craftitem("mcl_bundles:bundle", {
    description = S("Bundle"),
    --_doc_items_longdesc = S(""),
    --_doc_items_usagehelp = S(""),
    groups = { tool = 1 },
    pointabilities = {
        objects = {
            ["__builtin:item"] = true
        }
    },
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    inventory_image = "mcl_bundles_bundle.png",
    wield_image = "mcl_bundles_bundle.png",
    stack_max = 16
})

minetest.register_craftitem("mcl_bundles:bundle_filled", {
    description = S("Bundle"),
    groups = { not_in_creative_inventory = 1 },
    pointabilities = {
        objects = {
            ["__builtin:item"] = true
        }
    },
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    inventory_image = "mcl_bundles_bundle_filled.png",
    wield_image = "mcl_bundles_bundle_filled.png",
    stack_max = 1
})

minetest.register_craft({
    output = "mcl_bundles:bundle",
    recipe = {
        {"mcl_mobitems:rabbit_hide", "mcl_mobitems:string", "mcl_mobitems:rabbit_hide"},
        {"mcl_mobitems:rabbit_hide", "", "mcl_mobitems:rabbit_hide"},
        {"mcl_mobitems:rabbit_hide", "mcl_mobitems:rabbit_hide", "mcl_mobitems:rabbit_hide"}
    }
})
