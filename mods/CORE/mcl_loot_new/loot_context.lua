mcl_loot_new.loot_context = {}

local loot_context = mcl_loot_new.loot_context

function loot_context.generate_for_chest(pos, player)
    return {
        origin = pos,
        doer = player
    }
end