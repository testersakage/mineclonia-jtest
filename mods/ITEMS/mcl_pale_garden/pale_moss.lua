local S = core.get_translator(core.get_current_modname())

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

local pale_moss_carpet_desc = S("Pale Moss Carpet")
local pale_moss_box = {fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, type = "fixed"}

local function register_pale_moss_carpet(name, defs)
    core.register_node("mcl_pale_garden:" .. name, {
        _mcl_blast_resistance = 0.1,
        _mcl_hardness = 0.1,
		collision_box = pale_moss_box,
        drawtype = defs.mesh and "mesh" or "nodebox",
        drop = "mcl_pale_garden:pale_moss_carpet",
        groups = {
            carpet = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1, handy = 1,
            hoey = 1, not_in_creative_inventory = 1, supported_node = 1
        },
        is_ground_content = false,
		mesh = defs.mesh or nil,
        node_box = not defs.mesh and pale_moss_box or nil,
        paramtype = "light",
        paramtype2 = "4dir",
		selection_box = pale_moss_box,
        sounds = mcl_sounds.node_sound_leaves_defaults(),
        sunlight_propagates = true,
        tiles = {defs.image},
        use_texture_alpha = "blend",
		wield_image = defs.image,
		wield_scale = {x = 1, y = 1, z = 0.5}
	})
end

register_pale_moss_carpet("pale_moss_carpet_side", {
	image = "pale_vine_side_1.png",
	mesh = "pale_vine_side_1.obj"
})

register_pale_moss_carpet("pale_moss_carpet_side_up", {
    image = "pale_vine_side_2.png",
    mesh = "pale_vine_side_2.obj"
})

register_pale_moss_carpet("pale_moss_carpet_side_medium", {
    image = "pale_vine_d_side_1.png",
    mesh = "pale_vine_d_side_1.obj"
})

register_pale_moss_carpet("pale_moss_carpet_side_tall", {
    image = "pale_vine_d_side_2.png",
    mesh = "pale_vine_d_side_2.obj"
})

local function get_group(name, group)
    return core.get_item_group(name, group) > 0
end

local function is_solid(name)
    return name ~= "air" and not get_group(name, "moss") and get_group(name, "solid")
end

local function get_variant(base_name, variant)
    return "mcl_pale_garden:pale_moss_carpet_" .. (math.random(2) == 2 and variant or base_name)
end

local neighbors = {
    left = vector.new(-1, 0, 0),
    right = vector.new(1, 0, 0),
    back = vector.new(0, 0, -1),
    front = vector.new(0, 0, 1)
}

local vecs = {
    left = {x = 1, z = 0},
    right = {x = -1, z = 0},
    back = {x = 1, z = 0},
    front = {x = -1, z = 0}
}

core.register_node("mcl_pale_garden:pale_moss_carpet", {
    _mcl_blast_resistance = 0.1,
    _mcl_hardness = 0.1,
    description = pale_moss_carpet_desc,
	drawtype = "nodebox",
    groups = {
        carpet = 1, compostability = 30, deco_block = 1, destroy_by_lava_flow = 1,
        dig_by_piston = 1, dig_by_water = 1, handy = 1, hoey = 1, supported_node = 1
    },
    is_ground_content = false,
    node_box = pale_moss_box,
    on_construct = function(pos)
        local solids = {}

        for dir, offset in pairs(neighbors) do
            solids[dir] = is_solid(core.get_node(vector.add(pos, offset)).name)
        end

        local facing_direction, air_above

        for dir, vec in pairs(vecs) do
            if solids[dir] then
                local above_pos = vector.add(pos, {x = 0, y = 1, z = 0})

                facing_direction = table.copy(vec)
                air_above = core.get_node(above_pos).name == "air"

                break
            end
        end

        if facing_direction then
            local variant = air_above and get_variant("side", "side_up")

            core.set_node(pos, {name = variant, param2 = core.dir_to_facedir(facing_direction)})
        end

        if (solids.right or solids.left) and (solids.back or solids.front) then
            local corner_facing
            local corner_directions = {
                {"right", "front", {x = 1, z = -1}}, {"right", "back", {x = 1, z = 1}},
                {"left", "front", {x = -1, z =  -1}}, {"left", "back", {x = -1, z = 1}}
            }

            for _, data in pairs(corner_directions) do
                local d1, d2, vec = unpack(data)

                if solids[d1] and solids[d2] then
                    corner_facing = core.dir_to_facedir(vec)

                    break
                end
            end

            if corner_facing then
                local variant = get_variant("side_tall", "side_medium")

                core.set_node(pos, {name = variant, param2 = corner_facing})
            end
        end
    end,
    paramtype = "light",
    sounds = mcl_sounds.node_sound_dirt_defaults(),
    sunlight_propagates = true,
    tiles = {"mcl_pale_garden_pale_moss_block.png"},
	wield_image = "mcl_pale_garden_pale_moss_block.png",
	wield_scale = {x = 1, y = 1, z = 0.5}
})

local tpl_hanging = {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    drawtype = "plantlike",
    drop = {
        items = {
            {items = {"mcl_pale_garden:pale_hanging_moss_tip"}, tool_groups = {"shears"}}
        }
    },
    groups = {
        destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1, dig_immediate = 3,
        plant = 1, vinelike_node = 2
    },
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    walkable = false
}

core.register_node("mcl_pale_garden:pale_hanging_moss", table.merge(tpl_hanging, {
    _mcl_silk_touch_drop = true,
    description = S("Pale Hanging Moss"),
    groups = table.merge(tpl_hanging.groups, {deco_block = 1}),
    inventory_image = "mcl_pale_garden_pale_hanging_moss_tip.png",
    on_destruct = function(pos)
        local a_node = core.get_node(vector.offset(pos, 0, 1, 0))

        if a_node and a_node.name == "mcl_pale_garden:pale_hanging_moss" then
            core.swap_node(pos, {name = "mcl_pale_garden:pale_hanging_moss_tip"})
        end
    end,
    tiles = {"mcl_pale_garden_pale_hanging_moss.png"},
    wield_image = "mcl_pale_garden_pale_hanging_moss_tip.png"
}))

core.register_node("mcl_pale_garden:pale_hanging_moss_tip", table.merge(tpl_hanging, {
    _mcl_silk_touch_drop = "mcl_pale_garden:pale_hanging_moss",
    _on_bone_meal = function(_, _, _, pos)
		local pos_below = vector.offset(pos, 0, -1, 0)

        core.swap_node(pos, {name = "mcl_pale_garden:pale_hanging_moss"})
		core.place_node(pos_below, {name = "mcl_pale_garden:pale_hanging_moss_tip"})

		return true
	end,
    description = S("Pale Hanging Moss Tip"),
    groups = table.merge(tpl_hanging.groups, {not_in_creative_inventory = 1}),
    on_construct = function(pos)
        local a_node = core.get_node(vector.offset(pos, 0, 1, 0))

        if a_node and a_node.name == "mcl_pale_garden:pale_hanging_moss_tip" then
            core.swap_node(pos, {name = "mcl_pale_garden:pale_hanging_moss"})
        end
    end,
    on_destruct = function(pos)
        local a_node = core.get_node(vector.offset(pos, 0, 1, 0))

        if a_node and a_node.name == "mcl_pale_garden:pale_hanging_moss" then
            core.swap_node(pos, {name = "mcl_pale_garden:pale_hanging_moss_tip"})
        end
    end,
    tiles = {"mcl_pale_garden_pale_hanging_moss_tip.png"},
}))
