
local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath .. "/engine/number_provider.lua")
dofile(modpath .. "/engine/predicate.lua")
dofile(modpath .. "/engine/item_modifier.lua")

local number = mcl_loot_new.number
local predicate = mcl_loot_new.predicate
local item_modifier = mcl_loot_new.item_modifier

--[[

table spec:

{
O   type: unused,
O   pools: {<pool>},
O   functions: {<item modifier>},
O   random_sequence: unused
}
pool:

{
O    conditions: {<predicate>},
O    functions: {<item modifier>},
    rolls: <I number provider>,
O    bonus_rolls: <F number provider>,
    entries: {<entry>},
}

entry:

{
    type: item|loot_table|dynamic|empty|tag|group|alternatives|sequence
}

type:
    item: conditions, functions, weight, quality, name,
    loot_table: conditions, functions, weight, quality, value
    dynamic: conditions, functions, weight, quality, name
    empty: conditions, functions, weight, quality
    tag: conditions, functions, weight, quality, name, expand
    group|alternatives|sequence
]]

-- Returns random number in [0, 1)
local function get_random(pr)
    return pr:next() / 4294967296 + 0.5
end

local function get_uniform(min, max, pr)
    return min + (max - min) * get_random(pr)
end


local function get_luck(context, pr)
    -- TODO: Implement
    error("Unimplemented")
    return 0
end


-- Get the modified weight based on luck
local function get_computed_weight(entry, context)
    local weight_bonus = (entry.quality == nil or entry.quality == 0) and 0 or (get_luck(context) * entry.quality)
    return math.max(math.floor((entry.weight or 1) + weight_bonus), 0)
end

-- Get loot associated with a picked entry
-- Does not apply item modifiers
local function get_entry_loot(entry, context, pr)
    local entry_type = entry.type
    if entry_type == "item" then
        return {ItemStack(entry.name)}
    elseif entry_type == "loot_table" then
        -- TODO: Implement
        error("Unimplemented")
    elseif entry_type == "dynamic" then
        -- TODO: Implement
        error("Unimplemented")
    elseif entry_type == "empty" then
        return {}
    elseif entry_type == "tag" then
        -- TODO: Implement
        error("Unimplemented")
    else
        error("Invalid singleton entry type: " .. entry_type)
    end
end

-- Expand all composite entries into singleton entries for the flattened pool
-- Checks conditions on children but NOT on the root entry
local function expand_pool_entry(entry, context, pr)
    local entry_type = entry.type
    if entry_type == "item" or entry_type == "loot_table" or entry_type == "dynamic" or entry_type == "empty" then
        return {entry}
    elseif entry_type == "tag" then
        -- TODO: Implement
        error("tag entry type unimplemented")
    elseif entry_type == "group" then
        -- Recursively expand children
        local successful_entries = {}
        for _, child_entry in ipairs(entry.children or {}) do
            if predicate.check_all_conditions(entry.conditions or {}, context, pr) then
                for _, add_entry in ipairs(expand_pool_entry(child_entry, context, pr)) do
                    table.insert(successful_entries, add_entry)
                end
            end
        end
        return successful_entries
    elseif entry_type == "alternatives" then
        for _, child_entry in ipairs(entry.children or {}) do
            if predicate.check_all_conditions(child_entry.conditions or {}, context, pr) then
                -- Recursively expand children
                return expand_pool_entry(child_entry, context, pr)
            end
        end
        return {}
    elseif entry_type == "sequence" then
        local successful_entries = {}
        for _, child_entry in ipairs(entry.children or {}) do
            if not predicate.check_all_conditions(child_entry.conditions or {}, context, pr) then break end
            -- Recursively expand children
            for add_entry in ipairs(expand_pool_entry(child_entry, context, pr)) do
                table.insert(successful_entries, add_entry)
            end
        end
        return successful_entries
    else
        error("Invalid entry type: " .. entry_type)
    end
end

local function sample_pool(pool, context, pr)
    -- If not all conditions are met, return empty loot
    if not predicate.check_all_conditions(pool.conditions or {}, context, pr) then return {} end

    -- Calculate number of rolls from `rolls` and `bonus_rolls`
    local rolls = number.evaluate_integer_provider(pool.rolls, context, pr)
    if pool.bonus_rolls ~= nil then
        rolls = rolls + math.floor(number.evaluate_float_provider(pool.bonus_rolls, context, pr) * get_luck(context))
    end

    -- Sample from pool
    local pool_output = {}
    for i = 1, rolls do
        local expanded_entries = {}
        for _, entry in ipairs(pool.entries) do
            if predicate.check_all_conditions(entry.conditions or {}, context, pr) then
                for _, successful_entry in ipairs(expand_pool_entry(entry, context, pr)) do
                    table.insert(expanded_entries, successful_entry)
                end
            end
        end

        local total_weight = 0
        local weights = {}
        for i, entry in ipairs(expanded_entries) do
            local entry_weight = get_computed_weight(entry, context)
            weights[i] = entry_weight
            total_weight = total_weight + entry_weight
        end

        -- Random number [0,total_weight)
        local weight_value = get_uniform(0, total_weight, pr)
        --core.debug(dump(expanded_entries))
        --core.debug(dump(weights), total_weight, weight_value)
        local chosen_entry
        for i, weight in ipairs(weights) do
            weight_value = weight_value - weight
            --core.debug("Val " .. weight_value)
            if weight_value <= 0 then
                --core.debug("Chose " .. i)
                chosen_entry = expanded_entries[i]
                break
            end
        end
        --core.debug(dump(chosen_entry))

        -- Get loot for chosen entry
        local generated_loot = get_entry_loot(chosen_entry, context, pr)

        -- Apply entry functions
        for i, itemstack in ipairs(generated_loot) do
            if chosen_entry.functions then
                itemstack = item_modifier.apply_all_functions(itemstack, chosen_entry.functions, context, pr)
            end
            table.insert(pool_output, itemstack)
        end
    end

    -- Apply pool functions
    if pool.functions then
        for i, itemstack in ipairs(pool_output) do
            pool_output[i] = item_modifier.apply_all_functions(itemstack, pool.functions, context, pr)
        end
    end

    core.debug("POOL LOOT: " .. dump(pool_output))
    return pool_output
end

function mcl_loot_new.sample_table(table_name, context, pr)
    if not mcl_loot_new.loot_table_exists(table_name) then
        error("Attempt to generate loot from invalid table: " .. tostring(table_name))
    end
    if pr == nil then
        error("'sample_table' argument 'pr' is required (was nil)")
    end
    local table_spec = mcl_loot_new.loot_tables[table_name]

    local generated_loot = {}
    for _, pool in ipairs(table_spec.pools or {}) do
        for _, itemstack in ipairs(sample_pool(pool, context, pr)) do
            table.insert(generated_loot, itemstack)
        end
    end

    -- If no item modifiers, return early
    if not table_spec.functions then
        return generated_loot
    end

    local modified_loot = {}
    -- Apply item modifiers
    for i, itemstack in ipairs(generated_loot) do
        modified_loot[i] = item_modifier.apply_all_functions(itemstack, table_spec.functions, context, pr)
    end
    return modified_loot
end

--core.register_on_mods_loaded(function()
--    local enchant_list = {}
--    for k, _ in pairs(mcl_enchanting.enchantments) do
--        table.insert(enchant_list, k)
--    end
--    core.debug(dump(enchant_list))
--end)

--[[
{
	"soul_speed",
	"infinity",
	"punch",
	"frost_walker",
	"luck_of_the_sea",
	"projectile_protection",
	"blast_protection",
	"fire_protection",
	"protection",
	"flame",
	"fortune",
	"silk_touch",
	"feather_falling",
	"piercing",
	"thorns",
	"curse_of_binding",
	"fire_aspect",
	"power",
	"quick_charge",
	"lure",
	"efficiency",
	"respiration",
	"breach",
	"density",
	"smite",
	"multishot",
	"wind_burst",
	"bane_of_arthropods",
	"sharpness",
	"unbreaking",
	"mending",
	"knockback",
	"curse_of_vanishing",
	"depth_strider",
	"looting",
}

]]