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
	if string.find(minetest.get_node(vector.offset(pos, 0, -direction, 0)).name, "^mclx_dripstone:dripstone_") then
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
		local offset_pos = vector.copy(pos)
		local stage
		local node
		local stalagtite_lenth = 1
		while true do
			offset_pos = vector.offset(offset_pos, 0, 1, 0)
			stalagtite_lenth = stalagtite_lenth + 1
			node = minetest.get_node(offset_pos)
			stage = minetest.get_item_group(node.name, "dripstone_stage")
			if stage == 0 then
				if node.name ~= "mclx_dripstone:dripstone_block" 
				or minetest.get_item_group(minetest.get_node(vector.offset(offset_pos, 0, 1, 0)).name, "water") == 0 then 
					return 
				end
				break
			end
		end

		-- randomly chose to either grow the stalagmite or stalagtites
		if math.random(2) == 1 then
			-- stalagmite growth
			local groups
			local length = 0
			for i = 1, 10 do
				node = minetest.get_node(vector.offset(pos, 0, -i, 0))
				groups = minetest.registered_nodes[node.name].groups
				if (groups["solid"] or 0) > 0 or (groups["dripstone_stage"] or 0) > 0 then
					if (groups["dripstone_stage"] or 0) > 0 then
						while true do
							stage = minetest.get_item_group(minetest.get_node(vector.offset(pos, 0, -i - length, 0)).name, "dripstone_stage")
							if stage == 0 then
								break
							end
							length = length + 1
						end
					end

					if length < 7 then
						minetest.set_node(vector.offset(pos, 0, -i + 1, 0), {name = get_dripstone_node(2, -1)})
						update_dripstone(vector.offset(pos, 0, -i + 1, 0), -1)
					end
					break
				end
			end
		else
			-- stalagtite growth
			if stalagtite_lenth > 7 then return end

			minetest.set_node(vector.offset(pos, 0, -1, 0), {name = get_dripstone_node(2, 1)})
			update_dripstone(vector.offset(pos, 0, -1, 0), 1)
		end
	end,
})
