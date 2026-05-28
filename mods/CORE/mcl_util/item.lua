-- mineclonia/mods/CORE/mcl_util/item.lua
minetest.log("action", "[util/item.lua] 02 C++ API.")
local fuel_cache = {}

-- Returns the burntime of an item
-- Returns false otherwise
function mcl_util.get_burntime(item)
	assert(core.get_current_modname() == nil, "mcl_util.is_fuel and mcl_util.get_burntime cannot be called when loading mods")
	if fuel_cache[item] == nil then
		fuel_cache[item] = core.get_craft_result({method = "fuel", width = 1, items = {item}}).time
	end

	return fuel_cache[item]
end

-- Returns true if item (itemstring or ItemStack) can be used as a furnace fuel.
-- Returns false otherwise
function mcl_util.is_fuel(item)
	return mcl_util.get_burntime(item) ~= 0
end

function mcl_util.calculate_durability(itemstack)
	local name = itemstack:get_name()
	local unbreaking_level = mcl_enchanting.get_enchantment(itemstack, "unbreaking")
	local armor_uses = core.get_item_group(name, "mcl_armor_uses")
	local elytra = core.get_item_group(name, "elytra")

	local uses

	if armor_uses > 0 then
		uses = armor_uses
		if unbreaking_level > 0 then
			if elytra <= 0 then
				uses = uses / (0.6 + 0.4 / (unbreaking_level + 1))
			else
				uses = uses * (unbreaking_level + 1)
			end
		end
	else
		local def = itemstack:get_definition()
		if def then
			local fixed_uses = def._mcl_uses
			if fixed_uses then
				uses = fixed_uses
				if unbreaking_level > 0 then
					uses = uses * (unbreaking_level + 1)
				end
			end
		end

		local _, groupcap = next(itemstack:get_tool_capabilities().groupcaps)
		uses = uses or (groupcap or {}).uses
	end

	return uses or 0
end

function mcl_util.use_item_durability(itemstack, n)
	if n > 0 then
		local uses = mcl_util.calculate_durability(itemstack)
		itemstack:add_wear_by_uses (math.floor (uses / n))
	end
end


function mcl_util.move_item(source_inventory, source_list, source_stack_id, destination_inventory, destination_list)
	if source_stack_id == -1 then
		source_stack_id = mcl_util.get_eligible_transfer_item_slot(source_inventory, source_list)
		if source_stack_id == nil then
			return false
		end
	end

	if not source_inventory:is_empty(source_list) then
		local stack = source_inventory:get_stack(source_list, source_stack_id)
		if not stack:is_empty() then
			local new_stack = ItemStack(stack)
			new_stack:set_count(1)
			if not destination_inventory:room_for_item(destination_list, new_stack) then
				return false
			end
			stack:take_item()
			source_inventory:set_stack(source_list, source_stack_id, stack)
			destination_inventory:add_item(destination_list, new_stack)

			-- ─── 🏆 vector メタテーブル自動付与（お掃除完了版） ───
			local dummy_vector = vector.new(0, 0, 0)
			local vector_meta = getmetatable(dummy_vector)

			local source_location = source_inventory:get_location()
			if source_location and source_location.type == "node" then
				local pos = source_location.pos
				if pos and type(pos) == "table" and not getmetatable(pos) and vector_meta then
					setmetatable(pos, vector_meta)
				end
				mcl_redstone.update_comparators(pos)
			end

			local destination_location = destination_inventory:get_location()
			if destination_location and destination_location.type == "node" then
				local pos = destination_location.pos
				if pos and type(pos) == "table" and not getmetatable(pos) and vector_meta then
					setmetatable(pos, vector_meta)
				end
				mcl_redstone.update_comparators(pos)
			end
			-- ─── 🏆 ここまで ───

			return true
		end
	end
	return false
end


-- ─── 登録・結合コード ───
-- すべてのModがロードされ、region_classが創世された瞬間に耐久値減算能力を強制相乗り同期
core.register_on_mods_loaded(function()
	local rc = rawget(_G, "region_class") or (mcl_util and mcl_util.region_class)
	if rc then
		rc.use_item_durability = mclcapi.calculate_durability
		rc.use_item_durability = mclcapi.use_item_durability
	end
end)
