mcl_torches.player_ps = {}
local particle_distance = 32

-- Check if placement at given node is allowed
local function check_placement_allowed(node, wdir)
	-- Torch placement rules: Disallow placement on some nodes. General rule: Solid, opaque, full cube collision box nodes are allowed.
	-- Special allowed nodes:
	-- * soul sand
	-- * mob spawner
	-- * chorus flower
	-- * glass, barrier, ice
	-- * Fence, wall, end portal frame with ender eye: Only on top
	-- * Slab, stairs: Only on top if upside down

	-- Special forbidden nodes:
	-- * Piston, sticky piston
	local def = minetest.registered_nodes[node.name]
	if not def then
		return false
	-- No ceiling torches
	elseif wdir == 0 then
		return false
	elseif not def.buildable_to then
		if node.name ~= "mcl_core:ice" and node.name ~= "mcl_nether:soul_sand" and node.name ~= "mcl_mobspawners:spawner" and node.name ~= "mcl_core:barrier" and node.name ~= "mcl_end:chorus_flower" and node.name ~= "mcl_end:chorus_flower_dead" and (not def.groups.glass) and
				((not def.groups.solid) or (not def.groups.opaque)) then

			-- Only allow top placement on these nodes
			if node.name == "mcl_end:dragon_egg" or node.name == "mcl_portals:end_portal_frame_eye" or def.groups.fence == 1 or def.groups.wall or def.groups.slab_top == 1 or def.groups.anvil or def.groups.pane or (def.groups.stair == 1 and minetest.facedir_to_dir(node.param2).y ~= 0) then
				if wdir ~= 1 then
					return false
				end
			else
				return false
			end
		elseif minetest.get_item_group(node.name, "piston") >= 1 then
			return false
		end
	end
	return true
end

function mcl_torches.register_torch(def)
	local itemstring = minetest.get_current_modname() .. ":" .. def.name
	local itemstring_wall = itemstring .. "_wall"

	def.light = def.light or 14
	def.mesh_floor = def.mesh_floor or "mcl_torches_torch_floor.obj"
	def.mesh_wall = def.mesh_wall or "mcl_torches_torch_wall.obj"

	local groups = def.groups or {}

	groups.attached_node = 1
	groups.torch = 1
	groups.dig_by_water = 1
	groups.destroy_by_lava_flow = 1
	groups.dig_by_piston = 1
	groups.unsticky = 1
	groups.attaches_to_top = 1
	groups.attaches_to_side = 1
	groups.offhand_item = 1
	groups.offhand_placeable = 1

	local floordef = {
		description = def.description,
		_doc_items_longdesc = def.doc_items_longdesc,
		_doc_items_usagehelp = def.doc_items_usagehelp,
		_doc_items_hidden = def.doc_items_hidden,
		_doc_items_create_entry = def._doc_items_create_entry,
		_mcl_torches_particles = def.particles,
		drawtype = "mesh",
		mesh = def.mesh_floor,
		inventory_image = def.icon,
		wield_image = def.icon,
		tiles = def.tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		light_source = def.light,
		groups = groups,
		drop = def.drop or itemstring,
		use_texture_alpha = "clip",
		selection_box = {
			type = "wallmounted",
			wall_bottom = {-2/16, -0.5, -2/16, 2/16, 1/16, 2/16},
		},
		sounds = def.sounds,
		node_placement_prediction = "",
		on_destruct = function(pos)
			local ph = core.hash_node_position(pos)

			for k, v in pairs(mcl_torches.player_ps) do
				if v[ph] then
					if v[ph].flame then core.delete_particlespawner(v[ph].flame) end
					if v[ph].smoke then core.delete_particlespawner(v[ph].smoke) end

					mcl_torches.player_ps[k][ph] = nil
				end
			end
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				-- no interaction possible with entities, for now.
				return itemstack
			end

			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local def = minetest.registered_nodes[node.name]
			if not def then return itemstack end

			-- Call on_rightclick if the pointed node defines it
			local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
			if rc ~= nil then return rc end --check for nil explicitly to determine if on_rightclick existed

			local above = pointed_thing.above
			local wdir = minetest.dir_to_wallmounted({x = under.x - above.x, y = under.y - above.y, z = under.z - above.z})

			if type(def.placement_prevented) == "function" then
				if
					def.placement_prevented({
						itemstack = itemstack,
						placer = placer,
						pointed_thing = pointed_thing,
					})
				then
					return itemstack
				end
			elseif check_placement_allowed(node, wdir) == false then
				return itemstack
			end

			local itemstring = itemstack:get_name()
			local fakestack = ItemStack(itemstack)
			local idef = fakestack:get_definition()
			local retval

			if wdir == 1 then
				retval = fakestack:set_name(itemstring)
			else
				retval = fakestack:set_name(itemstring_wall)
			end
			if not retval then
				return itemstack
			end

			local success
			itemstack, success = minetest.item_place_node(fakestack, placer, pointed_thing, wdir)
			itemstack:set_name(itemstring)

			if success and idef.sounds and idef.sounds.place then
				minetest.sound_play(idef.sounds.place, {pos=under, gain=1}, true)
			end
			return itemstack
		end,
		on_rotate = false,
	}
	minetest.register_node(itemstring, floordef)

	local groups_wall = table.copy(groups)
	groups_wall.torch = 2
	groups_wall.not_in_creative_inventory = 1

	local walldef = {
		_mcl_torches_particles = def.particles,
		drawtype = "mesh",
		mesh = def.mesh_wall,
		tiles = def.tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		light_source = def.light,
		groups = groups_wall,
		drop = def.drop or itemstring,
		use_texture_alpha = "clip",
		_mcl_baseitem = itemstring,
		selection_box = {
			type = "wallmounted",
			wall_side = {-0.5, -0.3, -0.1, -0.2, 0.325, 0.1},
		},
		sounds = def.sounds,
		on_rotate = false,
		on_destruct = function(pos)
			local ph = core.hash_node_position(pos)

			for k, v in pairs(mcl_torches.player_ps) do
				if v[ph] then
					if v[ph].flame then core.delete_particlespawner(v[ph].flame) end
					if v[ph].smoke then core.delete_particlespawner(v[ph].smoke) end

					mcl_torches.player_ps[k][ph] = nil
				end
			end
		end,
	}
	minetest.register_node(itemstring_wall, walldef)

	-- Add entry alias for the Help
	if minetest.get_modpath("doc") then
		doc.add_entry_alias("nodes", itemstring, "nodes", itemstring_wall)
	end
end

local function in_range(npos, ppos)
	return vector.distance(npos, ppos) < particle_distance
end

local function generate_particles(pos, node)
	local ph = core.hash_node_position(pos)
	local n_name = node.name
	local is_wall = core.get_item_group(n_name, "torch") == 2
	local n_defs = core.registered_nodes[n_name]

	if not n_defs or not n_defs._mcl_torches_particles then return end

	local add_to_pos = vector.new(0, 0.125, 0)
	local flame = n_defs._mcl_torches_particles.flame
	local smoke = n_defs._mcl_torches_particles.smoke

	if is_wall then
		if node.param2 == 2 then
			add_to_pos = vector.new(0.25, 0.375, 0)
		elseif node.param2 == 3 then
			add_to_pos = vector.new(-0.25, 0.375, 0)
		elseif node.param2 == 4 then
			add_to_pos = vector.new(0, 0.375, 0.25)
		elseif node.param2 == 5 then
			add_to_pos = vector.new(0, 0.375, -0.25)
		end
	end

	for pl in mcl_util.connected_players() do
		local in_range = in_range(pos, pl:get_pos())
		if not mcl_torches.player_ps[pl] then mcl_torches.player_ps[pl] = {} end
		if not mcl_torches.player_ps[pl][ph] then mcl_torches.player_ps[pl][ph] = {} end
		if not mcl_torches.player_ps[pl][ph].flame and in_range and flame then
			mcl_torches.player_ps[pl][ph].flame = core.add_particlespawner({
				amount = 1,
				collisiondetection = false,
				maxpos = vector.add(pos, add_to_pos),
				minpos = vector.add(pos, add_to_pos),
				maxvel = vector.zero(),
				minvel = vector.zero(),
				maxacc = vector.zero(),
				minacc = vector.zero(),
				maxexptime = 1,
				minexptime = 0.5,
				maxsize = 5,
				minsize = 2,
				glow = 14,
				playername = pl:get_player_name(),
				texture = {name = flame, scale_tween = {1, 0.5}},
				time = 0
			})
		end
		if not mcl_torches.player_ps[pl][ph].smoke and in_range and smoke then
			mcl_torches.player_ps[pl][ph].smoke = core.add_particlespawner(table.merge({
				amount = 1,
				collisiondetection = false,
				maxpos = vector.add(pos, vector.add(add_to_pos, smoke.maxpos_to_add)),
				minpos = vector.add(pos, vector.add(add_to_pos, smoke.minpos_to_add)),
				maxsize = 2,
				minsize = 1,
				maxexptime = 1,
				minexptime = 0.5,
				playername = pl:get_player_name(),
				time = 0
			}, smoke.ps_defs))
		end
	end

	for pl, pt in pairs(mcl_torches.player_ps) do
		for _, sp in pairs(pt) do
			if not pl or not pl:get_pos() then
				if sp.flame then core.delete_particlespawner(sp.flame) end
				if sp.smoke then core.delete_particlespawner(sp.smoke) end
			elseif mcl_torches.player_ps[pl][ph] and not in_range(pos, pl:get_pos()) then
				if mcl_torches.player_ps[pl][ph].flame then
					core.delete_particlespawner(mcl_torches.player_ps[pl][ph].flame)
				end
				if mcl_torches.player_ps[pl][ph].smoke then
					core.delete_particlespawner(mcl_torches.player_ps[pl][ph].smoke)
				end

				mcl_torches.player_ps[pl][ph] = nil
			end
		end

		if not pl or not pl:get_pos() then mcl_torches.player_ps[pl][ph] = nil end
	end
end

core.register_on_leaveplayer(function(player)
	if mcl_torches.player_ps[player] then
		for _, v in pairs(mcl_torches.player_ps[player]) do
			core.delete_particlespawner(v)
		end

		mcl_torches.player_ps[player] = nil
	end
end)

core.register_abm({
	label = "Torch Particles",
	nodenames = {"group:torch"},
	interval = 4,
	chance = 1,
	action = generate_particles
})

core.register_abm({
	label = "Remove Torch Particles",
	nodenames = {"group:redstone_torch"},
	interval = 2,
	chance = 1,
	action = function(pos, node)
		if core.get_item_group(node.name, "redstone_torch") ~= 2 then return end

		local ph = core.hash_node_position(pos)

		for pl in mcl_util.connected_players() do
			if mcl_torches.player_ps[pl] and mcl_torches.player_ps[pl][ph] and mcl_torches.player_ps[pl][ph].smoke then
				core.delete_particlespawner(mcl_torches.player_ps[pl][ph].smoke)
			end

			mcl_torches.player_ps[pl][ph] = nil
		end
	end,
})
