-- Damage radius refined here and in the init.lua
local RADIUS = 4
local damage_radius = (RADIUS / math.max(1, RADIUS)) * RADIUS
local radius = 2

-- Wind Charge Registry
register_charge("wind_charge", "Wind Charge", {
	hit_player = mcl_mobs.get_arrow_damage_func(0, "fireball"),
	hit_mob = mcl_mobs.get_arrow_damage_func(6, "fireball"),
	hit_node = function(self, pos, node)
		mcl_charges.wind_burst(pos, damage_radius)
		local pr = PseudoRandom(math.ceil(os.time() / 60 / 10)) -- make particles change direction every 10 minutes
		local v = vector.new(pr:next(-2, 2)/10, 0, pr:next(-2, 2)/10)
			v.y = pr:next(-9, -4) / 10
					minetest.add_particlespawner(table.merge(wind_burst_spawner, {
						minacc = v,
						maxacc = v,
						minpos = vector.offset(pos, -0.8, 0.6, -0.8),
						maxpos = vector.offset(pos, 0.8, 0.8, 0.8),
					}))
		minetest.sound_play("tnt_explode", { pos = pos, gain = 0.4, max_hear_distance = 30, pitch = 2.5 }, true)
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)
		local posAbove = {x = pos.x, y = pos.y + 1, z = pos.z}
		local posBelow = {x = pos.x, y = pos.y - 1, z = pos.z}
		local param2_value = minetest.get_node(pos).param2
		local p2 = param2_value
		local meta1 = minetest.get_meta(pos)
		pos.y = pos.y+1
		local meta2 = minetest.get_meta(pos)
		pos.y = pos.y-1
		local params = {}
			if meta1:get_int("is_open") == 0 and meta2:get_int("is_mirrored") == 0 or meta1:get_int("is_open") == 1 and meta2:get_int("is_mirrored") == 1 then
				params = {1,2,3,0}
			else
				params = {3,0,1,2}
			end
		local np2 = params[p2+1]
-- Doors: There are 4 functions per door. Two to open and two to close. One for each the top and bottom.
				if node.name == "mcl_doors:door_acacia_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_acacia_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_acacia_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_acacia_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_acacia_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_acacia_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_acacia_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_acacia_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_acacia_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_acacia_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_acacia_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_acacia_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_bamboo_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_bamboo_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_bamboo_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_bamboo_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_bamboo_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_bamboo_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_bamboo_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_bamboo_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_bamboo_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_bamboo_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_bamboo_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_bamboo_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_birch_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_birch_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_birch_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_birch_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_birch_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_birch_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_birch_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_birch_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_birch_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_birch_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_birch_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_birch_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_cherry_blossom_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_cherry_blossom_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_cherry_blossom_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_cherry_blossom_b_2" then
				minetest.swap_node(pos, {name = "mcl_doors:door_cherry_blossom_b_1", param2 = np2})
				minetest.set_node(posAbove, {name = "mcl_doors:door_cherry_blossom_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_cherry_blossom_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_cherry_blossom_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_cherry_blossom_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_cherry_blossom_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_cherry_blossom_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_cherry_blossom_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_crimson_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_crimson_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_crimson_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_crimson_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_crimson_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_crimson_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_crimson_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_crimson_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_crimson_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_crimson_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_crimson_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_crimson_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_dark_oak_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_dark_oak_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_dark_oak_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_dark_oak_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_dark_oak_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_dark_oak_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_dark_oak_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_dark_oak_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_dark_oak_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_dark_oak_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_dark_oak_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_dark_oak_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_jungle_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_jungle_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_jungle_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_jungle_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_jungle_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_jungle_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_jungle_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_jungle_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_jungle_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_jungle_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_jungle_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_jungle_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_mangrove_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_mangrove_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_mangrove_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_mangrove_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_mangrove_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_mangrove_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_mangrove_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_mangrove_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_mangrove_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_mangrove_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_mangrove_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_mangrove_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_oak_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_oak_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_oak_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_oak_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_oak_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_oak_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_oak_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_oak_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_oak_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_oak_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_oak_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_oak_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_spruce_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_spruce_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_spruce_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_spruce_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_spruce_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_spruce_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_spruce_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_spruce_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_spruce_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_spruce_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_spruce_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_spruce_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_warped_b_1" then
					minetest.swap_node(pos, {name = "mcl_doors:door_warped_b_2", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_warped_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_warped_b_2" then
					minetest.swap_node(pos, {name = "mcl_doors:door_warped_b_1", param2 = np2})
					minetest.set_node(posAbove, {name = "mcl_doors:door_warped_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_warped_t_1" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_warped_b_2", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_warped_t_2", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
				if node.name == "mcl_doors:door_warped_t_2" then
					minetest.swap_node(posBelow, {name = "mcl_doors:door_warped_b_1", param2 = np2})
					minetest.set_node(pos, {name = "mcl_doors:door_warped_t_1", param2 = np2})
					if meta1:get_int("is_open") == 1 then
						minetest.sound_play("doors_door_close", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 0)
						meta2:set_int("is_open", 0)
					else
						minetest.sound_play("doors_door_open", { pos = pos, gain = 0.4, max_hear_distance = 10 }, true)
						meta1:set_int("is_open", 1)
						meta2:set_int("is_open", 1)
					end
				end
-- Trapdoors: 2 functions. One for opening and one for closing
				if node.name == "mcl_doors:trapdoor_acacia" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_acacia_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_acacia_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_acacia", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_bamboo" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_bamboo_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_bamboo_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_bamboo", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_birch" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_birch_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_birch_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_birch", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_cherry_blossom" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_cherry_blossom_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_cherry_blossom_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_cherry_blossom", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_crimson" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_crimson_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_crimson_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_crimson", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_dark_oak" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_dark_oak_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_dark_oak_open" then
				minetest.swap_node(pos, {name = "mcl_doors:trapdoor_dark_oak", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_jungle" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_jungle_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_jungle_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_jungle", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_mangrove" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_mangrove_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_mangrove_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_mangrove", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_oak" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_oak_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_oak_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_oak", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_spruce" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_spruce_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_spruce_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_spruce", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_warped" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_warped_open", param2 = param2_value})
				end
				if node.name == "mcl_doors:trapdoor_warped_open" then
					minetest.swap_node(pos, {name = "mcl_doors:trapdoor_warped", param2 = param2_value})
				end
-- Buttons:
				if node.name == "mesecons_button:button_acacia_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_bamboo_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_birch_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_cherry_blossom_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_crimson_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_dark_oak_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_jungle_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_mangrove_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_oak_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_spruce_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_button:button_warped_off" then
					minetest.punch_node(pos)
				end
-- Bell, Chorus flower, Decorated Pot, and Wall Lever:
				if node.name == "mcl_bells:bell" then
					mcl_bells.ring_once(pos)
				end
				if node.name == "mcl_end:chorus_flower" then
					minetest.dig_node(pos)
					mcl_charges.chorus_flower_effects(pos, radius)
				end
				if node.name == "mcl_pottery_sherds:pot" then
					minetest.dig_node(pos)
					mcl_charges.pot_effects(pos, radius)
				end
				if node.name == "mesecons_walllever:wall_lever_off" then
					minetest.punch_node(pos)
				end
				if node.name == "mesecons_walllever:wall_lever_on" then
					minetest.punch_node(pos)
				end
	end,
	hit_player_alt = function(self, pos)
		mcl_charges.wind_burst(pos, damage_radius)
		local pr = PseudoRandom(math.ceil(os.time() / 60 / 10)) -- make particles change direction every 10 minutes
		local v = vector.new(pr:next(-2, 2)/10, 0, pr:next(-2, 2)/10)
			v.y = pr:next(-9, -4) / 10
				minetest.add_particlespawner(table.merge(wind_burst_spawner, {
					minacc = v,
					maxacc = v,
					minpos = vector.offset(pos, -0.8, 0.6, -0.8),
					maxpos = vector.offset(pos, 0.8, 0.8, 0.8),
				}))
		minetest.sound_play("tnt_explode", { pos = pos, gain = 0.5, max_hear_distance = 30, pitch = 2.5 }, true)
	end,
	hit_mob_alt = function(self, pos)
		mcl_charges.wind_burst(pos, damage_radius)
		local pr = PseudoRandom(math.ceil(os.time() / 60 / 10)) -- make particles change direction every 10 minutes
		local v = vector.new(pr:next(-2, 2)/10, 0, pr:next(-2, 2)/10)
			v.y = pr:next(-9, -4) / 10
				minetest.add_particlespawner(table.merge(wind_burst_spawner, {
					minacc = v,
					maxacc = v,
					minpos = vector.offset(pos, -0.8, 0.6, -0.8),
					maxpos = vector.offset(pos, 0.8, 0.8, 0.8),
				}))
		minetest.sound_play("tnt_explode", { pos = pos, gain = 0.5, max_hear_distance = 30, pitch = 2.5 }, true)
	end,
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal = 1})
		minetest.after(3, function()
			if self.object:get_luaentity() then
				self.object:remove()
			end
		end)
	end,
})