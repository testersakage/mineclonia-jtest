local modpath = core.get_modpath(core.get_current_modname())

mcl_loot_new = {}

mcl_loot_new.loot_tables = {}

dofile(modpath.."/engine.lua")
dofile(modpath.."/loot_context.lua")
dofile(modpath.."/commands.lua")


function mcl_loot_new.register_loot_table(table_name, table_spec)
    if mcl_loot_new.loot_table_exists(table_name) then
        core.log("warning", "Loot table being overwritten: " .. table_name)
    end
    mcl_loot_new.loot_tables[table_name] = table_spec
end

function mcl_loot_new.loot_table_exists(table_name)
    return mcl_loot_new.loot_tables[table_name] ~= nil
end

---- ## FROM OLD mcl_loot
--[[
Returns a table of length `max_slot` and all natural numbers between 1 and `max_slot`
in a random order.
]]
local function get_random_slots(max_slot, pr)
	local slots = {}
	for s=1, max_slot do
		slots[s] = s
	end
    table.shuffle(slots, 1, max_slot, function(min, max) return pr:next(min, max) end)
	return slots
end

---- ## FROM OLD mcl_loot
--[[
Puts items in an inventory list into random slots.
* inv: InvRef
* listname: Inventory list name
* items: table of items to add

Items will be added from start of the table to end.
If the inventory already has occupied slots, or is
too small, placement of some items might fail.
]]
local function fill_inventory(inv, listname, items, pr)
	local size = inv:get_size(listname)
	local slots = get_random_slots(size, pr)

	for i=1, math.min(#items, size) do
		local item = items[i]
		local slot = slots[i]
		local old_item = inv:get_stack(listname, slot)
		if old_item:is_empty() then
		    inv:set_stack(listname, slot, item)
        end
	end
end

-- Fill a specific list from an inventory table from a metadata table
local function fill_inventory_table(list, items, pr)
    local size = #list
	local slots = get_random_slots(size, pr)

	for i=1, math.min(#items, size) do
		local item = items[i]
		local slot = slots[i]
		local old_item = list[slot]
		if old_item:is_empty() then
		    list[slot] = item
        end
	end
end

local inv_noiseparams = {
    offset = 0,
    scale = 1,
    spread = {x = 1, y = 1, z = 1},
    seed = 530922,
    octaves = 1,
    persistence = 0,
    lacunarity = 0,
    flags = "noeased, absvalue",
}
-- Inventory filling order noise is based only on world seed and container position
-- Can't load now - noise functions can't be used at load time
local inv_noise

local function load_inv_noise()
    inv_noise = core.get_value_noise(inv_noiseparams)
end

local function get_fill_seed(pos)
    if inv_noise == nil then load_inv_noise() end
    -- fill_seed should be u64
    return inv_noise:get_3d(pos) * 18446744073709551615
end

-- Insert loot from `loot_table` into container at `pos`,
-- using `seed` for RNG and `context` as loot context params
function mcl_loot_new.container_insert_loot(inv, loot_table, context, seed, pos)
    local loot = mcl_loot_new.sample_table(loot_table, context, PcgRandom(seed))
    core.debug("LOOT: " .. dump(loot))
    local fill_seed = get_fill_seed(pos)
    fill_inventory(inv, "main", loot, PcgRandom(fill_seed))
end

-- Insert loot from `loot_table` into metadata table representing a container at `pos`,
-- using `seed` for RNG and `context` as loot context params
function mcl_loot_new.metadata_table_insert_loot(table, loot_table, context, seed, pos)
    local loot = mcl_loot_new.sample_table(loot_table, context, PcgRandom(seed))
    local fill_seed = get_fill_seed(pos)
    local list = table.inventory["main"]
    fill_inventory_table(list, loot, PcgRandom(fill_seed))
end

local function get_loot_meta(meta)
    local loot_table = meta:get("loot_table")
    local loot_table_seed = meta:get("loot_table_seed")
    return {
        loot_table = loot_table,
        seed = loot_table_seed
    }
end

local function get_loot_meta_from_table(meta)
    local fields = meta.fields
    local loot_table = fields["loot_table"]
    local loot_table_seed = fields["loot_table_seed"]
    return {
        loot_table = loot_table,
        seed = loot_table_seed
    }
end

local function clear_loot_meta(meta)
    meta:set_string("loot_table", "")
    meta:set_string("loot_table_seed", "")
end

local function clear_loot_meta_from_table(meta)
    meta["loot_table"] = nil
    meta["loot_table_seed"] = nil
end

-- `player` can be nil
-- TODO: Support barrel, chest, trapped chest, hopper, dispenser, dropper, shulker box, dyed shulker box, and decorated pot
function mcl_loot_new.materialise_container_loot(pos, player)
    core.debug("try materialising loot")
    local meta = core.get_meta(pos)
    local loot_info = get_loot_meta(meta)
    if loot_info.loot_table == nil then return false end
    core.debug("actually materialising loot")

    core.debug("SEED: " .. tostring(loot_info.seed))

    if loot_info.seed == nil then
        loot_info.seed = math.random(0, 18446744073709551615)
    end
    local context = mcl_loot_new.loot_context.generate_for_chest(pos, player)
    local inv = meta:get_inventory()
    -- TODO: Should meta be cleared before loot is generated?
    -- This eliminates any possible duplication bugs,
    -- but if the loot table is invalid then loot will never be generated
    clear_loot_meta(meta)
    mcl_loot_new.container_insert_loot(inv, loot_info.loot_table, context, loot_info.seed, pos)
end

-- `player` can be nil
-- TODO: Support barrel, chest, trapped chest, hopper, dispenser, dropper, shulker box, dyed shulker box, and decorated pot
function mcl_loot_new.materialise_container_loot_in_metadata_table(pos, player, metadata_table)
    core.debug("try materialising loot")
    core.debug(dump(metadata_table))
    local loot_info = get_loot_meta_from_table(metadata_table)
    if loot_info.loot_table == nil then return false end
    core.debug("actually materialising loot")

    if loot_info.seed == nil then
        loot_info.seed = math.random(0, 18446744073709551615)

    end
    local context = mcl_loot_new.loot_context.generate_for_chest(pos, player)
    -- TODO: Should meta be cleared before loot is generated?
    -- This eliminates any possible duplication bugs,
    -- but if the loot table is invalid then loot will never be generated
    clear_loot_meta_from_table(metadata_table)
    mcl_loot_new.metadata_table_insert_loot(metadata_table, loot_info.loot_table, context, loot_info.seed, pos)
end

dofile(modpath.."/chests/init.lua")













local function get_first_line(s)
    return core.strip_colors(s:sub(0, string.find(s, "\n")))
end


core.register_chatcommand("items", {
    params = "",
    description = "Debug all items",
    privs = {debug = true},
    func = function(name, param)
        for item_name, item_spec in pairs(core.registered_items) do
            core.debug(item_name .. "|" .. get_first_line(item_spec.description))
        end
    end
})

local function place_chest_with_lootmeta(pos, loot_table, seed)
    core.set_node(pos, {name="mcl_chests:chest_small"})
    local meta = core.get_meta(pos)
    meta:set_string("loot_table", loot_table)
    -- Lua API doc says that `get_int`/`set_int` uses a system-dependent size (usually 32 bits)
    -- so we use a string instead
    meta:set_string("loot_table_seed", tostring(seed))
end

core.register_chatcommand("lootmeta", {
    params = "",
    description = "Place chest with lootmeta",
    privs = {debug = true},
    func = function(name, param)
        local words = param:gmatch("%S+")

        local coords = {}
        for _, coord_key in ipairs({"x", "y", "z"}) do
            local new_coord = words()
            if new_coord == nil then
                return false, "You must specify a " .. coord_key .. " coordinate for the chest"
            end
            local new_coord_parsed = tonumber(new_coord)
            if new_coord_parsed == nil then
                return false, "Invalid value for " .. coord_key .. " coordinate: " .. tostring(new_coord)
            end
            coords[coord_key] = new_coord_parsed
        end

        local loot_table = words()
        local loot_seed = words()
        if loot_seed == nil then
            loot_seed = math.random(0, 9223372036854775807)
        else
            loot_seed = tonumber(loot_seed)
        end

        place_chest_with_lootmeta(coords, loot_table, loot_seed)
    end
})



local function dbg_meta_at(pos)
    core.debug(dump(core.get_meta(pos):to_table()))
end


core.register_chatcommand("showmeta", {
    params = "",
    description = "Show node meta",
    privs = {debug = true},
    func = function(name, param)
        local words = param:gmatch("%S+")

        local coords = {}
        for _, coord_key in ipairs({"x", "y", "z"}) do
            local new_coord = words()
            if new_coord == nil then
                return false, "You must specify a " .. coord_key .. " coordinate for the chest"
            end
            local new_coord_parsed = tonumber(new_coord)
            if new_coord_parsed == nil then
                return false, "Invalid value for " .. coord_key .. " coordinate: " .. tostring(new_coord)
            end
            coords[coord_key] = new_coord_parsed
        end

        --core.debug(dump(core.get_meta(coords):to_table()))
        dbg_meta_at(coords)
        dbg_meta_at({x=0,y=41,z=0})
    end
})


core.register_chatcommand("metaprocess", {
    params = "",
    description = "Save metadata in new mapgen format",
    privs = {debug = true},
    func = function(name, param)
        local slash_pos = param:find("/")

        local filename = param:sub(1, slash_pos-1)
        local data = param:sub(slash_pos+1)

        local table_data = load("return " .. data)()
        core.debug("Writing: " .. dump(table_data))
        local serialised = core.serialize(table_data)
        core.debug("Serialised: " .. serialised)
        local compressed = core.compress(serialised, "zstd")
        core.debug("Actually writing: " .. compressed)

        local file = io.open(modpath.."/metadata/"..filename, "wb")
        file:write(compressed)
        file:close()


        core.debug(string.len(compressed))
        core.debug(core.decompress(compressed, "zstd"))

        local file = io.open(modpath.."/metadata/"..filename, "rb")
        local recovered = file:read("*all")
        file:close()
        core.debug(string.len(recovered))
        core.debug(recovered)
        core.debug(core.decompress(recovered, "zstd"))
        return true, "Successfully wrote data to " .. modpath.."/metadata/"..filename
    end
})
