local function get_treasure_map(cpos)
	local stack = ItemStack("mcl_books:written_book")
	local bookmeta = stack:get_meta()
	bookmeta:set_string("text", "There is a treasure at \n"..core.pos_to_string(cpos))
	bookmeta:set_string("author", "The Albatross")
	bookmeta:set_string("title", "Treasure")
	bookmeta:set_string("description", "Treasure")
	return stack
end

-- TODO: Move buried treasures to being a structure, so maps can be made for any structure
-- Also, maps often don't generate because there's no shore within 64 nodes
-- TODO: Add "exploration_map" item modifier
local function generate_treasure(_, context, pr)
    local ship_pos = context.origin
    local pos = vector.new(ship_pos.x, 1, ship_pos.z)
    local sand = core.find_nodes_in_area_under_air(vector.offset(pos, -64, -4, -64), vector.offset(pos, 64, 5, 64), {"mcl_core:sand", "mcl_core:gravel", "mcl_core:dirt_with_grass", "mcl_core:mycelium", "mcl_core:podzol"})
    core.debug("Treasure feasible locations: " .. tostring(#sand))
    if sand and #sand > 0 then
        table.shuffle(sand)
        local ppos = sand[pr:next(1,math.min(#sand, 6400))]
        local depth = pr:next(1,4)
        local cpos = vector.offset(ppos, 0, -depth, 0)
        core.swap_node(cpos, {name = "mcl_chests:chest_small"})
        core.registered_nodes["mcl_chests:chest_small"].on_construct(cpos)
        mcl_loot_new.generate_set_lootmeta(core.get_meta(cpos), "chest/buried_treasure", pr)
        return get_treasure_map(cpos)
    end
    return ItemStack("")
end

mcl_loot_new.register_loot_table("chest/shipwreck_map", {
    pools = {
        {
            rolls = 1,
            entries = {
                {
                    -- TODO: Implement "exploration_map" item modifier
                    type = "item",
                    name = "mcl_maps:empty_map",
                    weight = 1,
                    functions = {{["function"] = "lua_function", value=generate_treasure}}
                }
            }
        },
        {
            rolls = 3,
            entries = {
                {
                    type = "item",
                    name = "mcl_core:paper",
                    weight = 20,
                    functions = {{["function"] = "set_count", count={min=1, max=10}}}
                },
                {
                    type = "item",
                    name = "mcl_mobitems:feather",
                    weight = 10,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_books:book",
                    weight = 5,
                    functions = {{["function"] = "set_count", count={min=1, max=5}}}
                },
                {
                    type = "item",
                    name = "mcl_clock:clock",
                    weight = 1,
                },
                {
                    type = "item",
                    name = "mcl_compass:compass",
                    weight = 1,
                },
                {
                    type = "item",
                    name = "mcl_maps:empty_map",
                    weight = 1,
                },
            }
        }
    }
})