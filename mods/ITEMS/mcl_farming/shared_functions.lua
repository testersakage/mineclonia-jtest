mcl_farming.plant_lists = {}

local plant_lists = {}

local plant_nodename_to_id_list = {}

local function get_intervals_counter(pos, interval, chance)
	local meta = minetest.get_meta(pos)
	local time_speed = tonumber(minetest.settings:get("time_speed") or 72)
	local current_game_time
	if time_speed == nil then
		return 1
	end
	if (time_speed < 0.1) then
		return 1
	end
	local time_multiplier = 86400 / time_speed
	current_game_time = .0 + ((minetest.get_day_count() + minetest.get_timeofday()) * time_multiplier)

	local approx_interval = math.max(interval, 1) * math.max(chance, 1)

	local last_game_time = meta:get_string("last_gametime")
	if last_game_time then
		last_game_time = tonumber(last_game_time)
	end
	if not last_game_time or last_game_time < 1 then
		last_game_time = current_game_time - approx_interval / 10
	elseif last_game_time == current_game_time then
		current_game_time = current_game_time + approx_interval
	end

	local elapsed_game_time = .0 + current_game_time - last_game_time

	meta:set_string("last_gametime", tostring(current_game_time))

	return elapsed_game_time / approx_interval
end

local function get_avg_light_level(pos)
	local node_light = tonumber(minetest.get_node_light(pos) or 0)
	local meta = minetest.get_meta(pos)
	local counter = meta:get_int("avg_light_count")
	local summary = meta:get_int("avg_light_summary")
	if counter > 99 then
		counter = 51
		summary = math.ceil((summary + 0.0) / 2.0)
	else
		counter = counter + 1
	end
	summary = summary + node_light
	meta:set_int("avg_light_count", counter)
	meta:set_int("avg_light_summary", summary)
	return math.ceil((summary + 0.0) / counter)
end

function mcl_farming:add_plant(identifier, full_grown, names, interval, chance)
	mcl_farming.plant_lists[identifier] = {}
	mcl_farming.plant_lists[identifier].full_grown = full_grown
	mcl_farming.plant_lists[identifier].names = names
	mcl_farming.plant_lists[identifier].interval = interval
	mcl_farming.plant_lists[identifier].chance = chance
	plant_lists = mcl_farming.plant_lists --provide local copy of plant lists (performances)
	minetest.register_abm({
		label = string.format("Farming plant growth (%s)", identifier),
		nodenames = names,
		interval = interval,
		chance = chance,
		action = function(pos, node)
			local low_speed = minetest.get_node({ x = pos.x, y = pos.y - 1, z = pos.z }).name ~= "mcl_farming:soil_wet"
			mcl_farming:grow_plant(identifier, pos, node, false, false, low_speed)
		end,
	})
	for _, nodename in pairs(names) do
		plant_nodename_to_id_list[nodename] = identifier
	end
end

-- Attempts to advance a plant at pos by one or more growth stages (if possible)
-- identifier: Identifier of plant as defined by mcl_farming:add_plant
-- pos: Position
-- node: Node table
-- stages: Number of stages to advance (optional, defaults to 1)
-- ignore_light: if true, ignore light requirements for growing

-- Returns true if plant has been grown by 1 or more stages.
-- Returns false if nothing changed.
function mcl_farming:grow_plant(identifier, pos, node, stages, ignore_light, low_speed)
	local average_light_level = get_avg_light_level(pos)
	local plant_info = plant_lists[identifier]
	local intervals_counter = get_intervals_counter(pos, plant_info.interval, plant_info.chance)
	local low_speed = low_speed or false
	if low_speed then
		if intervals_counter < 1.01 and math.random(0, 9) > 0 then
			return
		else
			intervals_counter = intervals_counter / 10
		end
	end
	if not minetest.get_node_light(pos) and not ignore_light and intervals_counter < 1.5 then
		return false
	end
	if minetest.get_node_light(pos) < 10 and not ignore_light and intervals_counter < 1.5 then
		return false
	end

	if intervals_counter >= 1.5 then
		if average_light_level < 0.1 then
			return false
		end
		if average_light_level < 10 then
			intervals_counter = intervals_counter * average_light_level / 10
		end
	end

	local step = nil

	for i, name in ipairs(plant_info.names) do
		if name == node.name then
			step = i
			break
		end
	end
	if step == nil then
		return false
	end
	if not stages then
		stages = 1
	end
	stages = stages + math.ceil(intervals_counter)
	local new_node = { name = plant_info.names[step + stages] }
	if new_node.name == nil then
		new_node.name = plant_info.full_grown
	end
	new_node.param = node.param
	new_node.param2 = node.param2
	minetest.set_node(pos, new_node)
	return true
end

function mcl_farming:place_seed(itemstack, placer, pointed_thing, plantname)
	local pt = pointed_thing
	if not pt then
		return
	end
	if pt.type ~= "node" then
		return
	end

	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if rc then return rc end

	local pos = { x = pt.above.x, y = pt.above.y - 1, z = pt.above.z }
	local farmland = minetest.get_node(pos)
	pos = { x = pt.above.x, y = pt.above.y, z = pt.above.z }
	local place_s = minetest.get_node(pos)

	if string.find(farmland.name, "mcl_farming:soil") and string.find(place_s.name, "air") then
		minetest.sound_play(minetest.registered_nodes[plantname].sounds.place, { pos = pos }, true)
		minetest.add_node(pos, { name = plantname, param2 = minetest.registered_nodes[plantname].place_param2 })
		--local intervals_counter = get_intervals_counter(pos, 1, 1)
	else
		return
	end

	if not minetest.is_creative_enabled(placer:get_player_name()) then
		itemstack:take_item()
	end
	return itemstack
end

-- Used for growing gourd stems. Returns the intermediate color between startcolor and endcolor at a step
-- * startcolor: ColorSpec in table form for the stem in its lowest growing stage
-- * endcolor: ColorSpec in table form for the stem in its final growing stage
-- * step: The nth growth step. Counting starts at 1
-- * step_count: The number of total growth steps
function mcl_farming:stem_color(startcolor, endcolor, step, step_count)
	local color = {}
	local function get_component(startt, endd, step, step_count)
		return math.floor(math.max(0, math.min(255, (startt + (((step - 1) / step_count) * endd)))))
	end
	color.r = get_component(startcolor.r, endcolor.r, step, step_count)
	color.g = get_component(startcolor.g, endcolor.g, step, step_count)
	color.b = get_component(startcolor.b, endcolor.b, step, step_count)
	local colorstring = string.format("#%02X%02X%02X", color.r, color.g, color.b)
	return colorstring
end

--[[Get a callback that either eats the item or plants it.

Used for on_place callbacks for craft items which are seeds that can also be consumed.
]]
function mcl_farming:get_seed_or_eat_callback(plantname, hp_change)
	return function(itemstack, placer, pointed_thing)
		local new = mcl_farming:place_seed(itemstack, placer, pointed_thing, plantname)
		if new then
			return new
		else
			return minetest.do_item_eat(hp_change, nil, itemstack, placer, pointed_thing)
		end
	end
end

function mcl_farming.on_bone_meal(_, _, _, pos, n, plant,stages)
	local stages = stages or math.random(2, 5)
	return mcl_farming:grow_plant(plant, pos, n, stages, true)
end

minetest.register_lbm({
	label = "Add growth for unloaded farming plants",
	name = "mcl_farming:growth",
	nodenames = { "group:plant" },
	run_at_every_load = true,
	action = function(pos, node)
		local identifier = plant_nodename_to_id_list[node.name]
		if not identifier then
			return
		end
		local low_speed = minetest.get_node({ x = pos.x, y = pos.y - 1, z = pos.z }).name ~= "mcl_farming:soil_wet"
		mcl_farming:grow_plant(identifier, pos, node, false, false, low_speed)
	end,
})

local connected_stem_nodebox = {
	{-0.5, -0.5, 0, 0.5, 0.5, 0},
	{-0.5, -0.5, 0, 0.5, 0.5, 0},
	{0, -0.5, -0.5, 0, 0.5, 0.5},
	{0, -0.5, -0.5, 0, 0.5, 0.5}
}

local connected_stem_selectionbox = {
	{-0.1, -0.5, -0.1, 0.5, 0.2, 0.1},
	{-0.5, -0.5, -0.1, 0.1, 0.2, 0.1},
	{-0.1, -0.5, -0.1, 0.1, 0.2, 0.5},
	{-0.1, -0.5, -0.5, 0.1, 0.2, 0.1}
}

function mcl_farming.get_stem_nodebox(index) return connected_stem_nodebox[index] end

function mcl_farming.get_stem_selectionbox(index) return connected_stem_selectionbox[index] end

function mcl_farming.get_stem_tiles(texture, index)
	local connected_stem_tiles = {
		{"blank.png", "blank.png", "blank.png", "blank.png", texture, texture .. "^[transformFX"},
		{"blank.png", "blank.png", "blank.png", "blank.png", texture .. "^[transformFX", texture},
		{"blank.png", "blank.png", texture .. "^[transformFX", texture, "blank.png", "blank.png"},
		{"blank.png", "blank.png", texture, texture .. "^[transformFX", "blank.png", "blank.png"}
	}
	return connected_stem_tiles[index]
end

local neighbors = {
	vector.new(-1, 0, 0),
	vector.new(1, 0, 0),
	vector.new(0, 0, -1),
	vector.new(0, 0, 1)
}

local function get_connected_stem(name, neighbor)
	if neighbor.x == -1 then
		return name .. "_r"
	elseif neighbor.x == 1 then
		return name .. "_l"
	elseif neighbor.z == -1 then
		return name .. "_t"
	elseif neighbor.z == 1 then
		return name .. "_b"
	end
end

function mcl_farming.unconnect_gourd(pos)
	local gourd_defs = core.registered_nodes[core.get_node(pos).name]
	local linked_name = gourd_defs._mcl_farming_linked_stem

	for _, neighbor in pairs(neighbors) do
		local expected_stem = get_connected_stem(linked_name, neighbor)
		local stem_pos = vector.add(pos, neighbor)
		local stem = core.get_node(stem_pos)
		local stem_defs = core.registered_nodes[stem.name]

		if stem.name == expected_stem then
			core.add_node(stem_pos, {name = stem_defs._mcl_farming_unconnected_stem})
			mcl_farming.try_connect_stem(stem_pos)
		end
	end
end

function mcl_farming.try_connect_gourd(pos)
	for _, neighbor in pairs(neighbors) do
		local stem_pos = vector.add(pos, neighbor)
		mcl_farming.try_connect_stem(stem_pos)
	end
end

function mcl_farming.try_connect_stem(pos)
	local stem_defs = core.registered_nodes[core.get_node(pos).name]

	for _, neighbor in pairs(neighbors) do
		local block_pos = vector.add(pos, neighbor)
		local block = core.get_node(block_pos)
		local block_defs = core.registered_nodes[block.name]

		if block.name == stem_defs._mcl_farming_gourd_name then
			local linked_name = block_defs._mcl_farming_linked_stem

			core.set_node(pos, {name = get_connected_stem(linked_name, neighbor)})

			return true
		end
	end
end

function mcl_farming.add_gourd(unconnected_stem, connected_stem, gourd, interval, chance)
	core.register_abm({
		action = function(pos)
			local light = core.get_node_light(pos)
			local floor_block, floor_pos
			if light and light > 10 then
				for _, neighbor in pairs(neighbors) do
					floor_pos = vector.offset(neighbor, 0, -1, 0)
					floor_block = core.get_node(floor_pos)

					local soil_group = core.get_item_group(floor_block.name, "soil")

					if soil_group == 2 or soil_group == 3 then
						local param2 = 0
						local gourd_defs = core.registered_nodes[gourd]

						if gourd_defs.paramtype2 == "facedir" then
							if neighbor.x ~= 0 then
								param2 = neighbor.x + 2
							elseif neighbor.z ~= 0 then
								param2 = neighbor.z + 1
							end
						end

						core.set_node(pos, {name = get_connected_stem(connected_stem, neighbor)})
						core.add_node(neighbor, {name = gourd, param2 = param2})
					end

					if core.get_item_group(floor_block.name, "dirtifies_below_solid") > 0 then
						core.swap_node(floor_pos, {name = "mcl_core:dirt"})
					end
				end
			end
		end,
		chance = chance,
		interval = interval,
		label = "Grow gourd stem to gourd (" .. unconnected_stem .. " → " .. gourd .. ")",
		neighbors = {"air"},
		nodenames = {unconnected_stem}
	})
end
