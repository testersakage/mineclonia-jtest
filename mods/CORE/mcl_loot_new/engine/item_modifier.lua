mcl_loot_new.item_modifier = {}
local item_modifier = mcl_loot_new.item_modifier

function resolve_enchantments_specifier(specifier)
    -- For now, must be a single enchantment or a list of enchantments
    -- TODO: Add tags
    if type(specifier) == "string" then
        return {specifier}
    elseif type(specifier) == "table" then -- table
        return specifier
    elseif specifier == nil then
        return mcl_enchanting.all_enchantments
    else
        error("Invalid enchantment options: " .. tostring(specifier))
    end
end


function item_modifier.apply_item_function(itemstack, func, context, pr)
    if not func["function"] then
        -- Interpret as array
        return item_modifier.apply_all_functions(itemstack, func, context, pr)
    end

    if not mcl_loot_new.predicate.check_all_conditions(func.conditions or {}, context, pr) then
        return itemstack
    end
    
    local function_type = func["function"]
    if function_type == "set_count" then
        local new_count = mcl_loot_new.number.evaluate_integer_provider(func.count, context, pr) + (func.add and itemstack:get_count() or 0)
        itemstack:set_count(new_count)
        return itemstack
    elseif function_type == "enchant_randomly" then
        -- TODO: Test the `only_compatible` option
        local only_compatible = func.only_compatible == nil and true or func.only_compatible
        core.debug("ENCHANT STATE: " .. pr:get_state())
        return mcl_enchanting.enchant_uniform_randomly_from(itemstack, resolve_enchantments_specifier(func.options), only_compatible, pr)
    else
        error("Invalid loot function: " .. function_type)
    end
end

function item_modifier.apply_all_functions(itemstack, functions, context, pr)
    for _, func in ipairs(functions) do
        itemstack = item_modifier.apply_item_function(itemstack, func, context, pr)
    end
    return itemstack
end