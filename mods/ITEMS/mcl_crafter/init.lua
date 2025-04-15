-- mcl_crafter/init.lua
-- A Minecraft-style Crafter that can be configured with a recipe.
-- When powered, if the ingredients in the crafting grid match the configured recipe,
-- the crafter consumes the ingredients and dispenses the crafted item.
-- Additionally, hoppers can insert only those ingredients that are needed by the current recipe.

local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape
local C = core.colorize

-- We assume that modules like mcl_formspec, mcl_sounds, mcl_redstone, mcl_util,
-- and screwdriver already exist in your modpack.

--------------------------------------------------------------------------------
-- Forms Interface (Crafter UI)
--------------------------------------------------------------------------------
mcl_crafter = {}  -- our mod’s namespace

local crafter_formspec = table.concat({
    "formspec_version[4]",
    "size[13,12]",
    "label[2.25,0.375;" .. F(C("#FFFF00", S("Crafter"))) .. "]",
    -- The crafting grid (3×3) for ingredients:
    "label[2.25,0.5;" .. F(S("Ingredients")) .. "]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(2.25, 0.75, 3, 3) or ""),
    "list[context;grid;2.25,0.75;3,3;]",
    -- An arrow for visual indication:
    "image[6.125,2;1.5,1;gui_crafting_arrow.png]",
    -- The output preview slot:
    "label[8.2,0.5;" .. F(S("Result")) .. "]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(8.2,2,1,1,0.2) or ""),
    "list[context;output;8.2,2;1,1;]",
    -- Button to set/clear the current recipe:
    "image_button[0.5,5;1,1;craftguide_book.png;__mcl_crafter_setrecipe;]",
    "tooltip[__mcl_crafter_setrecipe;" .. F(S("Set/Clear Recipe")) .. "]",
    -- Player inventory:
    "label[0.375,7.2;" .. F(C((mcl_formspec and mcl_formspec.label_color) or "#FFFFFF", S("Inventory"))) .. "]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(0.375,7.5,9,3) or ""),
    "list[current_player;main;0.375,7.5;9,3;9]",
    (mcl_formspec.get_itemslot_bg_v4 and mcl_formspec.get_itemslot_bg_v4(0.375,10.5,9,1) or ""),
    "list[current_player;main;0.375,10.5;9,1;]",
    "listring[context;grid]",
    "listring[current_player;main]",
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

	-- Log the attempt for both a player and a hopper
	core.log("action", "[Crafter] " .. source ..
	" attempted to insert " .. item_name .. " (x" .. item_count ..
	") into list '" .. listname .. "' at " .. pos_str)

	-- Only perform protection checks if a player is directly involved
	if player then
		if core.is_protected(pos, source) then
		    core.record_protection_violation(pos, source)
		    return 0
		end
	end

	return stack:get_count()
    end,

    on_metadata_inventory_move = function(pos, _, _, _, _, _, player)
        core.log("action", player:get_player_name() ..
            " moves items in crafter at " .. core.pos_to_string(pos))
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        core.log("action", player:get_player_name() ..
            " puts item in crafter at " .. core.pos_to_string(pos))
    end,
    on_metadata_inventory_take = function(pos, _, _, _, player)
        core.log("action", player:get_player_name() ..
            " takes item from crafter at " .. core.pos_to_string(pos))
    end,
    on_rotate = screwdriver and screwdriver.rotate_simple or nil,
    _mcl_blast_resistance = 3.5,
    _mcl_hardness = 3.5,
}

--------------------------------------------------------------------------------
-- Orientation Helper (similar to dispenser mod)
--------------------------------------------------------------------------------
local function orientate(pos, placer)
    if not placer then return end
    local node = core.get_node(pos)
    local facedir = core.dir_to_facedir(placer:get_look_dir())
    node.param2 = facedir
    core.swap_node(pos, node)
end

--------------------------------------------------------------------------------
-- Setup the Crafter (initialize metadata and inventories)
--------------------------------------------------------------------------------
local function setup_crafter(pos)
    local meta = core.get_meta(pos)
    meta:set_string("formspec", crafter_formspec)
    local inv = meta:get_inventory()
    inv:set_size("grid", 9)    -- input crafting grid
    inv:set_size("output", 1)  -- output slot (for preview/dispense)
    inv:set_size("recipe", 9)  -- hidden storage for the configured recipe
    -- Clear any previous configuration:
    meta:set_string("configured_recipe", "")
    meta:set_string("recipe_output", "")
end

--------------------------------------------------------------------------------
-- Recipe Configuration Handling
-- When the player presses the "Set/Clear Recipe" button:
-- If no recipe is currently set, copy the items from "grid" into the
-- hidden "recipe" list and compute the resulting item.
-- Otherwise, clear the configuration.
--------------------------------------------------------------------------------
local function on_crafter_receive_fields(pos, formname, fields, sender)
    local meta = core.get_meta(pos)
    if fields.__mcl_crafter_setrecipe then
        local inv = meta:get_inventory()
        local configured = meta:get_string("configured_recipe")
        if configured == "" then
            -- Set the recipe from the current grid:
            local recipe = inv:get_list("grid")
            local valid = false
            for i = 1, #recipe do
                if not recipe[i]:is_empty() then
                    valid = true
                    break
                end
            end
            if valid then
                for i = 1, 9 do
                    inv:set_stack("recipe", i, recipe[i])
                    inv:set_stack("grid", i, "")
                end
                meta:set_string("configured_recipe", "true")
                local craft_req = { method = "normal", width = 3, items = recipe }
                local result = core.get_craft_result(craft_req).item
                meta:set_string("recipe_output", result and result:to_string() or "")
                core.chat_send_player(sender:get_player_name(), S("Recipe configured: ") .. (result and result:to_string() or "Nothing"))
            else
                core.chat_send_player(sender:get_player_name(), S("Fill the ingredient grid to configure a recipe"))
            end
        else
            -- Clear the configuration:
            for i = 1, 9 do
                inv:set_stack("recipe", i, "")
            end
            meta:set_string("configured_recipe", "")
            meta:set_string("recipe_output", "")
            core.chat_send_player(sender:get_player_name(), S("Recipe configuration cleared."))
        end
        return true
    end
end

--------------------------------------------------------------------------------
-- Check & Consume Ingredients Matching the Configured Recipe
-- For each non-empty slot in "recipe", verify that the corresponding slot in "grid"
-- has at least the required count; if so, remove them.
--------------------------------------------------------------------------------
local function check_and_consume_recipe(inv)
    local recipe = inv:get_list("recipe")
    local grid = inv:get_list("grid")
    
    -- Accumulate required counts per item from the recipe.
    local required = {}   -- key: item name, value: total count required
    for i = 1, 9 do
        if recipe[i] and not recipe[i]:is_empty() then
            local name = recipe[i]:get_name()
            local count = recipe[i]:get_count()
            required[name] = (required[name] or 0) + count
        end
    end
    
    -- If there are no required items, return false
    if next(required) == nil then
        return false
    end
    
    -- Sum up items in the grid regardless of position.
    local available = {}  -- key: item name, value: total count available
    for i = 1, 9 do
        if grid[i] and not grid[i]:is_empty() then
            local name = grid[i]:get_name()
            local count = grid[i]:get_count()
            available[name] = (available[name] or 0) + count
        end
    end

    -- Check that every required item exists in sufficient quantity.
    for name, req_count in pairs(required) do
        if not available[name] or available[name] < req_count then
            return false
        end
    end

    -- Consume (remove) the required items from the grid.
    -- For each item type required, find and remove items until the quota is met.
    for name, req_count in pairs(required) do
        local remaining = req_count
        for i = 1, 9 do
            local stack = inv:get_stack("grid", i)
            if not stack:is_empty() and stack:get_name() == name then
                local available_in_stack = stack:get_count()
                local to_remove = math.min(available_in_stack, remaining)
                stack:take_item(to_remove)
                inv:set_stack("grid", i, stack)
                remaining = remaining - to_remove
                if remaining <= 0 then
                    break
                end
            end
        end
    end

    return true
end

--------------------------------------------------------------------------------
-- Activation Function: When Powered, Try to Craft & Dispense the Output.
-- Consumes ingredients if they match the configured recipe.
--------------------------------------------------------------------------------
local function activate_crafter(pos)
    local meta = core.get_meta(pos)
    if meta:get_string("configured_recipe") == "" then
        return
    end
    local inv = meta:get_inventory()
    if check_and_consume_recipe(inv) then
        local output_item = meta:get_string("recipe_output")
        if output_item == "" then 
            return 
        end
        local node = core.get_node(pos)
        -- Always use the facedir value to determine the drop direction.
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
        local item_entity = core.add_item(droppos, output_item)
        local drop_vel = vector.subtract(droppos, pos)
        local speed = 3
        item_entity:set_velocity(vector.multiply(drop_vel, speed))
    end
end

--------------------------------------------------------------------------------
-- Hopper Insertion Function
-- This function allows a hopper to deposit ONE unit of an ingredient into the crafter’s "grid"
-- but only if that ingredient is required by the current recipe configuration (i.e. when
-- the ingredient count in the grid is less than what the recipe demands).
--------------------------------------------------------------------------------
function mcl_crafter.on_hopper_in(hopper_pos, crafter_pos)
    local meta = core.get_meta(crafter_pos)
    if meta:get_string("configured_recipe") == "" then
        return false
    end
    local inv = meta:get_inventory()
    -- Get the donor inventory from the hopper:
    local donor_inv = core.get_inventory({ type = "node", pos = hopper_pos })
    local donor_list = donor_inv:get_list("main")
    local transferred = false
    -- For each slot in the crafter's grid, check if the recipe requires an ingredient:
    for i = 1, 9 do
        local recipe_stack = inv:get_stack("recipe", i)
        if not recipe_stack:is_empty() then
            local required_name = recipe_stack:get_name()
            local required_count = recipe_stack:get_count()
            local grid_stack = inv:get_stack("grid", i)
            local current_count = grid_stack:get_count()
            if current_count < required_count then
                -- Look for a matching item in the hopper's inventory:
                for j, dstack in ipairs(donor_list) do
                    if not dstack:is_empty() and dstack:get_name() == required_name then
                        -- Move one item from the donor inventory to the crafter's grid:
                        mcl_util.move_item_container(hopper_pos, crafter_pos, nil, j, "grid")
                        transferred = true
                        break
                    end
                end
                if transferred then break end
            end
        end
    end
    return transferred
end

--------------------------------------------------------------------------------
-- Crafter Node Definition (including redstone support and hopper callback)
--------------------------------------------------------------------------------
local crafterdef = table.merge(commdef, {
    groups = table.merge(commdef.groups, { crafter = 1 }),
    description = S("Crafter"),
    _tt_help = S("3×3 crafting machine\nConfigure a recipe, then supply matching ingredients to craft and dispense an item"),
    _doc_items_longdesc = S("A crafter is a configurable block that lets you set up a crafting recipe. Once the ingredients are provided in "
        .."its input grid and it receives redstone power, it consumes the ingredients and dispenses the crafted item."),
    _doc_items_usagehelp = S("Rightclick to open the interface. Place desired ingredients in the grid and press the Set/Clear Recipe button "
        .."to store (or clear) the recipe. With the recipe configured, supply matching ingredients or use a hopper to insert missing ones, then power the crafter with redstone to craft and dispense the item."),
    tiles = {
        "crafter_top.png", "crafter_bottom.png",
        "crafter_side.png", "crafter_side.png", "crafter_side.png", "crafter_front.png"
    },
    paramtype2 = "facedir",
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        setup_crafter(pos)
        orientate(pos, placer, "crafter")
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        return on_crafter_receive_fields(pos, formname, fields, sender)
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
    -- Register our hopper insertion callback:
    _on_hopper_in = mcl_crafter.on_hopper_in,
})

--------------------------------------------------------------------------------
-- Register Crafter Node
--------------------------------------------------------------------------------
core.register_node("mcl_crafter:crafter", table.merge(crafterdef, {
    paramtype2 = "facedir",  -- ensures orientation support
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
        { "mcl_core:iron_ingot", "mcl_crafting_table:crafting_table", "mcl_core:iron_ingot" },
        { "mcl_redstone:redstone", "mcl_dispensers:dropper", "mcl_redstone:redstone" },
    },
})


