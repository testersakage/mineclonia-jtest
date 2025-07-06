mcl_loot_new.number = {}
local number = mcl_loot_new.number

-- Returns random number in [0, 1)
local function get_random(pr)
    return pr:next() / 4294967296 + 0.5
end

local function get_uniform(min, max, pr)
    return min + (max - min) * get_random(pr)
end

function number.evaluate_integer_provider(provider, context, pr)
    -- TODO: Implement
    if type(provider) == "number" then
        -- Number is shothand for "type" of "constant"
        return provider -- TODO: Maybe take floor?
    end

    -- Assume type is table
    local provider_type = provider.type
    if provider_type == nil then
        -- no "type" field is shorthand for uniform
        return get_uniform(provider.min, provider.max, pr)
    elseif provider_type == "constant" then
        return provider.value
    elseif provider_type == "uniform" then
        return get_uniform(provider.min, provider.max, pr)
    elseif provider_type == "binomial" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "score" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "storage" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "enchantment_level" then
        -- TODO: Implement
        error("Unimplemented")
    else
        error("Invalid number provider type: " .. provider_type)
    end
end

function number.evaluate_float_provider(provider, context, pr)
    -- TODO: Implement
    if type(provider) == "number" then
        -- Number is shothand for "type" of "constant"
        return provider
    end

    -- Assume type is table
    local provider_type = provider.type
    if provider_type == nil then
        -- no "type" field is shorthand for uniform
        return get_uniform(provider.min, provider.max)
    elseif provider_type == "constant" then
        return provider.value
    elseif provider_type == "uniform" then
        return get_uniform(provider.min, provider.max)
    elseif provider_type == "binomial" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "score" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "storage" then
        -- TODO: Implement
        error("Unimplemented")
    elseif provider_type == "enchantment_level" then
        -- TODO: Implement
        error("Unimplemented")
    else
        error("Invalid number provider type: " .. provider_type)
    end
end
