local S = core.get_translator("mcl_lightning_rods")
local D = mcl_util.get_dynamic_translator()

local cbox = {
	type = "fixed",
	fixed = {
		{ -0.0625, -0.5, -0.0625, 0.0625, 0.25, 0.0625 },
		{ -0.125, 0.25, -0.125, 0.125, 0.5, 0.125 },
	},
}

local rod_def = {
	description = S("Lightning Rod"),
	_doc_items_longdesc = S("A block that attracts lightning"),
	tiles = { "mcl_lightning_rods_rod.png" },
	drawtype = "mesh",
	mesh = "mcl_lightning_rods_rod.obj",
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { pickaxey = 2, attracts_lightning = 1 },
	sounds = mcl_sounds.node_sound_metal_defaults(),
	selection_box = cbox,
	collision_box = cbox,
	node_placement_prediction = "",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" or not placer or not placer:is_player() then
			return itemstack
		end

		local p0 = pointed_thing.under
		local p1 = pointed_thing.above
		local param2 = 0

		local placer_pos = placer:get_pos()
		if placer_pos then
			param2 = core.dir_to_facedir(vector.subtract(p1, placer_pos))
		end

		if p0.y - 1 == p1.y then
			param2 = 20
		elseif p0.x - 1 == p1.x then
			param2 = 16
		elseif p0.x + 1 == p1.x then
			param2 = 12
		elseif p0.z - 1 == p1.z then
			param2 = 8
		elseif p0.z + 1 == p1.z then
			param2 = 4
		end

		return core.item_place(itemstack, placer, pointed_thing, param2)
	end,

	_mcl_blast_resistance = 6,
	_mcl_hardness = 3,
}

core.register_node("mcl_lightning_rods:rod", rod_def)

local rod_def_powered = table.copy(rod_def)

rod_def_powered.groups.not_in_creative_inventory = 1

core.register_node("mcl_lightning_rods:rod_powered", rod_def_powered)

mcl_lightning.register_on_strike(function(pos, pos2, objects, for_trap)
	if for_trap then
		return false
	end
	local lr = core.find_nodes_in_area_under_air(vector.offset(pos, -64, -32, -64), vector.offset(pos, 64, 64, 64), { "group:attracts_lightning" }, true)
	lr = (lr and #lr > 0 and lr[1]) or false
	if lr then
		local node = core.get_node(lr)

		if node.name == "mcl_lightning_rods:rod" then
			node.name = "mcl_lightning_rods:rod_powered"
			core.set_node(lr, node)
			core.get_node_timer(lr):start(0.4)
		end
	end

	return lr, nil
end)

-- Exposed Lightning Rod
rod_def_exposed = table.copy(rod_def)
rod_def_exposed.description = D("Exposed Lightning Rod")
rod_def_exposed.tiles = { "mcl_lightning_rods_rod_exposed.png" }
core.register_node("mcl_lightning_rods:rod_exposed", rod_def_exposed)

rod_def_exposed_powered = table.copy(rod_def_exposed)
rod_def_exposed_powered.tiles = { "mcl_lightning_rods_rod_exposed.png^[brighten" }
rod_def_exposed_powered.groups.not_in_creative_inventory = 1
rod_def_exposed_powered._mcl_redstone = {
	get_power = function(node, dir)
		return 15
	end,
}
rod_def_exposed_powered.on_timer = function(pos)
	local node = core.get_node(pos)

	if node.name == "mcl_lightning_rods:rod_exposed_powered" then --has not been dug
		node.name = "mcl_lightning_rods:rod_exposed"
		core.set_node(pos, node)
	end

	return false
end
core.register_node("mcl_lightning_rods:rod_exposed_powered", rod_def_exposed_powered)

-- Weathered Lightning Rod
rod_def_weathered = table.copy(rod_def)
rod_def_weathered.description = D("Weathered Lightning Rod")
rod_def_weathered.tiles = { "mcl_lightning_rods_rod_weathered.png" }
core.register_node("mcl_lightning_rods:rod_weathered", rod_def_weathered)

rod_def_weathered_powered = table.copy(rod_def_exposed)
rod_def_weathered_powered.tiles = { "mcl_lightning_rods_rod_weathered.png^[brighten" }
rod_def_weathered_powered.groups.not_in_creative_inventory = 1
rod_def_weathered_powered._mcl_redstone = {
	get_power = function(node, dir)
		return 15
	end,
}
rod_def_weathered_powered.on_timer = function(pos)
	local node = core.get_node(pos)

	if node.name == "mcl_lightning_rods:rod_weathered_powered" then --has not been dug
		node.name = "mcl_lightning_rods:rod_weathered"
		core.set_node(pos, node)
	end

	return false
end
core.register_node("mcl_lightning_rods:rod_weathered_powered", rod_def_weathered_powered)

-- Oxidized Lightning Rod
rod_def_oxidized = table.copy(rod_def)
rod_def_oxidized.description = D("Oxidized Lightning Rod")
rod_def_oxidized.tiles = { "mcl_lightning_rods_rod_oxidized.png" }
core.register_node("mcl_lightning_rods:rod_oxidized", rod_def_oxidized)

rod_def_oxidized_powered = table.copy(rod_def_oxidized)
rod_def_oxidized_powered.tiles = { "mcl_lightning_rods_rod_oxidized.png^[brighten" }
rod_def_oxidized_powered.groups.not_in_creative_inventory = 1
rod_def_oxidized_powered._mcl_redstone = {
	get_power = function(node, dir)
		return 15
	end,
}
rod_def_oxidized_powered.on_timer = function(pos)
	local node = core.get_node(pos)

	if node.name == "mcl_lightning_rods:rod_oxidized_powered" then --has not been dug
		node.name = "mcl_lightning_rods:rod_oxidized"
		core.set_node(pos, node)
	end

	return false
end
core.register_node("mcl_lightning_rods:rod_oxidized_powered", rod_def_oxidized_powered)

mcl_copper.register_decaychain("lightning_rod",{
        preserve_group = "preserves_copper",
        unpreserve_callback = "_on_axe_place",
        undecay_callback = "_on_axe_place",
        nodes = { --order is significant
                "mcl_lightning_rods:rod",
                "mcl_lightning_rods:rod_exposed",
                "mcl_lightning_rods:rod_weathered",
                "mcl_lightning_rods:rod_oxidized",
        },
})
