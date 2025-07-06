
local function execute_loot_command(target_options, source_options, player_name)
    local loot
    if source_options.command == "loot" then
        loot = mcl_loot_new.sample_table(source_options.loot_table, {}, PcgRandom(math.random(0, 1000000)))
    else
        -- Unreachable if called from chatcommand function
        error("Invalid loot source command: " .. source_options.command)
    end

    if target_options.command == "give" then
        if not core.player_exists(player_name) then
            return false, "No such player: " .. tostring(player_name)
        end
        local player = core.get_player_by_name(player_name)
        if player == nil then
            return false, "Player not online: " .. tostring(player_name)
        end

        local player_inv = player:get_inventory({type="player", name=player_name})
        for _, itemstack in ipairs(loot) do
            player_inv:add_item("main", itemstack)
        end
        return true, "Loot added to player inventory"
    elseif target_options.command == "insert" then
        local meta = core.get_meta(target_options.pos)
        local inv = meta:get_inventory()

        for _, itemstack in ipairs(loot) do
            inv:add_item("main", itemstack)
        end
        return true, "Loot added to node inventory"
    else
        -- Unreachable if called from chatcommand function
        error("Invalid loot target command: " .. target_options.command)
    end
end

core.register_chatcommand("loot", {
    params = "loot (give <playerName> | insert <targetPos> | spawn <targetPos>) (loot <loot_table>)",
    description = "Give loot (WIP)",
    privs = {debug = true},
    func = function(name, param)
        local words = param:gmatch("%S+")

        -- PARSING TARGET COMMAND
        local target_command = words()
        local target_options
        if target_command == "give" then
            local player_name = words()
            if player_name == nil then
                return false, "You must specify a player to give loot to"
            end
            target_options = {
                command = "give",
                player = player_name
            }
        elseif target_command == "insert" then
            local coords = {}
            for _, coord_key in ipairs({"x", "y", "z"}) do
                local new_coord = words()
                if new_coord == nil then
                    return false, "You must specify a " .. coord_key .. " coordinate for the container block"
                end
                local new_coord_parsed = tonumber(new_coord)
                if new_coord_parsed == nil then
                    return false, "Invalid value for " .. coord_key .. " coordinate: " .. tostring(new_coord)
                end
                coords[coord_key] = new_coord_parsed
            end
            target_options = {
                command = "insert",
                pos = coords
            }
        elseif target_command == "spawn" then
            -- TODO: Implement
            error("Unimplemented")
        elseif target_command == nil then
            return false, "You must specify a loot target. Use one of 'give', 'insert', 'spawn'"
        else
            return false, "Invalid target command: " .. tostring(target_command) .. ". Use one of 'give', 'insert', 'spawn'"
        end

        -- PARSING SOURCE COMMAND
        local source_command = words()
        local source_options
        if source_command == "loot" then
            local loot_table = words()
            if loot_table == nil then
                return false, "You must specify a loot table to source loot from"
            end
            if not mcl_loot_new.loot_table_exists(loot_table) then
                return false, "No such loot table: " .. tostring(loot_table)
            end
            source_options = {
                command = "loot",
                loot_table = loot_table
            }
        elseif source_command == nil then
            return false, "You must specify a loot source. Use one of 'loot'"
        else
            return false, "Invalid source command: " .. tostring(source_command) .. ". Use one of 'loot'"
        end

        return execute_loot_command(target_options, source_options, name)
    end
})
