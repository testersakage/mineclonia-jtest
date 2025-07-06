mcl_loot_new.predicate = {}
local predicate = mcl_loot_new.predicate

function predicate.check_condition(condition, context, pr)
    -- TODO: Implement
    return true
end

-- Convenience function checking all conditions in an array are met
function predicate.check_all_conditions(conditions, context, pr)
    for _, condition in ipairs(conditions) do
        if not predicate.check_condition(condition, context, pr) then
            return false
        end
    end
    return true
end
