local S = minetest.get_translator(minetest.get_current_modname())

local dripstone_directions =
{
	[-1] = "bottom",
	[1] = "top",
}

local dripstone_stages =
{
	"tip_merge",
	"tip",
	"frustum",
	"middle",
	"base",
}

local function get_dripstone_node(stage, direction)
	return "mclx_dripstone:dripstone_" .. dripstone_directions[direction] .. "_" .. dripstone_stages[stage]
end

local function extract_direction(name)
	return string.sub(name, 26, 31) == "bottom" and -1 or 1
end

-- it is assumed pos is at the tip of the dripstone
local function get_dripstone_length(pos, direction)
	local offset_pos = vector.copy(pos)
	local stage
	local length = 1
	while true do
		offset_pos = vector.offset(offset_pos, 0, direction, 0)
		stage = minetest.get_item_group(minetest.get_node(offset_pos).name, "dripstone_stage")
		if stage == 0 then
			return length
		end
		length = length + 1
	end
end

minetest.register_node("mclx_dripstone:dripstone_block", {
	description = S("Dripstone block"),
	_doc_items_longdesc = S("Dripstone is type of stone that allows stalagmites and stalagtites to grow on it"),
	_doc_items_hidden = false,
	tiles = {"dripstone_block.png"},
	groups = {pickaxey=1, stone=1, building_block=1, material_stone=1, stonecuttable = 1, converts_to_moss = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

local function dripstone_hit_func(self, object)
	mcl_util.deal_damage(object, math.ceil(self.timer / 0.2 - 2), {type = "falling_node"})
end

mcl_mobs.register_arrow("mclx_dripstone:vengeful_dripstone",
{
	visual = "upright_sprite",
	textures = {"pointed_dripstone_tip.png"},
	visual_size = {x = 1, y = 1},
	velocity = 20,
	hit_player = dripstone_hit_func,
	hit_mob = dripstone_hit_func,
	hit_object = dripstone_hit_func,
	hit_node = function(_, pos)
		minetest.add_item(pos, ItemStack("mclx_dripstone:pointed_dripstone"))
	end,
	drop = "mclx_dripstone:pointed_dripstone",
})

local function update_dripstone(pos, direction)
	-- if a dripstone column should be created
	-- ".[^l]" is in the pattern to prevent dripstone blocks from being matched
	if string.find(minetest.get_node(vector.offset(pos, 0, -direction, 0)).name, "^mclx_dripstone:dripstone_.[^l]") then
		minetest.swap_node(pos, {name = "mclx_dripstone:dripstone_" .. dripstone_directions[direction] .. "_tip_merge"})
		minetest.swap_node(vector.offset(pos, 0, -direction, 0), {name = "mclx_dripstone:dripstone_" .. dripstone_directions[-direction] .. "_tip_merge"})
	end

	local stage
	local previous_stage
	while true do
		pos = vector.offset(pos, 0, direction, 0)
		previous_stage = stage
		stage = minetest.get_item_group(minetest.get_node(pos).name, "dripstone_stage")
		if stage == 4 or stage == 5 then
			break
		elseif stage == 0 then
			if previous_stage == 3 then
				minetest.swap_node(vector.offset(pos, 0, -direction, 0), {name = "mclx_dripstone:dripstone_" .. dripstone_directions[direction] .. "_base"})
			end
			break
		end
		minetest.swap_node(pos, {name = get_dripstone_node(stage + 1, direction)})
	end
end

local function on_dripstone_place(itemstack, player, pointed_thing)
	if pointed_thing.type ~= "node" then return itemstack end
	if pointed_thing.above.x ~= pointed_thing.under.x or pointed_thing.above.z ~= pointed_thing.under.z then return itemstack end

	local direction = pointed_thing.under.y - pointed_thing.above.y
	local direction_string = dripstone_directions[direction]
	if not direction_string then return end

	if not minetest.is_creative_enabled(player:get_player_name()) then
		itemstack:take_item()
	end
	minetest.set_node(pointed_thing.above, {name = "mclx_dripstone:dripstone_" .. direction_string .. "_tip"})
	update_dripstone(pointed_thing.above, direction)
	return itemstack
end

local on_dripstone_destruct = function(pos)
	local direction = extract_direction(minetest.get_node(pos).name)
	local offset_pos = vector.copy(pos)
	local stage
	while true do
		offset_pos = vector.offset(offset_pos, 0, -direction, 0)
		stage = minetest.get_item_group(minetest.get_node(offset_pos).name, "dripstone_stage")
		if stage == 1 and extract_direction(minetest.get_node(offset_pos).name) == -direction then
			minetest.swap_node(offset_pos, {name = get_dripstone_node(2, -direction)})
			break
		elseif stage == 0 then
			break
		else
			if direction == -1 then
				minetest.add_item(offset_pos, ItemStack("mclx_dripstone:pointed_dripstone"))
			else
				local vengeful_dripstone = minetest.add_entity(offset_pos, "mclx_dripstone:vengeful_dripstone")
				vengeful_dripstone:add_velocity(vector.new(0, -12, 0))
				local ent = vengeful_dripstone:get_luaentity()
				ent.switch = 1
			end
			minetest.swap_node(offset_pos, {name = "air"})
		end
	end

	offset_pos = vector.copy(vector.offset(pos, 0, direction, 0))
	if minetest.get_item_group(minetest.get_node(offset_pos).name, "dripstone_stage") ~= 0 then
		minetest.swap_node(offset_pos, {name = get_dripstone_node(2, direction)})

		while true do
			offset_pos = vector.offset(offset_pos, 0, direction, 0)
			stage = minetest.get_item_group(minetest.get_node(offset_pos).name, "dripstone_stage")
			if stage == 3 then
				minetest.swap_node(offset_pos, {name = get_dripstone_node(2, direction)})
			elseif stage == 4 or stage == 5 then
				minetest.swap_node(offset_pos, {name = get_dripstone_node(3, direction)})
				break
			else
				break
			end
		end
	end
end

minetest.register_craftitem("mclx_dripstone:pointed_dripstone", {
	description = S("Pointed dripstone"),
	_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
	_doc_items_hidden = false,
	inventory_image = "pointed_dripstone_tip.png",
	on_place = on_dripstone_place,
	on_secondary_use = on_dripstone_place,
})

for i = 1, #dripstone_stages do
	local stage = dripstone_stages[i]
	minetest.register_node("mclx_dripstone:dripstone_top_" .. stage, {
		description = S("Pointed dripstone (@1/@2)", i, #dripstone_stages),
		_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
		_doc_items_hidden = true,
		drawtype = "plantlike",
		tiles = {"pointed_dripstone_" .. stage .. ".png"},
		drop = "mclx_dripstone:pointed_dripstone",
		groups = {pickaxey=1, not_in_creative_inventory=1, dripstone_stage = i},
		sunlight_propagates = true,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_destruct = on_dripstone_destruct,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 1.5,
	})

	minetest.register_node("mclx_dripstone:dripstone_bottom_" .. stage, {
		description = S("Pointed dripstone (@1/@2)", i, #dripstone_stages),
		_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
		_doc_items_hidden = true,
		drawtype = "plantlike",
		tiles = {"pointed_dripstone_" .. stage .. ".png^[transform6"},
		drop = "mclx_dripstone:pointed_dripstone",
		groups = {pickaxey=1, not_in_creative_inventory=1, fall_damage_add_percent = 100, dripstone_stage = i},
		sunlight_propagates = true,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_destruct = on_dripstone_destruct,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 1.5,
	})
end

minetest.register_abm({
	label = "Dripstone growth",
	nodenames = {"mclx_dripstone:dripstone_top_tip"},
	interval = 1,
	chance = 1,
	action = function(pos)
		-- checking if can grow
		local stalagtite_lenth = get_dripstone_length(pos, 1)
		if minetest.get_node(vector.offset(pos, 0, stalagtite_lenth, 0)).name ~= "mclx_dripstone:dripstone_block"
		or minetest.get_item_group(minetest.get_node(vector.offset(pos, 0, stalagtite_lenth + 1, 0)).name, "water") == 0 then
			return
		end

		-- randomly chose to either grow the stalagmite or stalagtites
		if math.random(2) == 1 then
			-- stalagmite growth
			local groups
			local node
			local length
			for i = 1, 10 do
				node = minetest.get_node(vector.offset(pos, 0, -i, 0))
				groups = minetest.registered_nodes[node.name].groups
				if (groups["solid"] or 0) > 0 or (groups["dripstone_stage"] or 0) > 0 then
					length = get_dripstone_length(pos, 1)

					if length < 7 then
						minetest.set_node(vector.offset(pos, 0, -i + 1, 0), {name = get_dripstone_node(2, -1)})
						update_dripstone(vector.offset(pos, 0, -i + 1, 0), -1)
					end
					return
				elseif node.name ~= "air" then
					return
				end
			end
		else
			-- stalagtite growth
			if stalagtite_lenth > 7 then return end

			if minetest.get_node(vector.offset(pos, 0, -1, 0)).name == "air" then
				minetest.set_node(vector.offset(pos, 0, -1, 0), {name = get_dripstone_node(2, 1)})
				update_dripstone(vector.offset(pos, 0, -1, 0), 1)
			end
		end
	end,
})

-- Cauldron fill up rules:
-- Adding any water increases the water level by 1, preserving the current water type
local cauldron_levels = {
	["mcl_core:water_source"] = {"", "_1", "_2", "_3"},
	["mclx_core:river_water_source"] = {"", "_1r", "_2r", "_3r"},
}
local fill_cauldron = function(cauldron, water_type)
	local base = "mcl_cauldrons:cauldron"
	for index = 1, #cauldron_levels[water_type] do
		if cauldron == (base .. cauldron_levels[water_type][index]) and index ~= #cauldron_levels[water_type] then
			return base .. cauldron_levels[water_type][index + 1]
		end
	end
end

minetest.register_abm({
	label = "Dripstone filling water cauldrons, conversion from mud to clay",
	nodenames = {"mclx_dripstone:dripstone_top_tip"},
	interval = 1,
	chance = 5.5,
	action = function(pos)
		local stalagtite_length = get_dripstone_length(pos, 1)

		if minetest.get_item_group(minetest.get_node(vector.offset(pos, 0, stalagtite_length + 1, 0)).name, "water") == 0
		or stalagtite_length > 10 then
			-- reusing the ABM for converting mud to clay, since the chances are the same
			if minetest.get_node(vector.offset(pos, 0, stalagtite_length + 1, 0)).name == "mcl_mud:mud"
			and mcl_worlds.pos_to_dimension(vector.offset(pos, 0, stalagtite_length + 1, 0)) ~= "nether" then
				minetest.set_node(vector.offset(pos, 0, stalagtite_length + 1, 0), {name = "mcl_core:clay"})
			end
			return
		end

		local node
		local new_cauldron
		for i = 1, 10 do
			node = minetest.get_node(vector.offset(pos, 0, -i, 0))
			if minetest.get_item_group(node.name, "cauldron") ~= 0 and not string.find(node.name, "lava$") then
				new_cauldron = fill_cauldron(node.name, "mcl_core:water_source")
				if new_cauldron then
					minetest.set_node(vector.offset(pos, 0, -i, 0), {name = new_cauldron})
				end
				return
			elseif node.name ~= "air" then
				return
			end
		end
	end,
})

minetest.register_abm({
	label = "Dripstone filling lava cauldrons",
	nodenames = {"mclx_dripstone:dripstone_top_tip"},
	interval = 1,
	chance = 17,
	action = function(pos)
		local stalagtite_length = get_dripstone_length(pos, 1)

		if minetest.get_item_group(minetest.get_node(vector.offset(pos, 0, stalagtite_length + 1, 0)).name, "lava") == 0
		or stalagtite_length > 10 then
			return
		end

		local node
		for i = 1, 10 do
			node = minetest.get_node(vector.offset(pos, 0, -i, 0))
			if node.name == "mcl_cauldrons:cauldron" then
				minetest.set_node(vector.offset(pos, 0, -i, 0), {name = "mcl_cauldrons:cauldron_3_lava"})
			elseif node.name ~= "air" then
				return
			end
		end
	end,
})
