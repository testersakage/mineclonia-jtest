local SPAWNER_RANGE = (tonumber(minetest.settings:get("active_block_range")) or 4) * 16
local active_particlespawners = {}

mcl_node_particles = {}

local function spawn_node_particles(pos, node)
	local ndef = minetest.registered_nodes[node.name]
	local ph = minetest.hash_node_position(pos)
	if ndef and ndef._node_particlespawner then
		for _, player in pairs(minetest.get_connected_players()) do
			if vector.distance(player:get_pos(), pos) < SPAWNER_RANGE then
				if not active_particlespawners[player][ph] then
					local ps = table.copy(ndef._node_particlespawner)
					ps.playername = player:get_player_name()
					ps.time = 0
					if type(ndef._node_particlespawner_overrides) == "table" then
						table.update(ps, ndef._node_particlespawner_overrides)
					elseif type(ndef._node_particlespawner_overrides) == "function" then
						table.update(ps, ndef._node_particlespawner_overrides(pos, player))
					end
					ps.minpos = vector.add(pos, ps.minpos)
					ps.maxpos = vector.add(pos, ps.maxpos)
					active_particlespawners[player][ph] = minetest.add_particlespawner(ps)
				end
			end
		end
	end
end

local function remove_spawner_pos(pos)
	local ph = minetest.hash_node_position(pos)
	for pl, ps in pairs(active_particlespawners) do
		for cph, psid in pairs(ps) do
			if ph == cph then
				minetest.delete_particlespawner(psid)
				active_particlespawners[pl][cph] = nil
			end
		end
	end
end

function mcl_node_particles.register_particlespawner(nodename, psdef, ps_overrides)
	local def = minetest.registered_nodes[nodename]
	if def then
		local old_od = def.on_destruct
		minetest.override_item(nodename, {
			groups = table.merge(def.groups, { node_particlespawner = 1 }),
			_node_particlespawner = psdef,
			_node_particlespawner_overrides = ps_overrides,
			on_destruct = function(pos)
				remove_spawner_pos(pos)
				if old_od then
					return old_od(pos)
				end
			end
		})
	else
		minetest.log("warning", "[mcl_node_particles] attempting to register "..tostring(nodename).." for a node particlespawner, however it's node definition was not found. Skipping it.")
	end
end

mcl_player.register_globalstep_slow(function(player)
	for ph, psid in pairs(active_particlespawners[player]) do
		local pos = minetest.get_position_from_hash(ph)
		if vector.distance(player:get_pos(), pos) > SPAWNER_RANGE then
			minetest.delete_particlespawner(psid)
			active_particlespawners[player][ph] = nil
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	active_particlespawners[player] = {}
end)
minetest.register_on_leaveplayer(function(player)
	for k, v in pairs(active_particlespawners[player]) do
		minetest.delete_particlespawner(v)
	end
	active_particlespawners[player] = nil
end)

minetest.register_abm({
	label = "Node Particlespawners",
	nodenames = { "group:node_particlespawner" },
	interval = 2,
	chance = 2,
	action = spawn_node_particles,
})
