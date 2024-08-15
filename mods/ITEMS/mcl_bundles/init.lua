local S = minetest.get_translator("mcl_bundles")
local MAX_STACK_POINTS = 256

local function get_stack_points(itemstring)
    local itemstack = ItemStack(itemstring)
    local count = itemstack:get_count()
    local stack_max = itemstack:get_stack_max()
    return (64 / stack_max) * count
end

local function room_on_bundle(bundlestack, itemstring)
    local meta = bundlestack:get_meta()
    local stack_points = meta:get_int("stack_points")
    local new_sp = stack_points + get_stack_points(itemstring)
    if new_sp <= MAX_STACK_POINTS then
        meta:set_int("stack_points", new_sp)
        return true
    end
    return false
end

local function entity_to_stack(pointed_thing)
    local lentity = pointed_thing.ref:get_luaentity()
    if lentity and lentity.name == "__builtin:item" then
        if lentity.itemstring then
            return lentity, lentity.itemstring
        end
    end
    return nil
end

local function is_filled(bundlestack)
    return bundlestack:get_name():find("_filled")
end

local function get_bundle_inv(bundlestack)
    local meta = bundlestack:get_meta()
    local inv = meta:get_string("inventory")
    if inv ~= "" then return minetest.deserialize(inv) end
    return {}
end

local function fill_bundle(bundlestack, itemstring, player)
    -- TODO:
    --  Fix bugs and clean up the code
    --  Add sounds
    --  Add bar to filled bundle
    local inv = player:get_inventory()
    local old_name = bundlestack:get_name()
    local bundle_inv = get_bundle_inv(bundlestack)
    table.insert(bundle_inv, itemstring)
    local inv_data = minetest.serialize(bundle_inv)
    if not is_filled(bundlestack) then
        local new_stack = ItemStack(old_name.."_filled")
        new_stack:get_meta():set_string("inventory", inv_data)
        if inv:room_for_item("main", new_stack) then
            inv:add_item("main", new_stack)
        else
            minetest.add_item(player:get_pos(), new_stack)
        end
    else
        bundlestack:get_meta():set_string("inventory", inv_data)
    end
    bundlestack:take_item()
    return bundlestack
end

local function unfill_bundle(bundlestack, player)
    -- TODO:
    --  Fix bugs and clean up the code
    --  Add sounds
    local inv = player:get_inventory()
    local bundle_inv = get_bundle_inv(bundlestack)
    local new_stack = ItemStack(bundlestack:get_name():gsub("_filled", ""))
    for _, items in pairs(bundle_inv) do
        local stack = ItemStack(items)
        if inv:room_for_item("main", stack) then
            inv:add_item("main", stack)
        else
            minetest.add_item(player:get_pos(), stack)
        end
    end
    bundlestack:get_meta():set_string("inventory", "")
    bundlestack:take_item()
    if inv:room_for_item("main", new_stack) then
        inv:add_item("main", new_stack)
    end
    -- TODO:
    --  Check for room on player's hands
    return bundlestack
end

local function use_bundle(itemstack, placer, pointed_thing)
    -- TODO:
    --  Fix bugs and clean up the code
    if pointed_thing.type == "object" then
        local lentity, itemstring = entity_to_stack(pointed_thing)
        if room_on_bundle(itemstack, itemstring) then
            lentity._removed = true
            return fill_bundle(itemstack, itemstring, placer)
        end
    elseif pointed_thing.type == "node" then
        local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
        if rc then return rc end
        if is_filled(itemstack) then return unfill_bundle(itemstack, placer) end
    else
        if is_filled(itemstack) then return unfill_bundle(itemstack, placer) end
    end
    return itemstack
end

minetest.register_craftitem("mcl_bundles:bundle", {
    description = S("Bundle"),
    _doc_items_longdesc = S("A bundle is an item that can store up to a stack's worth of mixed item types within itself in a single inventory slot."),
    -- TODO:
    --  Proper documentation
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
