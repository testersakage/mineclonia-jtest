local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
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
--[[
local PARTICLE_DISTANCE = 20

local spawn_particlespawner = {
	texture = "",
	texpool = {},
	time = 2,
	glow = 1,
	minvel = vector.zero(),
	maxvel = vector.zero(),
	minacc = vector.new(-0.1, -0.1, -0.1),
	maxacc = vector.new(0.2, 0.2, 0.2),
	minexptime = 1.25,
	maxexptime = 2,
	minsize = 5.5,
	maxsize= 7.5,
	collisiondetection = true,
	collision_removal = true,
}

minetest.register_node("vlf_pale_garden:inactive_creaking_heart", {
	description = ("Creaking Heart"),
	_doc_items_hidden = false,
	paramtype2 = "facedir",
	tiles = {"creaking_heart_top.png", "creaking_heart_top.png","creaking_heart.png"},
	groups = {
		handy = 1, axey = 1,
		building_block = 1,
		tree = 1, material_wood=1,
		flammable = 3, fire_encouragement=5, fire_flammability=20,
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
})

local function check_creaking_heart_activation(pos)
    local node = minetest.get_node(pos)
    local facedir = node.param2

    local left_pos = {x = pos.x - 1, y = pos.y, z = pos.z}
    local right_pos = {x = pos.x + 1, y = pos.y, z = pos.z}
    local above_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
    local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    local front_pos = {x = pos.x, y = pos.y, z = pos.z + 1}
    local back_pos = {x = pos.x, y = pos.y, z = pos.z - 1}

    local left_node = minetest.get_node(left_pos)
    local right_node = minetest.get_node(right_pos)
    local above_node = minetest.get_node(above_pos)
    local below_node = minetest.get_node(below_pos)
    local front_node = minetest.get_node(front_pos)
    local back_node = minetest.get_node(back_pos)

    -- Table of valid block names for comparison
    local valid_blocks = {
        ["mcl_trees:tree_pale_oak"] = true,
        ["mcl_trees:stripped_pale_oak"] = true,
        ["mcl_trees:bark_stripped_pale_oak"] = true,
        ["mcl_trees:bark_pale_oak"] = true
    }

    -- Check left and right nodes
    if valid_blocks[left_node.name] and valid_blocks[right_node.name] then
        if left_node.param2 == facedir and right_node.param2 == facedir then
            return true
        end
    end

    -- Check above and below nodes
    if valid_blocks[above_node.name] and valid_blocks[below_node.name] then
        if above_node.param2 == facedir and below_node.param2 == facedir then
            return true
        end
    end

    -- Check above and below nodes
    if valid_blocks[front_node.name] and valid_blocks[back_node.name] then
        if front_node.param2 == facedir and back_node.param2 == facedir then
            return true
        end
    end

    return false
end

minetest.register_abm({
    label = "Check Creaking Heart Activation",
    nodenames = {"vlf_pale_garden:inactive_creaking_heart"},
    interval = 2,
    chance = 1,
    action = function(pos, node)
        if check_creaking_heart_activation(pos) then
            minetest.set_node(pos, {name = "vlf_pale_garden:active_creaking_heart", param2 = node.param2})
        end
    end
})

minetest.register_node("vlf_pale_garden:active_creaking_heart", {
	description = ("Creaking Heart"),
	_doc_items_hidden = false,
	paramtype2 = "facedir",
	tiles = {"creaking_heart_top_active.png", "creaking_heart_top_active.png","creaking_heart_active.png"},
	groups = {
		handy = 1, axey = 1,
		building_block = 1,
		tree = 1, material_wood=1,
		flammable = 3, fire_encouragement=5, fire_flammability=20,
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	on_dig = function(pos, node, digger)
	-- Remove the creaking mob whose heart position matches the block
	for _, object in pairs(minetest.get_objects_inside_radius(pos, 32)) do
		local lua_entity = object:get_luaentity()
		if lua_entity and lua_entity.name == "vlf_pale_garden:creaking_transient" and lua_entity._heart_pos and vector.equals(lua_entity._heart_pos, pos) then
			minetest.add_particlespawner({
				amount = 20, -- Number of particles
				time = 1.5, -- Duration of the spawner
				minpos = vector.subtract(lua_entity.object:get_pos(), {x = 0.5, y = 1.5, z = 0.5}),
				maxpos = vector.add(lua_entity.object:get_pos(), {x = 0.5, y = 2.5, z = 0.5}),
				minvel = {x = -0.5, y = -2, z = -0.5}, -- Particles only fall downwards
				maxvel = {x = 0.5, y = -4, z = 0.5},  -- Downward velocity range
				minacc = {x = 0, y = -7.81, z = 0}, -- Gravity effect pulling particles down
				maxacc = {x = 0, y = -7.81, z = 0},
				minexptime = 0.5, -- Minimum lifetime of particles
				maxexptime = 1, -- Maximum lifetime of particles
				minsize = 1, -- Minimum size of particles
				maxsize = 3, -- Maximum size of particles
				texture = "tree_creak_particle.png", -- Particle texture
				glow = 0, -- Glow effect (optional)
			})
			object:remove()
			-- Particle spawner to simulate tree-like creaking falling apart
		end
	end
	minetest.node_dig(pos, node, digger)
end,

})

minetest.register_abm({
	label = "Creaking Heart Mob Spawner",
	nodenames = {"vlf_pale_garden:active_creaking_heart"},
	interval = 2,
	chance = 1,
	action = function(pos, node)
		-- Get current time of day
		local time_of_day = minetest.get_timeofday()
		local meta = minetest.get_meta(pos)
		local has_spawned = meta:get_int("creaking_spawned") == 1

		-- Only attempt to spawn if it's night and a mob hasn't already spawned
		if (time_of_day >= 0.8 or time_of_day <= 0.2) and not has_spawned then
			local spawn_pos = nil

			for dy = 0, -10, -1 do
				for dx = -5, 5 do
					for dz = -5, 5 do
						if math.abs(dx) + math.abs(dz) <= 5 then
							local check_pos = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
							local node_below = minetest.get_node(check_pos)
							local node_above_pos = {x = check_pos.x, y = check_pos.y + 1, z = check_pos.z}
							local node_above = minetest.get_node(node_above_pos)
							local node_below_def = minetest.registered_nodes[node_below.name]
							if node_below_def and node_below_def.walkable and minetest.get_item_group(node_below.name, "solid") > 0
							and node_above.name == "air" then
								spawn_pos = node_above_pos
								break
							end
						end
					end
				end
			end

			-- If a valid spawn position was found, spawn the mob and mark it as spawned
			if spawn_pos and not minetest.is_protected(spawn_pos, "") then
				local mob = mcl_mobs.spawn(spawn_pos, "vlf_pale_garden:creaking_transient")
				if mob then
					local lua_entity = mob:get_luaentity()
					if lua_entity then
						lua_entity._heart_pos = pos
						lua_entity.spawn_from_heart = true

						-- Particle effect
						local amount = 6
						local name = "mcl_particles_generic.png^[colorize:#A0A0A0:255"
						for _, pl in pairs(minetest.get_connected_players()) do
							if vector.distance(pos, pl:get_pos()) < PARTICLE_DISTANCE then
								table.insert(spawn_particlespawner.texpool, {
									name = name,
									animation = {type = "vertical_frames", aspect_w = 8, aspect_h = 8, length = 1.9},
								})
								minetest.add_particlespawner(table.merge(spawn_particlespawner, {
									amount = amount,
									minpos = vector.subtract(lua_entity.object:get_pos(), {x = 0.5, y = 0.5, z = 0.5}),
									maxpos = vector.add(lua_entity.object:get_pos(), {x = 0.5, y = 1.5, z = 0.5}),
									playername = pl:get_player_name(),
								}))
							end
						end
					end
					-- Mark that a mob has been spawned this night
					meta:set_int("creaking_spawned", 1)
				end
			end
		elseif time_of_day > 0.2 and time_of_day < 0.8 and has_spawned then
			-- Remove existing "creaking" mobs that match the heart position if day
			meta:set_int("creaking_spawned", 0)
			for _, object in pairs(minetest.get_objects_inside_radius(pos, 32)) do
				local lua_entity = object:get_luaentity()
				if lua_entity and lua_entity.name == "vlf_pale_garden:creaking_transient" and lua_entity._heart_pos and vector.equals(lua_entity._heart_pos, pos) then
					local amount = 6
					local name = "mcl_particles_generic.png^[colorize:#A0A0A0:255"
					for _, pl in pairs(minetest.get_connected_players()) do
						if vector.distance(pos, pl:get_pos()) < PARTICLE_DISTANCE then
							table.insert(spawn_particlespawner.texpool, {
								name = name,
								animation = {type = "vertical_frames", aspect_w = 8, aspect_h = 8, length = 1.9},
							})
							minetest.add_particlespawner(table.merge(spawn_particlespawner, {
								amount = amount,
								minpos = vector.subtract(lua_entity.object:get_pos(), {x = 0.5, y = 0.5, z = 0.5}),
								maxpos = vector.add(lua_entity.object:get_pos(), {x = 0.5, y = 1.5, z = 0.5}),
								playername = pl:get_player_name(),
							}))
						end
					end
					object:remove()
				end
			end
		end
	end,
})

minetest.register_node("vlf_pale_garden:closed_eyeblossom", {
	description = ("Closed Eyeblossom"),
	drawtype = "plantlike",
	waving = 1,
	tiles = { "eyeblossom_stem.png^closed_eyeblossom.png" },
	inventory_image = "eyeblossom_stem.png^closed_eyeblossom.png",
	wield_image = "eyeblossom_stem.png^closed_eyeblossom.png",
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
})
mcl_flowerpots.register_potted_flower("vlf_pale_garden:closed_eyeblossom", {
	name = "closed_eyeblossom",
	desc = ("Closed Eyeblossom"),
	image = "(eyeblossom_stem.png^closed_eyeblossom.png)",
})

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
