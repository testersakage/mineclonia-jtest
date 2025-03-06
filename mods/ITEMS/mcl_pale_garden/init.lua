local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)
local schempath = modpath .. "/schematics/"

--dofile(modpath .. "/biome.lua")
--dofile(schempath.."/mob.lua")
dofile(modpath .. "/pale_moss.lua")
dofile(modpath .. "/resin.lua")

mcl_trees.register_wood("pale_oak", {
	readable_name = "Pale Oak",
	sign_color = "#ECDDE3",
	tree_schems_2x2 = {
		{file = schempath .. "mcl_pale_garden_pale_oak_tree_1.mts", offset = vector.new(1, 0, 1)},
		{file = schempath .. "mcl_pale_garden_pale_oak_tree_2.mts"}
	},
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
	description = ("Creaking Heart"),
	groups = {axey = 1, creaking_heart = 1, deco_block = 1, unmovable_by_piston = 1},
	tiles = ch_textures
}))

core.register_node("mcl_pale_garden:creaking_heart_dormant", {
	groups = {
		axey = 1, creaking_heart = 2, not_in_creative_inventory = 1, unmovable_by_piston = 1
	},
	tiles = apply_overlay(ach_textures, ch_textures, 159)
})

core.register_node("mcl_pale_garden:creaking_heart_active", {
	groups = {
		axey = 1, creaking_heart = 3, not_in_creative_inventory = 1, unmovable_by_piston = 1
	},
	tiles = ach_textures
})

mcl_flowers.register_simple_flower("closed_eyeblossom", {
    _mcl_crafting_output = {single = {output = "mcl_dyes:grey"}},
    desc = S("Closed Eyeblossom"),
    image = "mcl_pale_garden_closed_eyeblossom.png",
    potted = true,
    selection_box = {-0.25, -0.5, -0.25, 0.25, 0.3125, 0.25}
})

--[[
minetest.register_node("vlf_pale_garden:open_eyeblossom", {
	description = ("Open Eyeblossom"),
	drawtype = "plantlike",
	waving = 1,
	tiles = { "eyeblossom_stem.png^open_eyeblossom.png" },
	inventory_image = "eyeblossom_stem.png^open_eyeblossom.png^open_eyeblossom_emissive.png",
	wield_image = "eyeblossom_stem.png^open_eyeblossom.png^open_eyeblossom_emissive.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = {
		attached_node = 1, deco_block = 1, dig_by_piston = 1, dig_immediate = 3,
		dig_by_water = 1, destroy_by_lava_flow = 1, enderman_takable = 1,
		plant = 1, flower = 1, place_flowerlike = 1, non_mycelium_plant = 1,
		flammable = 2, fire_encouragement = 60, fire_flammability = 100,
		compostability = 65, unsticky = 1
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	node_placement_prediction = "",
	on_place = mcl_flowers.on_place_flower,
	selection_box = {
		type = "fixed",
		fixed = { -5/16, -0.5, -5/16, 5/16, 5/16, 5/16 },
	},
	--_mcl_silk_touch_drop = ,
	_on_bone_meal = mcl_flowers.on_bone_meal_simple,
	on_construct = function(pos)
		minetest.add_entity(pos, "vlf_pale_garden:eyeblossom_emissive")
        end,
})
mcl_flowerpots.register_potted_flower("vlf_pale_garden:open_eyeblossom", {
	name = "open_eyeblossom",
	desc = ("Open Eyeblossom"),
	image = "(eyeblossom_stem.png^open_eyeblossom.png)",
	on_construct = function(pos)
		minetest.add_entity(pos, "vlf_pale_garden:eyeblossom_pot_emissive")
        end,
})

-- Register an ABM to check for eyeblossom entities
minetest.register_abm({
    label = "Add missing eyeblossom entities to flowerpots",
    nodenames = {"mcl_flowerpots:flower_pot_open_eyeblossom"},
    interval = 2, -- Frequency of the check (in seconds)
    chance = 1, -- Apply the ABM to all matching nodes

    action = function(pos, node)
        -- Check for existing eyeblossom entities at this position
        local objects = minetest.get_objects_inside_radius(pos, 0.5)
        local entity_present = false

        for _, obj in ipairs(objects) do
            if obj:get_luaentity() and obj:get_luaentity().name == "vlf_pale_garden:eyeblossom_pot_emissive" then
                entity_present = true
                break
            end
        end
	local f_pos = {x=pos.x, y=pos.y+0.23, z=pos.z}
        -- If the entity is not present, add it
        if not entity_present then
            minetest.add_entity(f_pos, "vlf_pale_garden:eyeblossom_pot_emissive")
        end
    end,
})

-- Register the glowing add-on entity
    minetest.register_entity("vlf_pale_garden:eyeblossom_emissive", {
    initial_properties = {
		pointable = false,
		visual = "mesh",
		mesh = "plantlike.obj",
		visual_size = {x = 10, y = 10},
		textures = {"open_eyeblossom_emissive.png"},
		glow = 15,
	},
        on_step = function(self, dtime)
            local pos = self.object:get_pos()
            local node = minetest.get_node(pos)
            if node.name ~= "vlf_pale_garden:open_eyeblossom" then
                self.object:remove()
                return
            end
        end,
    })
minetest.register_entity("vlf_pale_garden:eyeblossom_pot_emissive", {
	initial_properties = {
		pointable = false,
		visual = "mesh",
		mesh = "plantlike.obj",
		visual_size = {x = 10, y = 10},
		textures = { "open_eyeblossom_emissive.png" },
		glow = 15,
	},
        on_step = function(self, dtime)
            local pos = self.object:get_pos()
            local node = minetest.get_node(pos)
            if node.name ~= "mcl_flowerpots:flower_pot_open_eyeblossom" then
                self.object:remove()
                return
            end
        end,
})

minetest.register_abm({
    label = "Bloom closed eyeblossoms",
    nodenames = {"vlf_pale_garden:closed_eyeblossom"},
    interval = 5, -- Frequency of the check (in seconds)
    chance = 1, -- Apply the ABM to all matching nodes

    action = function(pos, node)
        -- Check the game time
        local time_of_day = minetest.get_timeofday()
        if time_of_day <= 0.8 and time_of_day >= 0.2 then
            return
        end

        -- Find all closed eyeblossoms within a 10-block radius
        local positions = minetest.find_nodes_in_area(
            vector.subtract(pos, 10),
            vector.add(pos, 10),
            {"vlf_pale_garden:closed_eyeblossom"}
        )

        if #positions > 0 then
            -- Pick a random closed eyeblossom to bloom
            local random_pos = positions[math.random(1, #positions)]
            minetest.set_node(random_pos, {name = "vlf_pale_garden:open_eyeblossom"})

            -- Trigger surrounding closed eyeblossoms to slowly bloom
            minetest.after(5, function()
                local neighbors = minetest.find_nodes_in_area(
                    vector.subtract(random_pos, 3),
                    vector.add(random_pos, 3),
                    {"vlf_pale_garden:closed_eyeblossom"}
                )

                for _, neighbor_pos in ipairs(neighbors) do
                    minetest.after(math.random(1, 2), function()
                        minetest.set_node(neighbor_pos, {name = "vlf_pale_garden:open_eyeblossom"})
                    end)
                end
            end)
        end
    end,
})

minetest.register_abm({
    label = "Bloom closed eyeblossoms",
    nodenames = {"vlf_pale_garden:open_eyeblossom"},
    interval = 5, -- Frequency of the check (in seconds)
    chance = 1, -- Apply the ABM to all matching nodes

    action = function(pos, node)
        -- Check the game time
        local time_of_day = minetest.get_timeofday()
        if time_of_day > 0.2 and time_of_day < 0.8 then
            --return
        --end

        -- Find all closed eyeblossoms within a 10-block radius
        local positions = minetest.find_nodes_in_area(
            vector.subtract(pos, 10),
            vector.add(pos, 10),
            {"vlf_pale_garden:open_eyeblossom"}
        )

        if #positions > 0 then
            -- Pick a random closed eyeblossom to bloom
            local random_pos = positions[math.random(1, #positions)]
            minetest.set_node(random_pos, {name = "vlf_pale_garden:closed_eyeblossom"})

            -- Trigger surrounding closed eyeblossoms to slowly bloom
            minetest.after(5, function()
                local neighbors = minetest.find_nodes_in_area(
                    vector.subtract(random_pos, 3),
                    vector.add(random_pos, 3),
                    {"vlf_pale_garden:open_eyeblossom"}
                )

                for _, neighbor_pos in ipairs(neighbors) do
                    minetest.after(math.random(1, 2), function()
                        minetest.set_node(neighbor_pos, {name = "vlf_pale_garden:closed_eyeblossom"})
                    end)
                end
            end)
        end
        end
    end,
})
]]
