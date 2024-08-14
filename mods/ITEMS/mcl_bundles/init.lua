local S = minetest.get_translator("mcl_bundles")
local MAX_STACK_POINTS = 256

local function get_stack_points(itemstack)
    local count = itemstack:get_count()
    local stack_max = itemstack:get_stack_max()
    return (64 / stack_max) * count
end

local function check_for_room(bundlestack, itemstack)
    local meta = bundlestack:get_meta()
    local stack_points = meta:get_int("stack_points") or 0
    local new_sp = stack_points + get_stack_points(itemstack)
    if new_sp <= MAX_STACK_POINTS then
        meta:set_int("stack_points", new_sp)
        return true
    end
    return false
end

local function entity_to_stack(pointed_thing)
    if pointed_thing.type == "object" then
        local lentity = pointed_thing.ref:get_luaentity()
        if lentity and lentity.name == "__builtin:item" then
            if lentity.itemstring then
                return ItemStack(lentity.itemstring), lentity
            end
        end
    end
    return nil
end

local function is_filled(bundlestack)
    return bundlestack:get_name():find("_filled")
end

local function check_room_on_inv(player, itemstring)
    local inv = player:get_inventory()
    local stack = ItemStack(itemstring)
    return inv and inv:room_for_item("main", stack), inv
end

local function fill_bundle(bundlestack, itemstack, player)
    local old_name = bundlestack:get_name()
    local data = minetest.deserialize(bundlestack:get_metadata())
    table.insert(data or {}, itemstack)
    local room, inv = check_room_on_inv(player, old_name)
    if not is_filled(bundlestack) then
        if room then inv:add_item("main", ItemStack(old_name.."_filled")) end
        bundlestack:take_item()
    end
    bundlestack:set_metadata(minetest.serialize(data))
    return bundlestack
end

local function unfill_bundle(bundlestack, player)
    local old_name = bundlestack:get_name()
    local inv = player:get_inventory()
    local items = minetest.deserialize(bundlestack:get_metadata())
    if items then
        for _, item in pairs(items) do
            local stack = ItemStack(item)
            if inv:room_for_item("main", stack) then
                inv:add_item("main", stack)
            else
                minetest.add_item(player:get_pos(), stack)
            end
        end
    end
    bundlestack:set_name(old_name:gsub("_filled", ""))
    return bundlestack
end

local function use_bundle(itemstack, placer, pointed_thing)
    local item_stack, lentity = entity_to_stack(pointed_thing)
    if item_stack then
        if check_for_room(itemstack, item_stack) then
            lentity._removed = true
            return fill_bundle(itemstack, item_stack, placer)
        end
    end
    if pointed_thing.type ~= "node" then
        if is_filled(itemstack) then
            return unfill_bundle(itemstack, placer)
        end
    else
        local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
        if rc then return rc end
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
