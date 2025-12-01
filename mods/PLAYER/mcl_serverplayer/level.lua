------------------------------------------------------------------------
-- Biome and level data transmission to client-side players.
------------------------------------------------------------------------

local insert = table.insert
local ipos3 = mcl_levelgen.ipos3
local send_biome_data_updates = mcl_levelgen.levelgen_enabled

local function get_biome_state (state)
	if state.biome_state then
		return state.biome_state
	end
	local tbl = {
		-- Number of MapBlocks whose biome data is known to
		-- have been transferred to the client.
		num_loaded = 0,
		-- Map between MapBlock hashes and booleans indicating
		-- that data at that position is known to the client.
		is_loaded = {},
		dtime_since_last_transfer = 0.5,
	}
	state.biome_state = tbl
	return tbl
end

local MAX_LOADED_MAPBLOCKS = 2048
-- Transfer biome data within a radius of 3 blocks around each player.
local MAP_BLOCK_RANGE = 3
local arshift = bit.arshift
local hashmapblock = mcl_levelgen.hashmapblock

local function within_map_limits_p (x, y, z)
	return x >= -2048 and x <= 2047
		and z >= -2048 and z <= 2047
		and y >= -2048 and y <= 2047
end

local v = vector.new ()

function mcl_serverplayer.update_biome_data (state, player, dtime)
	if not send_biome_data_updates then
		return
	end

	local tbl = get_biome_state (state)
	tbl.dtime_since_last_transfer
		= tbl.dtime_since_last_transfer + dtime
	if tbl.dtime_since_last_transfer < 0.5 then
		return
	else
		tbl.dtime_since_last_transfer = 0
	end

	if tbl.num_loaded > MAX_LOADED_MAPBLOCKS then
		-- The client isn't disposing of loaded MapBlocks;
		-- delete tbl.is_loaded to prevent it from burgeoning
		-- endlessly.
		tbl.is_loaded = {}
		tbl.num_loaded = 0
	end

	local self_pos = player:get_pos ()
	local node_pos = mcl_util.get_nodepos (self_pos)
	local bx = arshift (node_pos.x, 4)
	local by = arshift (node_pos.y, 4)
	local bz = arshift (node_pos.z, 4)

	local load_list, meta_list = {}, {}
	local len = 0

	local is_loaded = tbl.is_loaded
	for x, y, z in ipos3 (bx - MAP_BLOCK_RANGE,
			      by - MAP_BLOCK_RANGE,
			      bz - MAP_BLOCK_RANGE,
			      bx + MAP_BLOCK_RANGE,
			      by + MAP_BLOCK_RANGE,
			      bz + MAP_BLOCK_RANGE) do
		local hash = hashmapblock (x, y, z)
		if not is_loaded[hash] and within_map_limits_p (x, y, z) then
			v.x = x * 16
			v.y = y * 16
			v.z = z * 16
			local meta = core.compare_block_status (v, "loaded")
				and mcl_levelgen.get_biome_meta (x, y, z)
			if meta then
				is_loaded[hash] = true
				tbl.num_loaded = tbl.num_loaded + 1
				insert (load_list, hash)
				insert (load_list, len)
				len = len + #meta
				insert (meta_list, meta)
			end
		end
	end

	-- Dispatch the biome data to the client.
	if len > 0 then
		local index = table.concat (load_list, ',')
		local meta = table.concat (meta_list)
		mcl_serverplayer.send_biome_data (player, index, meta)
	end
end

local blurb = "[mcl_serverplayer]: Client %s attempted to report relinquishment of biome data in MapBlock not recorded by the server: %d,%d,%d"
local unhashmapblock = mcl_levelgen.unhashmapblock

function mcl_serverplayer.discard_biome_data (player, state, list)
	local tbl = get_biome_state (state)
	for _, block in ipairs (list) do
		if block >= 0x1000000000 then
			error ("MapBlock out of range: " .. block)
		end

		if not tbl.is_loaded[block] then
			local name = player:get_player_name ()
			local msg = string.format (blurb, name,
						   unhashmapblock (block))
			core.log ("warning", msg)
		else
			tbl.num_loaded = tbl.num_loaded - 1
			tbl.is_loaded[block] = nil
			assert (tbl.num_loaded >= 0)
		end
	end
end
