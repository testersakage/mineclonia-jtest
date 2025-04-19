-- mcl_crafter/init.lua
-- A Minecraft-style Crafter that automatically sets its recipe
-- based on the first ingredients inserted into each grid cell.
-- When powered, if every configured cell contains enough items,
-- it consumes the ingredients and dispenses the crafted item.
-- Hoppers are supported and will only insert an ingredient if the cell is not yet full.

local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape
local C = core.colorize

--------------------------------------------------------------------------------
-- Forms Interface (Crafter UI)
-- We define 9 separate 1×1 inventories ("grid_1" ... "grid_9") arranged in a 3×3 layout,
-- plus an output preview slot and the player's inventory, which is now split into a
-- main inventory and a hotbar at the bottom. Each cell uses
-- the mcl_formspec.get_itemslot_bg_v4 texture.
--------------------------------------------------------------------------------
mcl_crafter = {}  -- our mod’s namespace

local crafter_formspec = table.concat({
    "formspec_version[4]",
    "size[13,12]",
    "label[2.25,0.375;" .. F(C("#FFFF00", S("Crafter"))) .. "]",
    "label[2.25,0.5;" .. F(S("Ingredients")) .. "]",
    
    -- Row 1 (cells 1-3)
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(2.25,0.75,1,1) or ""),
    "list[context;grid_1;2.25,0.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(3.25,0.75,1,1) or ""),
    "list[context;grid_2;3.25,0.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(4.25,0.75,1,1) or ""),
    "list[context;grid_3;4.25,0.75;1,1;]",
    
    -- Row 2 (cells 4-6)
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(2.25,1.75,1,1) or ""),
    "list[context;grid_4;2.25,1.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(3.25,1.75,1,1) or ""),
    "list[context;grid_5;3.25,1.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(4.25,1.75,1,1) or ""),
    "list[context;grid_6;4.25,1.75;1,1;]",
    
    -- Row 3 (cells 7-9)
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(2.25,2.75,1,1) or ""),
    "list[context;grid_7;2.25,2.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(3.25,2.75,1,1) or ""),
    "list[context;grid_8;3.25,2.75;1,1;]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(4.25,2.75,1,1) or ""),
    "list[context;grid_9;4.25,2.75;1,1;]",
    
    -- Output preview slot:
    "label[6.125,1.375;" .. F(S("Result")) .. "]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(6.125,2,1,1,0.2) or ""),
    "list[context;output;6.125,2;1,1;]",
    
    -- Player's Main Inventory (moved higher)
    "label[0.375,6.2;" .. F(C((mcl_formspec and mcl_formspec.label_color) or "#FFFFFF", S("Inventory"))) .. "]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(0.375,6.5,9,3) or ""),
    "list[current_player;main;0.375,6.5;9,3;9]",
    
    -- Player's Hotbar at the bottom:
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(0.375,10.5,9,1) or ""),
    "list[current_player;main;0.375,10.5;9,1;]",
    "listring[context;grid]",
    "listring[current_player;main]",
    
    -- Listrings for smooth inventory navigation:
    "listring[context;output]",
    "listring[current_player;main]"
    --"listring[current_player;hotbar]",
})

--------------------------------------------------------------------------------
-- Common Definition (adapted from dispenser/furnace mods)
--------------------------------------------------------------------------------
local commdef = {
    is_ground_content = false,
    sounds = mcl_sounds and mcl_sounds.node_sound_stone_defaults() or nil,
    groups = { pickaxey = 1, container = 2, material_stone = 1 },
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local pos_str = core.pos_to_string(pos)
        local source = (player and player:get_player_name()) or "hopper"
        if player and core.is_protected(pos, source) then
            core.record_protection_violation(pos, source)
            core.log("action", "[Crafter] " .. source .. " attempted to move " .. count ..
                " items from '" .. from_list .. "' (index " .. from_index ..
                ") to '" .. to_list .. "' (index " .. to_index .. ") at " .. pos_str .. " - PROTECTED")
            return 0
        else
            core.log("action", "[Crafter] " .. source .. " moves " .. count ..
                " items from '" .. from_list .. "' (index " .. from_index ..
                ") to '" .. to_list .. "' (index " .. to_index .. ") at " .. pos_str)
            return count
        end
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local pos_str = core.pos_to_string(pos)
        local source = (player and player:get_player_name()) or "hopper"
        if player and core.is_protected(pos, source) then
            core.record_protection_violation(pos, source)
            core.log("action", "[Crafter] " .. source .. " attempted to take " .. stack:get_count() ..
                " items from list '" .. listname .. "' (index " .. index .. ") at " .. pos_str .. " - PROTECTED")
            return 0
        else
            core.log("action", "[Crafter] " .. source .. " takes " .. stack:get_count() ..
                " items from list '" .. listname .. "' (index " .. index .. ") at " .. pos_str)
            return stack:get_count()
        end
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local pos_str = core.pos_to_string(pos)
        local item_name = stack:get_name()
        local item_count = stack:get_count()
        local source = (player and player:get_player_name()) or "hopper"
        core.log("action", "[Crafter] " .. source ..
            " attempted to insert " .. item_name .. " (x" .. item_count ..
            ") into list '" .. listname .. "' at " .. pos_str)
        if player then
            if core.is_protected(pos, source) then
                core.record_protection_violation(pos, source)
                return 0
            end
        end
        return stack:get_count()
    end,
    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        core.log("action", (player and player:get_player_name() or "unknown") ..
            " moves items in crafter at " .. core.pos_to_string(pos))
    end,
    on_rotate = screwdriver and screwdriver.rotate_simple or nil,
    _mcl_blast_resistance = 3.5,
    _mcl_hardness = 3.5,
}

--------------------------------------------------------------------------------
-- Orientation Helper
--------------------------------------------------------------------------------
local function orientate(pos, placer)
    if not placer then return end
    local node = core.get_node(pos)
    local facedir = core.dir_to_facedir(placer:get_look_dir())
    node.param2 = facedir
    core.swap_node(pos, node)
end

--------------------------------------------------------------------------------
-- Helper: Update the output preview based on the current (automatically set) recipe.
--------------------------------------------------------------------------------
local function update_recipe_output(pos)
    local meta = core.get_meta(pos)
    local recipe = {}
    for i = 1, 9 do
        local rec_str = meta:get_string("recipe_" .. i) or ""
        if rec_str ~= "" then
            recipe[i] = ItemStack(rec_str)
        else
            recipe[i] = ItemStack("")
        end
    end
    local craft_req = { method = "normal", width = 3, items = recipe }
    local result = core.get_craft_result(craft_req).item
    local inv = meta:get_inventory()
    inv:set_stack("output", 1, result)
end

--------------------------------------------------------------------------------
-- Setup the Crafter (initialize metadata and inventories)
--------------------------------------------------------------------------------
local function setup_crafter(pos)
    local meta = core.get_meta(pos)
    meta:set_string("formspec", crafter_formspec)
    local inv = meta:get_inventory()
    for i = 1, 9 do
        inv:set_size("grid_" .. i, 1)
        meta:set_string("recipe_" .. i, "")  -- no recipe initially
    end
    inv:set_size("output", 1)
end

--------------------------------------------------------------------------------
-- Automatic Recipe Configuration via Inventory Callbacks
-- When an item is inserted into a grid cell (list "grid_i") and that cell has no recipe yet,
-- record that item as the recipe for that cell.
--------------------------------------------------------------------------------
local function on_grid_inventory_put(pos, listname, index, stack, player)
    local meta = core.get_meta(pos)
    if string.sub(listname, 1, 5) == "grid_" then
        local cell = string.sub(listname, 6)
        if meta:get_string("recipe_" .. cell) == "" and not stack:is_empty() then
            meta:set_string("recipe_" .. cell, stack:to_string())
        end
        update_recipe_output(pos)
    end
end

local function on_grid_inventory_take(pos, listname, index, stack, player)
    local meta = core.get_meta(pos)
    if string.sub(listname, 1, 5) == "grid_" then
        local cell = string.sub(listname, 6)
        local inv = meta:get_inventory()
        -- If the cell becomes empty, clear its recipe.
        if inv:is_empty(listname) then
            meta:set_string("recipe_" .. cell, "")
        end
        update_recipe_output(pos)
    end
end

--------------------------------------------------------------------------------
-- Activation Function: When Powered, Try to Craft & Dispense the Output.
-- Consumes the required number of items from each grid cell that is configured.
--------------------------------------------------------------------------------
local function activate_crafter(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    
    -- Build the recipe from metadata.
    local recipe = {}
    local recipe_configured = false
    for i = 1, 9 do
        local rec_str = meta:get_string("recipe_" .. i)
        if rec_str and rec_str ~= "" then
            recipe_configured = true
            recipe[i] = ItemStack(rec_str)
        else
            recipe[i] = ItemStack("")
        end
    end
    if not recipe_configured then
        return
    end
    
    -- Check that in each configured cell, enough items are available.
    for i = 1, 9 do
        local rec_str = meta:get_string("recipe_" .. i)
        if rec_str and rec_str ~= "" then
            local required_stack = ItemStack(rec_str)
            local available_stack = inv:get_stack("grid_" .. i, 1)
            if available_stack:is_empty() or available_stack:get_name() ~= required_stack:get_name() or available_stack:get_count() < required_stack:get_count() then
                return  -- Ingredient missing or insufficient.
            end
        end
    end
    
    -- Consume the required amounts from each grid cell.
    for i = 1, 9 do
        local rec_str = meta:get_string("recipe_" .. i)
        if rec_str and rec_str ~= "" then
            local required_stack = ItemStack(rec_str)
            local available_stack = inv:get_stack("grid_" .. i, 1)
            available_stack:take_item(required_stack:get_count())
            inv:set_stack("grid_" .. i, 1, available_stack)
        end
    end
    
    -- Calculate and dispense the crafted output.
    local craft_req = { method = "normal", width = 3, items = recipe }
    local result = core.get_craft_result(craft_req).item
    if result and result:get_name() ~= "" then
        local node = core.get_node(pos)
        local dropdir = vector.multiply(core.facedir_to_dir(node.param2), -1)
        local droppos = vector.add(pos, dropdir)
        -- Add a small random offset:
        local pos_variation = 100
        droppos = vector.offset(
            droppos,
            math.random(-pos_variation, pos_variation) / 1000,
            math.random(-pos_variation, pos_variation) / 1000,
            math.random(-pos_variation, pos_variation) / 1000
        )
        local item_entity = core.add_item(droppos, result:to_string())
        local drop_vel = vector.subtract(droppos, pos)
        local speed = 3
        item_entity:set_velocity(vector.multiply(drop_vel, speed))
    end
end

--------------------------------------------------------------------------------
-- Hopper Insertion Function
-- A hopper will try to deposit one unit of any ingredient into the corresponding grid cell,
-- but only if that cell (as set by the automatic recipe) has fewer items than required.
--------------------------------------------------------------------------------
function mcl_crafter.on_hopper_in(hopper_pos, crafter_pos)
    local meta = core.get_meta(crafter_pos)
    local inv = meta:get_inventory()
    local donor_inv = core.get_inventory({ type = "node", pos = hopper_pos })
    local transferred = false

    -- First, loop over all grid cells that have a recipe configured.
    -- Record the current count per cell and determine the minimum count.
    local configured_slots = {}  -- key: grid index; value: table { rec_str, count }
    local min_count = nil

    for i = 1, 9 do
        local rec_str = meta:get_string("recipe_" .. i)
        if rec_str and rec_str ~= "" then
            local grid_stack = inv:get_stack("grid_" .. i, 1)
            local count = grid_stack:get_count()
            configured_slots[i] = { rec_str = rec_str, count = count }
            if not min_count or count < min_count then
                min_count = count
            end
        end
    end

    -- If no grid cell is configured, there’s nothing to do.
    if not min_count then
        return false
    end

    -- For each configured slot that is at the minimum count,
    -- try to move one matching ingredient from the hopper.
    for i, data in pairs(configured_slots) do
        -- Check if the cell’s count is equal to (or less than) the minimum.
        if data.count <= min_count then
            local recipe_stack = ItemStack(data.rec_str)
            -- Fetch the donor list from the hopper.
            local donor_list = donor_inv:get_list("main")
            for j, dstack in ipairs(donor_list) do
                if not dstack:is_empty() and dstack:get_name() == recipe_stack:get_name() then
                    -- Move one item from the hopper into the corresponding grid cell.
                    mcl_util.move_item_container(hopper_pos, crafter_pos, nil, j, "grid_" .. i)
                    transferred = true
                    -- Once an item is added for this slot, move on to the next slot.
                    break
                end
            end
        end
    end

    return transferred
end

--------------------------------------------------------------------------------
-- Crafter Node Definition (with redstone and hopper callbacks)
--------------------------------------------------------------------------------
local crafterdef = table.merge(commdef, {
    groups = table.merge(commdef.groups, { crafter = 1 }),
    description = S("Crafter"),
    _tt_help = S("3×3 crafting machine\nAutomatically sets its recipe when ingredients are placed and then crafts when powered"),
    _doc_items_longdesc = S("This crafter automatically configures its recipe from the first ingredients placed into its 9 separate grid cells. When every recipe cell contains enough items and redstone power is applied, it consumes the ingredients and dispenses the crafted item."),
    _doc_items_usagehelp = S("Place ingredients into the grid cells – each cell automatically records its ingredient type and required amount. Supply sufficient items (possibly via hoppers), then power the crafter with redstone to craft and dispense the output."),
    tiles = {
        "crafter_top.png", "crafter_bottom.png",
        "crafter_side.png", "crafter_side.png", "crafter_side.png", "crafter_front.png"
    },
    paramtype2 = "facedir",
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        setup_crafter(pos)
        orientate(pos, placer)
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        -- No manual button needed; configuration is automatic.
        return false
    end,
    _mcl_redstone = {
        connects_to = function(node, dir)
            return true
        end,
        update = function(pos, node)
            local oldpowered = math.floor(node.param2 / 32) ~= 0
            local powered = mcl_redstone and (mcl_redstone.get_power(pos) ~= 0) or false
            if powered and not oldpowered then
                activate_crafter(pos)
            end
            return {
                name = node.name,
                param2 = node.param2 % 32 + (powered and 32 or 0),
            }
        end,
    },
    _on_hopper_in = mcl_crafter.on_hopper_in,
    on_metadata_inventory_put = on_grid_inventory_put,
    on_metadata_inventory_take = on_grid_inventory_take,
})

--------------------------------------------------------------------------------
-- Register Crafter Node
--------------------------------------------------------------------------------
core.register_node("mcl_crafter:crafter", table.merge(crafterdef, {
    paramtype2 = "facedir",
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        setup_crafter(pos)
        orientate(pos, placer)
    end,
}))

--------------------------------------------------------------------------------
-- Crafting Recipe for the Crafter Block
--------------------------------------------------------------------------------
core.register_craft({
    output = "mcl_crafter:crafter",
    recipe = {
        { "mcl_core:iron_ingot", "mcl_core:iron_ingot",               "mcl_core:iron_ingot" },
        { "mcl_core:iron_ingot", "mcl_crafting_table:crafting_table",   "mcl_core:iron_ingot" },
        { "mcl_redstone:redstone", "mcl_dispensers:dropper",           "mcl_redstone:redstone" },
    },
})

