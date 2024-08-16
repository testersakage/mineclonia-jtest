local S = minetest.get_translator("mcl_tools")
local MAX_STACK_POINTS = 256

local function get_stack_points(itemstring)
    local itemstack = ItemStack(itemstring)
    local count = itemstack:get_count()
    local stack_max = itemstack:get_stack_max()
    return (64 / stack_max) * count
end

local function room_on_bundle(bundlestack)
    local meta_bs = bundlestack:get_meta()
    local stack_points = meta_bs:get_int("stack_points")
    return stack_points < MAX_STACK_POINTS
end

local function entity_to_string(pointed_thing_ref)
    local lentity = pointed_thing_ref:get_luaentity()
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
    local player_inv = player:get_inventory()
    local bundle_inv = get_bundle_inv(bundlestack)
    table.insert(bundle_inv, itemstring)
    local stack_points = get_stack_points(itemstring)
    local inv_data = minetest.serialize(bundle_inv)
    if not is_filled(bundlestack) then
        local new_stack = ItemStack(bundlestack:get_name().."_filled")
        local meta_ns = new_stack:get_meta()
        meta_ns:set_string("inventory", inv_data)
        meta_ns:set_int("stack_points", stack_points)
        if player_inv:room_for_item("main", new_stack) then
            player_inv:add_item("main", new_stack)
        else
            minetest.add_item(player:get_pos(), new_stack)
        end
        bundlestack:take_item()
    else
        local meta_bs = bundlestack:get_meta()
        meta_bs:set_int("stack_points", meta_bs:get_int("stack_points") + stack_points)
        bundlestack:get_meta():set_string("inventory", inv_data)
    end
    return bundlestack
end

local function unfill_bundle(bundlestack, player)
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
    bundlestack:clear()
    if inv:room_for_item("main", new_stack) then
        return new_stack
    else
        minetest.add_item(player:get_pos(), new_stack)
    end
end

local function use_bundle(itemstack, placer, pointed_thing)
    if pointed_thing.type == "object" then
        local lentity, itemstring = entity_to_string(pointed_thing.ref)
        if room_on_bundle(itemstack) then
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

minetest.register_tool("mcl_tools:bundle", {
    description = S("Bundle"),
    _doc_items_longdesc = S("A bundle is an item that can store up to a stack's worth of mixed item types within itself in a single inventory slot."),
    _doc_items_usagehelp = S("Right-click on items dropped on the ground to collect them. To empty the bundle, use it to point to a node or point to nothing."),
    groups = { tool = 1 },
    pointabilities = {
        objects = {
            ["__builtin:item"] = true
        }
    },
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    inventory_image = "mcl_tools_bundle.png",
    wield_image = "mcl_tools_bundle.png",
    stack_max = 16
})

minetest.register_tool("mcl_tools:bundle_filled", {
    description = S("Bundle"),
    groups = { not_in_creative_inventory = 1 },
    pointabilities = {
        objects = {
            ["__builtin:item"] = true
        }
    },
    wear_color = {
        blend = "linear",
        color_stops = {
            [0.0] = "#3A7DFF",
            [0.5] = "#3FAE51",
            [1.0] = "#BA1E1E"
        }
    },
    on_place = use_bundle,
    on_secondary_use = use_bundle,
    inventory_image = "mcl_tools_bundle_filled.png",
    wield_image = "mcl_tools_bundle_filled.png",
    stack_max = 1
})
