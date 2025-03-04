local S = core.get_translator(core.get_current_modname())

mcl_trees.register_wood("pale_oak",{
    readable_name = "Pale Oak",
    sign_color = "#ECDDE3",
    tree = {
        tiles = {
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak.png"
        }
    },
    stripped = {
        tiles = {
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_side.png"
        }
    },
    wood = {tiles = {"mcl_pale_garden_planks_pale_oak.png"}}
})

mcl_flowers.register_simple_flower("closed_eyeblossom", {
    desc = S("Closed Eyeblossom"),
    image = "mcl_pale_garden_closed_eyeblossom.png",
    selection_box = {-0.25, -0.5, -0.25, 0.25, 0.25, 0.25},
    potted = true,
    _mcl_crafting_output = {single = {output = "mcl_dyes:grey"}}
})

mcl_flowers.register_simple_flower("open_eyeblossom", {
    desc = S("Open Eyeblossom"),
    image = "mcl_pale_garden_open_eyeblossom.png",
    selection_box = {-0.25, -0.5, -0.25, 0.25, 0.25, 0.25},
    potted = true,
    _mcl_crafting_output = {single = {output = "mcl_dyes:orange"}}
})

local function random_moss_vegetation()
	local x = math.random()
	if x < 0.5882 then
		return "mcl_flowers:tallgrass"
	elseif x < 0.8823 then
		return "mcl_pale_garden:pale_moss_carpet"
	else
		return "mcl_flowers:double_grass"
	end
end

local function set_moss_with_chance_vegetation(pos)
	core.set_node(pos, { name = "mcl_pale_garden:pale_moss_block" })
	if math.random() < 0.6 then
		local vegetation = random_moss_vegetation()
		local pos_up = vector.offset(pos, 0, 1, 0)
		if vegetation == "mcl_flowers:double_grass" then
			local pos_up2 = vector.offset(pos, 0, 2, 0)
			if core.registered_nodes[core.get_node(pos_up2).name].buildable_to then
				core.set_node(pos_up, { name = "mcl_flowers:double_grass" })
				core.set_node(pos_up2, { name = "mcl_flowers:double_grass_top" })
			else
				core.set_node(pos_up, { name = "mcl_flowers:tallgrass" })
			end
		else
			core.set_node(pos_up, { name = vegetation })
		end
	end
end

local function bone_meal_moss(_, _, _, pos)
    if core.get_node(vector.offset(pos, 0, 1, 0)).name ~= "air" then return end

    local x_max = math.random(2, 3)
    local z_max = math.random(2, 3)
    local area_positions = core.find_nodes_in_area_under_air(
		vector.offset(pos, -x_max, -6, -z_max),
		vector.offset(pos, x_max, 4, z_max),
		{ "group:converts_to_moss" }
	)

	for _, conversion_pos in pairs(area_positions) do
		local x_distance = math.abs(pos.x - conversion_pos.x)
		local z_distance = math.abs(pos.z - conversion_pos.z)

		if not ( x_distance == x_max and z_distance == z_max ) then
			if x_distance == x_max or z_distance == z_max then
				if math.random() < 0.75 then
					set_moss_with_chance_vegetation(conversion_pos)
				end
			else
				set_moss_with_chance_vegetation(conversion_pos)
			end
		end
	end
	return true
end

core.register_node("mcl_pale_garden:pale_moss_block", {
    _mcl_blast_resistance = 0.1,
    _mcl_crafting_output = {line_wide2 = {output = "mcl_pale_garden:pale_moss_carpet 3"}},
    _mcl_hardness = 0.1,
    _on_bone_meal = bone_meal_moss,
    description = S("Pale Moss Block"),
    groups = {
        building_block = 1, compostability = 65, converts_to_moss = 1, dig_by_piston = 1,
        handy = 1, hoey = 1, soil = 1, soil_bamboo = 1, soil_sapling = 1, soil_sugarcane = 1,
        unsticky = 1
    },
    sounds = mcl_sounds.node_sound_dirt_defaults(),
    tiles = {"mcl_pale_garden_pale_moss_block.png"}
})

core.register_node("mcl_pale_garden:pale_moss_carpet", {
    _mcl_blast_resistance = 0.1,
    _mcl_hardness = 0.1,
    description = S("Pale Moss Carpet"),
	drawtype = "nodebox",
    groups = {
        carpet = 1, compostability = 30, deco_block = 1, dig_by_piston = 1, dig_by_water = 1,
        handy = 1, supported_node = 1
    },
    is_ground_content = false,
    node_box = {
		fixed = {{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}},
        type = "fixed"
	},
    paramtype = "light",
    sounds = mcl_sounds.node_sound_dirt_defaults(),
    sunlight_propagates = true,
    tiles = {"mcl_pale_garden_pale_moss_block.png"},
	wield_image = "mcl_pale_garden_pale_moss_block.png",
	wield_scale = {x = 1, y = 1, z = 0.5}
})
