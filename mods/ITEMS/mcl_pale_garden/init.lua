local modname = core.get_current_modname()
local S = core.get_translator(modname)
local schem_path = core.get_modpath(modname) .. "/schematics/"

mcl_trees.register_wood("pale_oak",{
    readable_name = "Pale Oak",
    sign_color = "#ECDDE3",
    tree_schems_2x2 = {
        {file = schem_path .. "mcl_pale_garden_pale_oak_1.mts", offset = vector.new(1, 0, 1)},
        {file = schem_path .. "mcl_pale_garden_pale_oak_2.mts"}
    },
    tree = {
        tiles = {
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak_top.png",
            "mcl_pale_garden_log_pale_oak.png"
        }
    },
    leaves = {palette = "", paramtype2 = "none"},
    stripped = {
        tiles = {
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_top.png",
            "mcl_pale_garden_stripped_pale_oak_side.png"
        }
    },
    wood = {tiles = {"mcl_pale_garden_planks_pale_oak.png"}},
    door = {
        inventory_image = "mcl_pale_garden_pale_oak_door.png",
        tiles_bottom = {
            "mcl_pale_garden_pale_oak_door_bottom.png^[transformFX",
            "mcl_pale_garden_pale_oak_door_bottom.png"
        },
        tiles_top = {
            "mcl_pale_garden_pale_oak_door_top.png^[transformFX",
            "mcl_pale_garden_pale_oak_door_top.png"
        }
    },
    trapdoor = {
		tile_front = "mcl_pale_garden_pale_oak_trapdoor.png",
		tile_side = "mcl_pale_garden_pale_oak_trapdoor.png",
		wield_image = "mcl_pale_garden_pale_oak_trapdoor.png"
	},
    fence = {tiles = {"mcl_pale_garden_planks_pale_oak.png"}},
    fence_gate = {tiles = {"mcl_pale_garden_planks_pale_oak.png"}}
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

core.register_node("mcl_pale_garden:resin_block", {
    _mcl_blast_resistance = 0,
    _mcl_crafting_output = {single = {output = "mcl_pale_garden:resin_clump 9"}},
    _mcl_hardness = 0,
    description = S("Block of Resin"),
    groups = {building_block = 1, dig_immediate = 3},
    sounds = mcl_sounds.node_sound_defaults(),
    tiles = {"mcl_pale_garden_resin_block.png"}
})

core.register_node("mcl_pale_garden:resin_clump", {
    _mcl_blast_resistance = 0,
    _mcl_cooking_output = "mcl_pale_garden:resin_brick",
    _mcl_crafting_output = {square3 = {output = "mcl_pale_garden:resin_block"}},
    _mcl_hardness = 0,
    description = S("Resin Clump"),
    drawtype = "signlike",
    groups = {craftitem = 1, dig_immediate = 3},
    inventory_image = "mcl_pale_garden_resin_clump_inv.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    selection_box = {fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, type = "fixed"},
    sounds = mcl_sounds.node_sound_defaults(),
    sunlight_propagates = true,
    tiles = {"mcl_pale_garden_resin_clump.png"},
    use_texture_alpha = "blend",
    walkable = false,
    wield_image = "mcl_pale_garden_resin_clump_inv.png"
})

core.register_node("mcl_pale_garden:resin_bricks", {
    _mcl_blast_resistance = 6,
    _mcl_hardness = 1.5,
    description = S("Resin Bricks"),
    groups = {building_block = 1, pickaxey = 1},
    sounds = mcl_sounds.node_sound_defaults(),
    tiles = {"mcl_pale_garden_resin_bricks.png"}
})

mcl_stairs.register_stair_and_slab("resin_bricks", {
    baseitem = "mcl_pale_garden:resin_bricks",
    description_slab = S("Resin Bricks Slab"),
    description_stair = S("Resin Bricks Stairs"),
    overrides = {_mcl_stonecutter_recipes = {"mcl_pale_garden:resin_bricks"}},
    recipeitem = "mcl_pale_garden:resin_bricks"
})

core.register_node("mcl_pale_garden:chiseled_resin_bricks", {
    _mcl_blast_resistance = 6,
    _mcl_hardness = 1.5,
    _mcl_stonecutter_recipes = {"mcl_pale_garden:resin_bricks"},
    description = S("Chiseled Resin Bricks"),
    groups = {building_block = 1, pickaxey = 1},
    sounds = mcl_sounds.node_sound_defaults(),
    tiles = {"mcl_pale_garden_chiseled_resin_bricks.png"}
})

core.register_craft({
    output = "mcl_pale_garden:chiseled_resin_bricks",
    recipe = {
        {"mcl_stairs:slab_resin_bricks"},
        {"mcl_stairs:slab_resin_bricks"}
    }
})

core.register_craftitem("mcl_pale_garden:resin_brick", {
    _mcl_crafting_output = {square2 = {output = "mcl_pale_garden:resin_bricks"}},
    description = S("Resin Brick"),
    groups = {craftitem = 1},
    inventory_image = "mcl_pale_garden_resin_brick.png",
    wield_image = "mcl_pale_garden_resin_brick.png"
})

local tpl_heart = {
	_mcl_blast_resistance = 10,
	_mcl_hardness = 10,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local tool = digger:get_wielded_item()

        if not tool then return end

        local silk_touch = mcl_enchanting.get_enchantment(tool, "silk_touch")
        local fortune = mcl_enchanting.get_enchantment(tool, "fortune")
        local creative = core.is_creative_enabled(digger:get_player_name())

        if silk_touch == 1 then
            -- Check for creaking heart variants
            if oldnode.name ~= "mcl_pale_garden:creaking_heart" then
                oldnode.name = "mcl_pale_garden:creaking_heart"
            end

            core.add_item(pos, oldnode.name)
        else
            if oldmetadata.fields["mcl_pale_garden:is_natural"] == "true" then
                local xp_amount = math.random(20, 24)

                if not creative then mcl_experience.throw_xp(pos, xp_amount) end
            end

            local clump_amount = math.random(1, 3)

            if fortune >= 1 then clump_amount = clump_amount * fortune end

            if not creative then
				core.add_item(pos, "mcl_pale_garden:resin_clump " .. clump_amount)
			end
        end

        tool:add_wear(mcl_autogroup.get_wear(tool:get_name(), "axey"))
        digger:set_wielded_item(tool)
    end,
	after_place_node = function(pos, placer)
        core.get_meta(pos):set_string("mcl_pale_garden:is_natural", "false")

        return core.is_creative_enabled(placer:get_player_name())
    end,
	drop = "",
	on_construct = function(pos)
        core.get_meta(pos):set_string("mcl_pale_garden:is_natural", "true")
    end,
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	paramtype2 = "facedir",
	sounds = mcl_sounds.node_sound_wood_defaults()
}

local ch_textures = {
	"mcl_pale_garden_creaking_heart_top.png",
	"mcl_pale_garden_creaking_heart_top.png",
	"mcl_pale_garden_creaking_heart.png"
}

local ach_textures = {
	"mcl_pale_garden_creaking_heart_top_active.png",
	"mcl_pale_garden_creaking_heart_top_active.png",
	"mcl_pale_garden_creaking_heart_active.png"
}

local function apply_overlay(textures, overlays, opacity)
	local texture
	local result = {}

	for i = 1, 3 do
		texture = textures[i] .. "^(" .. overlays[i] .. "^[opacity:" .. opacity .. ")"
		table.insert(result, texture)
	end

	return result
end

core.register_node("mcl_pale_garden:creaking_heart", table.merge(tpl_heart, {
    description = S("Creaking Heart"),
    groups = {axey = 1, creaking_heart = 1, unmovable_by_piston = 1},
    tiles = ch_textures
}))

core.register_node("mcl_pale_garden:creaking_heart_dormant", table.merge(tpl_heart, {
    groups = {
        axey = 1, creaking_heart = 2, not_in_creative_inventory = 1, unmovable_by_piston = 1
    },
    tiles = apply_overlay(ach_textures, ch_textures, 159)
}))

core.register_node("mcl_pale_garden:creaking_heart_active", table.merge(tpl_heart, {
    groups = {
       axey = 1, creaking_heart = 2, not_in_creative_inventory = 1, unmovable_by_piston = 1
    },
    tiles = ach_textures
}))

core.register_node("mcl_pale_garden:pale_hanging_moss", {
    _mcl_blast_resistance = 0,
    _mcl_hardness = 0,
    _mcl_silk_touch_drop = true,
    drawtype = "plantlike",
    drop = {
        items = {
            {items = {"mcl_pale_garden:pale_hanging_moss"}, tool_groups = {"shears"}}
        }
    },
    groups = {
        compostability = 30, deco_block = 1, dig_by_piston = 1, dig_immediate = 3,
        supported_node = 1
    },
    inventory_image = "mcl_pale_garden_pale_hanging_moss.png",
    paramtype = "light",
    sounds = mcl_sounds.node_sound_leaves_defaults(),
    sunlight_propagates = true,
    tiles = {"mcl_pale_garden_pale_hanging_moss.png"},
    walkable = false,
    wield_image = "mcl_pale_garden_pale_hanging_moss.png"
})
