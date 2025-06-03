local ipairs = ipairs
local ipos1 = mcl_levelgen.ipos1
local ipos2 = mcl_levelgen.ipos2

local S = core.get_translator ("mcl_levelgen")
local mt_chunksize = core.ipc_get ("mcl_levelgen:mt_chunksize")
local chunksize = mt_chunksize * 16

--------------------------------------------------------------------------
-- Level post-processing.
--------------------------------------------------------------------------

-- Decorations are divided into two types, structures and features,
-- between which the chief difference is that structure placement is
-- decided by the level seed alone, and precedes and exerts influence
-- on terrain generation, while feature placement is contingent on
-- characteristics of the terrain unavailable before generation
-- concludes.  Therefore, in contrast to structures, which may occupy
-- multiple MapChunks because their positions in each are available
-- independently of the contents of their origins or adjoining chunks,
-- features must be placed after their origins are generated and care
-- must be taken that adjoining mapblocks should also be available and
-- ready to receive any portion of a feature that should extrude
-- beyond the chunk where it is placed.  This does however place an
-- upper limit on the size of a feature; more below.
--
-- Since adjacent chunks are not available in an emerge environment,
-- terrain that is initially received from the said environment is
-- designated as "proto-chunks", and some record-keeping is undertaken
-- in the main thread to ascertain when a sufficient periphery has
-- been generated around a proto-chunk for feature placement to
-- commence, whereupon the periphery and proto-chunk at hand are
-- loaded into a VoxelManipulator and submitted to an async
-- environment for feature processing and the periphery is excluded
-- from further modification till the proto-chunk is complete.  This
-- component is the "regeneration scheduler."
--
-- Feature generation may also be influenced by the products of prior
-- feature generation, in particular, on alterations to the surface
-- height they may have produced.  This is problematic because
-- Minetest worlds are also partitioned into MapBlocks vertically, so
-- that heightmap modifications for one phase are not certain to be
-- conclusive when the next phase commences, which issue is partially
-- addressed by increasing the height of the periphery required of
-- each MapBlock processed.

local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local lshift = bit.lshift
local rshift = bit.rshift
local arshift = bit.arshift

local floor = math.floor
local ceil = math.ceil
local mathmin = math.min
local mathmax = math.max

local function dbg (...)
	-- print (string.format (...))
end

local generation_radius
	= core.settings:get ("mcl_feature_placement_radius") or "0"
generation_radius = mathmax (1, tonumber (generation_radius))

--------------------------------------------------------------------------
-- MapBlock tagging.
--------------------------------------------------------------------------

-- Each MapBlock enjoys 8 bits' worth of tags globally accessible that
-- decide whether or not it is a proto-block.  These tags are stored
-- in mod storage in 256x24x256 sections (in the case of the
-- Overworld); when represented as doubles where 32 bits of the
-- significand are available for bitwise operations each section
-- amounts to roughly 4 megabytes.

local SS = 256
local SSHIFT = 8
local HEIGHT = 32
local HEIGHT_SHIFT = 5
local NUMBER_BITS = 4
local INDICES = floor ((SS * HEIGHT * SS * 8 + NUMBER_BITS - 1) / NUMBER_BITS)

-- TODO: generalize to multiple dimensions.
local OVERWORLD_MIN = mcl_vars.mg_overworld_min
local OVERWORLD_MIN_BLOCK = OVERWORLD_MIN / 16
local OVERWORLD_MAX_BLOCK = OVERWORLD_MIN_BLOCK + 24 - 1
local storage = core.get_mod_storage and core.get_mod_storage () or nil

local function section (bx, bz)
	local xs = bx - 128
	local zs = bz - 128
	return arshift (xs, SSHIFT), arshift (zs, SSHIFT)
end

local function section_hash (sx, sz)
	return lshift (sx + 9, 5) + sz + 9
end

local loaded_mb_sections = {}
local section_access_times = {}
local sections_loaded = {}

for i = 1, section_hash (17, 17) + 1 do
	sections_loaded[i] = false
end

local function create_section (hash)
	local tbl = {}
	for i = 1, INDICES do
		tbl[i] = 0
	end
	return tbl
end

-- The three low order bits are reserved for a state ordinal,
-- while bits 3:7 of the lowermost 8 MapBlocks are reserved for
-- heightmap references.

local MBS_UNKNOWN = 0
local MBS_LOCKED = 1
local MBS_LOCKED_GENERATED = 2
local MBS_REGENERATING = 3
local MBS_PROTO_CHUNK = 4
local MBS_GENERATED = 5

local function reset_loaded_section (section)
	for i, word in ipairs (section) do
		local mask = bnot (0x07070707)
		local temp = band (word, mask)
		local w1 = band (word, 7)
		local w2 = band (rshift (word, 8), 7)
		local w3 = band (rshift (word, 16), 7)
		local w4 = band (rshift (word, 24), 7)

		if w1 >= MBS_LOCKED and w1 <= MBS_REGENERATING then
			w1 = ((w1 == MBS_LOCKED or w1 == MBS_REGENERATING)
			      and MBS_PROTO_CHUNK or MBS_GENERATED)
		end
		if w2 >= MBS_LOCKED and w2 <= MBS_REGENERATING then
			w2 = ((w2 == MBS_LOCKED or w2 == MBS_REGENERATING)
			      and MBS_PROTO_CHUNK or MBS_GENERATED)
		end
		if w3 >= MBS_LOCKED and w3 <= MBS_REGENERATING then
			w3 = ((w3 == MBS_LOCKED or w3 == MBS_REGENERATING)
			      and MBS_PROTO_CHUNK or MBS_GENERATED)
		end
		if w4 >= MBS_LOCKED and w4 <= MBS_REGENERATING then
			w4 = ((w4 == MBS_LOCKED or w4 == MBS_REGENERATING)
			      and MBS_PROTO_CHUNK or MBS_GENERATED)
		end

		section[i] = bor (temp, w1, lshift (w2, 8),
				  lshift (w3, 16), lshift (w4, 24))
	end
end

local function load_section (sx, sz)
	local hash = section_hash (sx, sz)
	local section = loaded_mb_sections[hash]
	if not loaded_mb_sections[hash] then
		local str = storage:get_string ("mbs," .. hash)
		if not str or str == "" then
			section = create_section (hash)
			loaded_mb_sections[hash] = section
		else
			local data = core.decompress (str, "zstd")
			section = loadstring (data) ()
			loaded_mb_sections[hash] = section

			-- If this is the first occasion on which the
			-- section has been loaded in this session,
			-- revert instances of MBS_LOCKED and
			-- MBS_REGENERATING into MBS_PROTO_CHUNK.
			if not sections_loaded[hash] then
				reset_loaded_section (section)
				sections_loaded[hash] = true
			end
		end
	end
	return section
end

local function mapblock_index (bx, by, bz)
	local sx, sz = section (bx, bz)
	local section = load_section (sx, sz)
	local ix = band (bx - 128, 0xff)
	local iy = band (by + OVERWORLD_MIN_BLOCK, 0x1f)
	local iz = band (bz - 128, 0xff)
	local index = bor (lshift (bor (lshift (ix, 8), iz), 5), iy)
	local section_index = rshift (index, 2) + 1
	local bit_index = lshift (band (index, 0x3), 3)
	return section, section_index, bit_index
end

local function mapblock_index_1 (bx, by, bz)
	local ix = band (bx - 128, 0xff)
	local iy = band (by + OVERWORLD_MIN_BLOCK, 0x1f)
	local iz = band (bz - 128, 0xff)
	local index = bor (lshift (bor (lshift (ix, 8), iz), 5), iy)
	local section_index = rshift (index, 2) + 1
	local bit_index = lshift (band (index, 0x3), 3)
	return section_index, bit_index
end

local function mapblock_flagbyte (bx, by, bz)
	local section, section_index, bit_index	= mapblock_index (bx, by, bz)
	return band (rshift (section[section_index], bit_index), 0xff)
end

local function mapblock_state (bx, by, bz)
	return band (mapblock_flagbyte (bx, by, bz), 0x7)
end

local function set_mapblock_state (bx, by, bz, state)
	local section, section_index, bit_index	= mapblock_index (bx, by, bz)
	dbg ("  MapBlock state change: X: %d, Y: %d, Z: %d -> %d",
	     bx, by, bz, state)
	section[section_index] = bor (band (bnot (lshift (0x7, bit_index)),
					    section[section_index]),
				      lshift (state, bit_index))
end

-- local function mapblock_flag (bx, by, bz, i)
-- 	return band (rshift (mapblock_flagbyte (bx, by, bz), i + 3), 1)
-- end

-- local function set_mapblock_flag (bx, by, bz, i)
-- 	local section, section_index, bit_index	= mapblock_index (bx, by, bz)
-- 	section[section_index] = bor (lshift (1, bit_index + i + 3),
-- 				      section[section_index])
-- end

-- local function clear_mapblock_flag (bx, by, bz, i)
-- 	local section, section_index, bit_index	= mapblock_index (bx, by, bz)
-- 	section[section_index] = band (bnot (lshift (1, bit_index + i + 3)),
-- 				       section[section_index])
-- end

local function save_section (hash, sdata)
	loaded_mb_sections[hash] = false
	section_access_times[hash] = nil
	local data = "return {" .. table.concat (sdata, ",") .. "}"
	storage:set_string ("mbs," .. hash,
			    core.compress (data, "zstd"))
end

local SECTION_EVICTION_DELAY = 120

local function manage_sections (dtime)
	for hash, dtime in pairs (section_access_times) do
		local t = section_access_times[hash]
		section_access_times[hash] = t + dtime

		if t > SECTION_EVICTION_DELAY then
			save_section (hash, loaded_mb_sections[hash])
		end
	end
end

local function save_sections ()
	for hash, _ in pairs (loaded_mb_sections) do
		save_section (hash, loaded_mb_sections[hash])
	end
end

if not mcl_levelgen.load_feature_environment then
	core.register_globalstep (manage_sections)
	core.register_on_shutdown (save_sections)
end

local blurb = "An existing MapBlock (%d) was reported to post_process_mapchunk: X: %d, Y: %d, Z: %d (src = %s, %s)"
local fmt = "MapBlock %d,%d,%d (%d) was likely overwritten by the generation of the region between %s and %s"
local save_heightmap
local attempt_feature_placement

local function require_regeneration (current, x, y, z)
	-- Regenerate this mapblock or arrange to have it regenerated
	-- when regeneration of its surroundings is complete.  This
	-- would not be necessary if the engine were not liable
	-- sporadically to generate existing mapblocks.
	if current == MBS_GENERATED then
		set_mapblock_state (x, y, z, MBS_PROTO_CHUNK)
		if generation_radius == 1 then
			attempt_feature_placement (x, y, z)
		end
	end
	-- A locked & generated or simply locked MapBlock's contents
	-- are already available and will soon be restored to the
	-- level.
end

-- local parent = {}

local schedule_regeneration_for_emerge

local function post_process_mapchunk (minp, maxp)
	local bx = minp.x / 16
	local by = minp.y / 16
	local bz = minp.z / 16
	local bx1 = floor (maxp.x / 16)
	local by1 = floor (maxp.y / 16)
	local bz1 = floor (maxp.z / 16)

	by = mathmax (by, OVERWORLD_MIN_BLOCK)
	by1 = mathmin (by1, OVERWORLD_MAX_BLOCK)
	if by1 - by < 0 then
		return
	end

	-- Verify that no locked or generated mapblocks have been
	-- overwritten by overgeneration.
	for x, y, z in ipos1 (bx, by, bz, bx1, by1, bz1) do
		local current = mapblock_state (x, y, z)
		if current == MBS_GENERATED
			or current == MBS_LOCKED
			or current == MBS_LOCKED_GENERATED then
			local blurb = string.format (fmt, x, y, z, current,
						     minp:to_string (),
						     maxp:to_string ())
			core.log ("warning", blurb)
			require_regeneration (current, x, y, z)
		end
	end

	for x, y, z in ipos1 (bx, by, bz, bx1, by1, bz1) do
		local current = mapblock_state (x, y, z)
		-- local hash = mcl_levelgen.hashmapblock (x, y, z)

		-- Blocks that are locked for
		-- regeneration are liable to be
		-- processed by this loop.
		if current == MBS_UNKNOWN then
			set_mapblock_state (x, y, z, MBS_PROTO_CHUNK)
			assert (mapblock_state (x, y, z) == MBS_PROTO_CHUNK)
		else
			core.log ("warning", string.format (blurb, current, x, y, z,
							    minp:to_string (),
							    maxp:to_string ()))
			if current == MBS_LOCKED_GENERATED
				or current == MBS_GENERATED then
				require_regeneration (current, x, y, z)
				end
			-- core.log ("warning", "   MapBlock was previously generated by "
			-- 	  .. dump (parent[hash]))
		end
		-- parent[hash] = { minp = minp, maxp = maxp, }
	end

	save_heightmap (bx, bx1, by, by1, bz, bz1, chunksize)
	schedule_regeneration_for_emerge (bx, bx1, by, by1, bz, bz1)
end

if not mcl_levelgen.load_feature_environment then
	core.register_on_generated (post_process_mapchunk)
end

--------------------------------------------------------------------------
-- Min-heap implementation.  TODO: merge this with pathfinding.lua.
--------------------------------------------------------------------------

local function shift_up (self, node, idx)
	local priority = node.priority
	local heap = self.heap
	while idx > 1 do
		local parent = floor (idx / 2)
		local n = heap[parent]

		if n.priority < priority then
			break
		end

		-- Swap node positions.
		heap[idx] = n
		n.idx = idx
		idx = parent
	end

	-- idx is now the proper depth of this node in the tree.
	self.heap[idx] = node
	node.idx = idx
end

local function shift_down (self, node, idx)
	local priority = node.priority
	local heap = self.heap
	local size = self.size

	while true do
		local left = idx * 2
		local right = left + 1

		-- Break early if it is known that no nodes exist
		-- greater than this.
		if left > size then
			break
		end
		local leftnode = heap[left]
		local rightnode = heap[right]
		local lp, rp = leftnode.priority
		rp = rightnode and rightnode.priority or math.huge

		if lp < rp then
			if lp >= priority then
				break
			end
			heap[idx] = leftnode
			leftnode.idx = idx
			idx = left
		else
			if rp >= priority then
				break
			end
			heap[idx] = rightnode
			rightnode.idx = idx
			idx = right
		end
	end

	heap[idx] = node
	node.idx = idx
end

local function mintree_enqueue (self, item, priority)
	assert (not item.idx)
	local i = self.size + 1
	self.size = i
	self.heap[i] = item
	item.idx = i
	item.priority = priority
	shift_up (self, item, i)
end

local function mintree_dequeue (self, item)
	local heap = self.heap
	local n, size = heap[1], self.size
	-- dbg ("Dequeueing: " .. dump (n) .. " [" .. self.size .. "]")
	heap[1], heap[size] = heap[size], nil
	self.size = size - 1
	if size > 0 then
		shift_down (self, heap[1], 1)
	end
	n.idx = nil
	n.penalized = nil
	return n
end

local function mintree_update (self, item, priority)
	local f_old = item.priority
	item.priority = priority

	-- dbg ("Update start: " .. dump (item))

	if priority < f_old then
		shift_up (self, item, item.idx)
	elseif priority > f_old then
		shift_down (self, item, item.idx)
	end

	-- dbg ("Update complete: " .. dump (self))
end

local function mintree_empty (self)
	return self.size == 0
end

local function mintree_contains (self, item)
	return item.idx ~= nil
end

local mintree_meta = {
	enqueue = mintree_enqueue,
	dequeue = mintree_dequeue,
	update = mintree_update,
	empty = mintree_empty,
	contains = mintree_contains,
}
mintree_meta.__index = mintree_meta

local function new_mintree ()
	local tbl = {
		heap = { },
		size = 0,
	}
	setmetatable (tbl, mintree_meta)
	return tbl
end

--------------------------------------------------------------------------
-- Regeneration scheduling.
--------------------------------------------------------------------------

local shutdown_complete = false

local feature_placement_queue = new_mintree ()
local mb_records = {}

local function hashmapblock (x, y, z)
	return lshift (y + 2048, 24)
		+ lshift (x + 2048, 12)
		+ (z + 2048)
end

mcl_levelgen.hashmapblock = hashmapblock

local function getmapblock (x, y, z)
	local hash = hashmapblock (x, y, z)
	local value = mb_records[hash]

	if not value then
		value = {}
		mb_records[hash] = value
	end
	return value
end

local REQUIRED_CONTEXT_Y = 2  -- 2 MapBlocks ought to be taller than
			      -- the tallest feature generated.
local REQUIRED_CONTEXT_XZ = 1
mcl_levelgen.REQUIRED_CONTEXT_Y = REQUIRED_CONTEXT_Y
mcl_levelgen.REQUIRED_CONTEXT_XZ = REQUIRED_CONTEXT_XZ
local huge = math.huge

-- XXX: `compare_block_status' is surprisingly expensive; therefore
-- the criteria applied in deciding whether to skip a mapblock is
-- instead one of distance.

local mathabs = math.abs
local player_x, player_y, player_z

local function test_block_status (x, y, z)
	if generation_radius > 1 then
		local dx = player_x - x
		local dy = player_y - y
		local dz = player_z - z

		return mathabs (dx) <= generation_radius + 1
			and mathabs (dy) <= generation_radius + 1
			and mathabs (dz) <= generation_radius + 1
	else
		return true
	end
end

local function nearest_power_of_2 (x)
	local k, m = 1, 0
	while x > k do
		k = lshift (k, 1)
		m = m + 1
	end
	return k, m
end

local base_cache_size

if generation_radius > 1 then
	base_cache_size = generation_radius
else
	local chunk_check_size
		= mt_chunksize + (REQUIRED_CONTEXT_XZ + 1) * 2
	base_cache_size = mathmax (6, chunk_check_size)
end

local player_block_positions = {}
local n_player_block_positions

local function dist_to_nearest_player (x, y, z)
	local d = huge
	local n = n_player_block_positions
	local p = player_block_positions
	for i = 1, n, 3 do
		local x1, y1, z1 = p[i], p[i + 1], p[i + 2]
		local dx = x - x1
		local dy = y - y1
		local dz = z - z1
		d = mathmin (d, dx * dx + dy * dy + dz * dz)
	end
	return d
end

local function refresh_player_block_positions ()
	player_block_positions = {}
	for player in mcl_util.connected_players () do
		local pos = mcl_util.get_nodepos (player:get_pos ())
		local x = floor (pos.x / 16)
		local y = floor (pos.y / 16)
		local z = floor (pos.z / 16)
		table.insert (player_block_positions, x)
		table.insert (player_block_positions, y)
		table.insert (player_block_positions, z)
	end
	n_player_block_positions = #player_block_positions
end

local mbs_cache = { }
local mbs_cache_width, mbs_cache_shift_base
	= nearest_power_of_2 ((base_cache_size
			       + REQUIRED_CONTEXT_XZ + 1) * 2 + 1)
local mbs_cache_shift_x = mbs_cache_shift_base + HEIGHT_SHIFT

local mbs_cache_min_x
local mbs_cache_min_y
local mbs_cache_min_z

local function local_set_mapblock_state (x, y, z, state)
	set_mapblock_state (x, y, z, state)
	local ix = x - mbs_cache_min_x
	local iy = y - mbs_cache_min_y
	local iz = z - mbs_cache_min_z
	-- assert (ix >= 0 and iy >= 0 and iz >= 0
	-- 	and ix < mbs_cache_width
	-- 	and iy < HEIGHT
	-- 	and iz < mbs_cache_width)
	local hash = bor (lshift (ix, mbs_cache_shift_x),
			  lshift (iz, HEIGHT_SHIFT), iy) + 1
	mbs_cache[hash] = state
end

local function local_mapblock_state (x, y, z)
	local ix = x - mbs_cache_min_x
	local iy = y - mbs_cache_min_y
	local iz = z - mbs_cache_min_z
	-- assert (ix >= 0 and iy >= 0 and iz >= 0
	-- 	and ix < mbs_cache_width
	-- 	and iy < HEIGHT
	-- 	and iz < mbs_cache_width)
	local hash = bor (lshift (ix, mbs_cache_shift_x),
			  lshift (iz, HEIGHT_SHIFT), iy) + 1
	local k = mbs_cache[hash]
	if k then
		return k
	end
	k = mapblock_state (x, y, z)
	mbs_cache[hash] = k
	return k
end

local function clear_mbs_cache (width)
	local nelem = width * HEIGHT * width
	for i = 1, nelem do
		mbs_cache[i] = false
	end
end

local surroundings = {
}

for x = -REQUIRED_CONTEXT_XZ - 1, REQUIRED_CONTEXT_XZ + 1 do
	for z = -REQUIRED_CONTEXT_XZ - 1, REQUIRED_CONTEXT_XZ + 1 do
		if mathabs (x) > REQUIRED_CONTEXT_XZ
			or mathabs (z) > REQUIRED_CONTEXT_XZ then
			table.insert (surroundings, x)
			table.insert (surroundings, z)
		end
	end
end

local all_surroundings = {
}

for x = -REQUIRED_CONTEXT_XZ - 1, REQUIRED_CONTEXT_XZ + 1 do
	for z = -REQUIRED_CONTEXT_XZ - 1, REQUIRED_CONTEXT_XZ + 1 do
		table.insert (all_surroundings, x)
		table.insert (all_surroundings, z)
	end
end

local n_surroundings = #surroundings
local n_all_surroundings = #all_surroundings

local function vertical_context_generated (x, y, z)
	if y > OVERWORLD_MAX_BLOCK or y < OVERWORLD_MIN_BLOCK then
		return true
	end
	-- for x = x - REQUIRED_CONTEXT_XZ - 1, x + REQUIRED_CONTEXT_XZ + 1 do
	-- 	for z = z - REQUIRED_CONTEXT_XZ - 1, z + REQUIRED_CONTEXT_XZ + 1 do
	-- 		if local_mapblock_state (x, y, z) == MBS_UNKNOWN then
	-- 			return false
	-- 		end
	-- 	end
	-- end
	for i = 1, n_all_surroundings, 2 do
		local dx = all_surroundings[i]
		local dz = all_surroundings[i + 1]
		if local_mapblock_state (x + dx, y, z + dz) == MBS_UNKNOWN then
			return false
		end
	end
	return true
end

local function adequate_context_exists_p (x, y, z, curstate)
	for x = x - REQUIRED_CONTEXT_XZ, x + REQUIRED_CONTEXT_XZ do
		for z = z - REQUIRED_CONTEXT_XZ, z + REQUIRED_CONTEXT_XZ do
			if local_mapblock_state (x, y, z) < MBS_PROTO_CHUNK
				or not test_block_status (x, y, z) then
				return false
			end
		end
	end

	if curstate == MBS_GENERATED then
		-- A MapBlock can't have been generated unless its
		-- surroundings were previously.
		return true
	end

	-- Verify that a further MapBlock's margin around the context
	-- itself has been generated, or subsequent level generation
	-- may overwrite any data that is written into the context.
	for i = 1, n_surroundings, 2 do
		local x = x + surroundings[i]
		local z = z + surroundings[i + 1]
		if local_mapblock_state (x, y, z) == MBS_UNKNOWN then
			return false
		end
	end

	return vertical_context_generated (x, y + 1, z)
		and vertical_context_generated (x, y - 1, z)
end

-- local mapblock_lockers = {}
-- local function whohasit (x, y, z)
-- 	return mapblock_lockers[core.hash_node_position (vector.new (x, y, z))]
-- end
-- local function record_whohasit (x, y, z, run)
-- 	mapblock_lockers[core.hash_node_position (vector.new (x, y, z))] = run
-- end

local function queue_mapblock_run (x, y_start, y_end, z, d, supplemental,
				   data)
	local run = getmapblock (x, y_start, z)

	run.x = x
	run.z = z
	run.y1 = y_start
	run.y2 = y_end
	run.supplemental = supplemental
	run.data = data
	dbg ("Queueing mapblock run: X: %d, Y: %d - %d, Z: %d (supplemental: %s)",
	     x, y_start, y_end, z, tostring (supplemental))

	-- Lock surrounding MapBlocks.
	local context_start = mathmax (y_start - REQUIRED_CONTEXT_Y,
				       OVERWORLD_MIN_BLOCK)
	local context_end = mathmin (y_end + REQUIRED_CONTEXT_Y,
				     OVERWORLD_MAX_BLOCK)
	for x = x - REQUIRED_CONTEXT_XZ, x + REQUIRED_CONTEXT_XZ do
		for z = z - REQUIRED_CONTEXT_XZ, z + REQUIRED_CONTEXT_XZ do
			for y = context_start, context_end do
				local rec = mb_records[hashmapblock (x, y, z)]
				assert (not rec or rec == run)
				local state = local_mapblock_state (x, y, z)
				if state == MBS_PROTO_CHUNK then
					local_set_mapblock_state (x, y, z, MBS_LOCKED)
					-- record_whohasit (x, y, z, run)
				elseif state == MBS_GENERATED then
					local_set_mapblock_state (x, y, z, MBS_LOCKED_GENERATED)
					-- record_whohasit (x, y, z, run)
				else
					-- dbg ("MapBlock conflict: ", x, y, z,
					--        dump (run),
					--        dump (whohasit (x, y, z)))
					assert (false)
				end
			end
		end
	end

	-- Enqueue this run of MapBlocks; its state should be updated
	-- to MBS_GENERATED unless it is a supplemental run.
	for y = y_start, y_end do
		if not supplemental then
			assert (local_mapblock_state (x, y, z) == MBS_LOCKED)
			local_set_mapblock_state (x, y, z, MBS_REGENERATING)
		else
			assert (local_mapblock_state (x, y, z) == MBS_LOCKED_GENERATED
				or local_mapblock_state (x, y, z) == MBS_LOCKED)
		end
	end
	feature_placement_queue:enqueue (run, d)
	-- dbg ("  --> Feature placement queue: " .. dump (feature_placement_queue))
end

local function maybe_reprioritize (d, x, y, z)
	local hash = hashmapblock (x, y, z)
	local value = mb_records[hash]

	if value and value.idx and not value.penalized then
		-- Increase the priority if appropriate.
		if d + 16 < value.priority then
			dbg ("Reprioritizing X: %d, Y: %d - %d, Z: %d from %d -> %d",
			     value.x, value.y1, value.y2, value.z, value.priority, d)
			feature_placement_queue:update (value, d)
		end
	end
end

function attempt_feature_placement (x, z)
	local sx, sz = section (x, z)
	local hash = section_hash (sx, sz)
	section_access_times[hash] = 0

	-- Search for MapBlocks with valid and loaded context from
	-- the bottom to the top of the map.
	local cnt_below, last_above = 0, -huge
	local runs = {}
	local lastrun, nextrun = huge, -huge

	for y = OVERWORLD_MIN_BLOCK, OVERWORLD_MAX_BLOCK do
		if y > last_above then
			for i = y, OVERWORLD_MAX_BLOCK do
				if adequate_context_exists_p (x, i, z) then
					last_above = i
				else
					break
				end
			end
		end

		local curstate = local_mapblock_state (x, y, z)
		local context_adequate
			= adequate_context_exists_p (x, y, z, curstate)
		local d = dist_to_nearest_player (x, y, z)

		if curstate == MBS_PROTO_CHUNK and context_adequate then
			local min = mathmax (-(y - OVERWORLD_MIN_BLOCK - 2), 0)
			local max = mathmax (-(OVERWORLD_MAX_BLOCK - y - 2), 0)
			local required_below = REQUIRED_CONTEXT_Y - min
			local required_above = REQUIRED_CONTEXT_Y - max
			local cnt_above = last_above - y

			if cnt_below >= required_below
				and cnt_above >= required_above
			-- Do not permit subsequent runs to be
			-- enqueued if their context would overlap
			-- this one's.
				and (y == lastrun + 1
				     or y > nextrun + REQUIRED_CONTEXT_Y) then
				table.insert (runs, y)
				table.insert (runs, d)
				lastrun = y
				nextrun = y + REQUIRED_CONTEXT_Y
			end
		end

		if context_adequate then
			cnt_below = cnt_below + 1
		else
			cnt_below = 0
		end

		maybe_reprioritize (d, x, y, z)
	end

	if #runs > 0 then
		-- Enqueue runs in reverse.
		local min_d = huge
		local prev_y = nil
		local last_y = nil

		for i = #runs, 1, -2 do
			local d = runs[i]
			local y = runs[i - 1]

			if y + 1 ~= last_y and prev_y then
				queue_mapblock_run (x, last_y, prev_y, z,
						    mathmin (d, min_d),
						    false, nil)
				prev_y = y
				min_d = d
			elseif not prev_y then
				prev_y = y
				min_d = d
			else
				min_d = mathmin (d, min_d)
			end

			last_y = y
		end
		local y_initial = runs[1]
		local d_initial = runs[2]
		queue_mapblock_run (x, y_initial, prev_y, z,
				    mathmin (min_d, d_initial),
				    false, nil)
	end
end

local REGENERATION_QUOTA_US = 8000

if mcl_levelgen.load_feature_environment then
	-- This global variable holds the last VM to be supplied to
	-- async_function.  It exists as, for reasons that ought to
	-- require no explanation, a VM cannot be closed before the
	-- function returns.
	levelgen_previous_vm = nil
end

local function async_function (vm, run, heightmap, wg_heightmap, biomes)
	if levelgen_previous_vm and levelgen_previous_vm.close then
		levelgen_previous_vm:close ()
	end
	-- These constants must be redundantly defined within this
	-- function, as constants in upvalues are not transferred to
	-- the async environment.
	local OVERWORLD_OFFSET = mcl_levelgen.OVERWORLD_OFFSET
	local preset = mcl_levelgen.overworld_preset
	local relight_list, gen_notifies, fluids_to_transform, features, c_above, c_below
		= mcl_levelgen.process_features (vm, run, heightmap, wg_heightmap,
						 biomes, OVERWORLD_OFFSET, preset.min_y,
						 preset.height, preset)
	levelgen_previous_vm = vm
	return vm, run, heightmap, relight_list, gen_notifies,
		fluids_to_transform, features, c_above, c_below
end

local v1 = vector.zero ()
local v2 = vector.zero ()
local warned = {}
local registered_notification_handlers = {}
mcl_levelgen.registered_notification_handlers
	= registered_notification_handlers

local apply_heightmap_modifications
local schedule_regeneration_for_unlock
local apply_feature_context_requisitions

local function run_execution_cb (vm, run, heightmap, relight_queue, gen_notifies,
				 fluids_to_transform,
				 features_requesting_additional_context,
				 c_above, c_below)
	if shutdown_complete then
		vm:close ()
		return
	end

	-- It appears that this calback is occasionally called oftener
	-- than once.
	local run_hash = hashmapblock (run.x, run.y1, run.z)
	if not mb_records[run_hash] then
		dbg ("A MapBlock execution task completed twice: X: %d, Y: %d - %d, Z: %d",
		     run.x, run.y1, run.y2, run.z)
		return
	end
	mb_records[run_hash] = nil

	vm:write_to_map (false)
	-- 5.13.0 only API.
	if vm.close then
		vm:close ()
	end

	-- Unlock all MapBlocks that were locked for the duration of
	-- this run.
	local y_min = mathmax (run.y1 - REQUIRED_CONTEXT_Y,
			       OVERWORLD_MIN_BLOCK)
	local y_max = mathmin (run.y2 + REQUIRED_CONTEXT_Y,
			       OVERWORLD_MAX_BLOCK)
	local supplemental = run.supplemental

	dbg ("Completed MapBlock run: X: %d, Y: %d - %d, Z: %d",
	     run.x, run.y1, run.y2, run.z)

	for x, y, z in ipos1 (run.x - REQUIRED_CONTEXT_XZ, y_min,
			      run.z - REQUIRED_CONTEXT_XZ,
			      run.x + REQUIRED_CONTEXT_XZ, y_max,
			      run.z + REQUIRED_CONTEXT_XZ) do
		if (x == run.x and y >= run.y1 and y <= run.y2 and z == run.z)
			and not supplemental then
			local state = mapblock_state (x, y, z)
			assert (state == MBS_REGENERATING)
			set_mapblock_state (x, y, z, MBS_GENERATED)
		else
			local state = mapblock_state (x, y, z)
			if state == MBS_LOCKED then
				set_mapblock_state (x, y, z, MBS_PROTO_CHUNK)
			elseif state == MBS_LOCKED_GENERATED then
				set_mapblock_state (x, y, z, MBS_GENERATED)
			else
				dbg ("MapBlock execution inconsistency detected: ")
				dbg ("  From X: %d, Y: %d - %d, Z: %d (supplemental: %s)",
				     run.x, run.y1, run.y2, run.z, tostring (run.supplemental))
				dbg ("  X: %d, Y: %d, Z: %d is %d rather than L or G",
				     x, y, z, state)
				assert (false)
			end
		end
	end

	if heightmap then
		apply_heightmap_modifications (run, heightmap)
	end

	-- local time = core.get_us_time ()
	for _, rgn in ipairs (relight_queue) do
		v1.x, v1.y, v1.z = rgn[1], rgn[2], rgn[3]
		v2.x, v2.y, v2.z = rgn[4], rgn[5], rgn[6]
		core.fix_light (v1, v2)
	end
	-- print (string.format ("%.2f", (core.get_us_time () - time) / 1000))

	for _, notify in ipairs (gen_notifies) do
		local name = notify.name
		local handler = registered_notification_handlers[name]
		if not handler and not warned[name] then
			warned[name] = true
			core.log ("warning", "Invoking unknown feature generation handler: " .. name)
		elseif handler then
			handler (notify.name, notify.data)
		end
	end

	-- Queue all fluids that were marked for transformation.
	for i = 1, #fluids_to_transform, 3 do
		local x = fluids_to_transform[i]
		local y = fluids_to_transform[i + 1]
		local z = fluids_to_transform[i + 2]
		v1.x, v1.y, v1.z = x, y, z
		core.transforming_liquid_add (v1)
	end

	apply_feature_context_requisitions (run, features_requesting_additional_context,
					    c_above, c_below)
	schedule_regeneration_for_unlock (run.x, run.z)
end

local function cancel_mapblock_run (run, y_min, y_max)
	local run_hash = hashmapblock (run.x, run.y1, run.z)
	assert (mb_records[run_hash] == run)

	for x, y, z in ipos1 (run.x - REQUIRED_CONTEXT_XZ, y_min,
			      run.z - REQUIRED_CONTEXT_XZ,
			      run.x + REQUIRED_CONTEXT_XZ, y_max,
			      run.z + REQUIRED_CONTEXT_XZ) do
		local state = mapblock_state (x, y, z)
		assert (state == MBS_LOCKED
			or state == MBS_LOCKED_GENERATED
			or state == MBS_REGENERATING)

		if state == MBS_LOCKED then
			set_mapblock_state (x, y, z, MBS_PROTO_CHUNK)
		elseif state == MBS_LOCKED_GENERATED then
			set_mapblock_state (x, y, z, MBS_GENERATED)
		elseif state == MBS_REGENERATING then
			set_mapblock_state (x, y, z, MBS_PROTO_CHUNK)
		end
	end
	mb_records[run_hash] = nil
end

local function resume_mapblock_run (run)
	local run_hash = hashmapblock (run.x, run.y1, run.z)
	local ymin = mathmax (OVERWORLD_MIN_BLOCK,
			      run.y1 - REQUIRED_CONTEXT_Y)
	local ymax = mathmin (OVERWORLD_MAX_BLOCK,
			      run.y2 + REQUIRED_CONTEXT_Y)

	for x, y, z in ipos1 (run.x - REQUIRED_CONTEXT_XZ, ymin,
			      run.z - REQUIRED_CONTEXT_XZ,
			      run.x + REQUIRED_CONTEXT_XZ, ymax,
			      run.z + REQUIRED_CONTEXT_XZ) do
		local state = mapblock_state (x, y, z)
		assert (state == MBS_PROTO_CHUNK or state == MBS_GENERATED)

		if state == MBS_PROTO_CHUNK then
			set_mapblock_state (x, y, z, MBS_LOCKED)
		elseif state == MBS_GENERATED then
			set_mapblock_state (x, y, z, MBS_LOCKED_GENERATED)
		end
	end

	local x = run.x
	local z = run.z
	for y = run.y1, run.y2 do
		set_mapblock_state (x, y, z, MBS_REGENERATING)
	end
	mb_records[run_hash] = run
end

local construct_heightmaps_for_run
local biome_data_for_run

local v = vector.zero ()

local function post_mapblock_run (run)
	dbg ("Issuing MapBlock run: X: %d, Y: %d - %d, Z: %d", run.x,
	     run.y1, run.y2, run.z)

	v1.x = (run.x - REQUIRED_CONTEXT_XZ) * 16
	v1.z = (run.z - REQUIRED_CONTEXT_XZ) * 16
	v1.y = (run.y1 - REQUIRED_CONTEXT_Y) * 16
	v2.x = (run.x + REQUIRED_CONTEXT_XZ) * 16 + 15
	v2.z = (run.z + REQUIRED_CONTEXT_XZ) * 16 + 15
	v2.y = (run.y2 + REQUIRED_CONTEXT_Y) * 16 + 15

	local y_min = mathmax (run.y1 - REQUIRED_CONTEXT_Y,
			       OVERWORLD_MIN_BLOCK)
	local y_max = mathmin (run.y2 + REQUIRED_CONTEXT_Y,
			       OVERWORLD_MAX_BLOCK)

	for x, y, z in ipos2 (run.x - REQUIRED_CONTEXT_XZ, y_min,
			      run.z - REQUIRED_CONTEXT_XZ,
			      run.x + REQUIRED_CONTEXT_XZ, y_max,
			      run.z + REQUIRED_CONTEXT_XZ) do
		-- Verify that the context of the run is consistent,
		-- and abandon it if it has since been unloaded.
		local state = mapblock_state (x, y, z)
		if not (state == MBS_LOCKED
			or state == MBS_LOCKED_GENERATED
			or state == MBS_REGENERATING) then
			local blurb = "  Inconsistency detected: X: %d, Y: %d, Z: %d is %d, not locked"
			dbg (blurb, x, y, z, state)
			assert (false)
		end

		-- This condition cannot trigger if
		-- generation_radius == 1.
		if not test_block_status (x, y, z) then
			cancel_mapblock_run (run, y_min, y_max)
			return
		end
	end

	local heightmap, wg_heightmap
		= construct_heightmaps_for_run (run)
	local biomes = biome_data_for_run (run)
	local vm = VoxelManip (v1, v2)
	core.handle_async (async_function, run_execution_cb, vm, run,
			   heightmap, wg_heightmap, biomes)
	if vm.close then
		vm:close ()
	end

	-- mb_records will continue to hold `run' until such time as
	-- it completely processed as a further test of consistency.
	local run_hash = hashmapblock (run.x, run.y1, run.z)
	assert (mb_records[run_hash] == run)
end

local timer = 0

local function schedule_regeneration_per_player (generation_radius)
	-- Iterate over mapblocks in a circular pattern from the
	-- position of each player.  Enroll them in the regeneration
	-- queue subject to their distance to the nearest player and
	-- the quantity of generation context available.  Dispatch the
	-- generation queue.

	-- local clock = core.get_us_time ()

	refresh_player_block_positions ()
	local p = player_block_positions
	for i = 1, n_player_block_positions, 3 do
		local x, y, z = p[i], p[i + 1], p[i + 2]

		mbs_cache_min_x = x - generation_radius - 3
		mbs_cache_min_y = OVERWORLD_MIN_BLOCK
		mbs_cache_min_z = z - generation_radius - 3
		clear_mbs_cache (mbs_cache_width)

		player_x, player_y, player_z = x, y, z
		attempt_feature_placement (x, z)

		local cnt = 2
		for i = 1, generation_radius do
			local xstart = x - i
			local zstart = z + i
			local x_start, z_start = xstart, zstart

			-- Clockwise X.
			for x1 = 0, cnt - 1 do
				attempt_feature_placement (x_start + x1, z_start)
			end
			x_start = x_start + cnt

			-- Clockwise Z.
			for z1 = 0, cnt - 1 do
				attempt_feature_placement (x_start, z_start - z1)
			end
			z_start = z_start - cnt

			-- Clockwise X.
			for x1 = 0, cnt - 1 do
				attempt_feature_placement (x_start - x1, z_start)
			end
			x_start = x_start - cnt
			assert (x_start == xstart)

			-- Clockwise Z.
			for z1 = 0, cnt - 1 do
				attempt_feature_placement (x_start, z_start + z1)
			end
			z_start = z_start + cnt
			assert (z_start == zstart)

			cnt = cnt + 2
		end
	end
end

mcl_levelgen.schedule_regeneration_per_player = schedule_regeneration_per_player

local check_supplemental_generation

function schedule_regeneration_for_emerge (bx, bx1, by, by1, bz, bz1)
	refresh_player_block_positions ()
	-- Each MapBlock is capable of influencing the generation of
	-- other blocks within two blocks of itself on either axis,
	-- the one as context and the other by reason of being
	-- generated.
	mbs_cache_min_x = bx - REQUIRED_CONTEXT_XZ - 3
	mbs_cache_min_y = OVERWORLD_MIN_BLOCK
	mbs_cache_min_z = bz - REQUIRED_CONTEXT_XZ - 3
	clear_mbs_cache (mbs_cache_width)
	for bx, by, bz in ipos2 (bx - REQUIRED_CONTEXT_XZ - 1,
				 by,
				 bz - REQUIRED_CONTEXT_XZ - 1,
				 bx1 + REQUIRED_CONTEXT_XZ + 1,
				 by,
				 bz1 + REQUIRED_CONTEXT_XZ + 1) do
		check_supplemental_generation (bx, bz)
		if generation_radius == 1 then
			attempt_feature_placement (bx, bz)
		end
	end
end

function schedule_regeneration_for_unlock (bx, bz)
	refresh_player_block_positions ()
	mbs_cache_min_x = bx - REQUIRED_CONTEXT_XZ - 3
	mbs_cache_min_y = OVERWORLD_MIN_BLOCK
	mbs_cache_min_z = bz - REQUIRED_CONTEXT_XZ - 3
	clear_mbs_cache (mbs_cache_width)
	for bx, by, bz in ipos2 (bx - REQUIRED_CONTEXT_XZ - 1,
				 0,
				 bz - REQUIRED_CONTEXT_XZ - 1,
				 bx + REQUIRED_CONTEXT_XZ + 1,
				 0,
				 bz + REQUIRED_CONTEXT_XZ + 1) do
		check_supplemental_generation (bx, bz)
		if generation_radius == 1 then
			attempt_feature_placement (bx, bz)
		end
	end
end

local function schedule_regeneration (dtime)
	timer = timer + dtime
	if timer < 0.10 then
		return
	end
	timer = 0

	if generation_radius > 1 then
		schedule_regeneration_per_player (generation_radius)
	end

	-- print (string.format ("%.2f", (core.get_us_time () - clock) / 1000))

	local start_time = core.get_us_time ()
	repeat
		if feature_placement_queue:empty () then
			return
		end

		-- Begin dispatching VoxelManips to async threads.
		local run = feature_placement_queue:dequeue ()
		post_mapblock_run (run)
	until core.get_us_time () - start_time >= REGENERATION_QUOTA_US

	-- block_status_cache.loaded = {}
	-- ncalls = 0
end

local additional_ctx_requisitions = {}

local function save_feature_placement_queue ()
	if generation_radius == 1 then
		-- Cancel every run that is currently in progress by
		-- returning it to the feature placement queue.
		for hash, run in pairs (mb_records) do
			if not feature_placement_queue:contains (run) then
				-- This run must have existed
				-- previously.  Assign it its old
				-- priority.
				assert (run and run.priority)
				feature_placement_queue:enqueue (run, run.priority)
			end
		end
		mb_records = {}

		local sdata = core.serialize (feature_placement_queue)
		storage:set_string ("feature_placement_queue", sdata)

		local sdata = core.serialize (additional_ctx_requisitions)
		storage:set_string ("additional_ctx_requisitions", sdata)

		-- At this point, the state of the level generator has
		-- been saved to disk and any extant tasks which might
		-- still complete should be disregarded.
		shutdown_complete = true
	else
		storage:set_string ("feature_placement_queue", "")
	end
end

local function restore_feature_placement_queue ()
	if generation_radius == 1 then
		local sdata = storage:get_string ("feature_placement_queue")
		if sdata ~= nil and sdata ~= "" then
			local queue = core.deserialize (sdata)
			if queue then
				setmetatable (queue, mintree_meta)

				if queue.size > 0 then
					local blurb = "[mcl_levelgen]: Resuming %d feature placement tasks"
					core.log ("action", string.format (blurb, queue.size))
					feature_placement_queue = queue

					for i = 1, queue.size do
						resume_mapblock_run (queue.heap[i])
					end
				end
			end
		end

		local sdata = storage:get_string ("additional_ctx_requisitions")
		if sdata ~= nil and sdata ~= "" then
			local n = 0
			local additional_ctx_requisitions = core.deserialize (sdata)
			for k, req in ipairs (additional_ctx_requisitions) do
				v1.x = (req.x - REQUIRED_CONTEXT_XZ - 1) * 16
				v1.z = (req.z - REQUIRED_CONTEXT_XZ - 1) * 16
				v1.y = req.min
				v2.x = (req.x + REQUIRED_CONTEXT_XZ + 1) * 16 + 15
				v2.z = (req.z + REQUIRED_CONTEXT_XZ + 1) * 16 + 15
				v2.y = req.max
				core.emerge_area (v1, v2)
				n = n + 1
			end
			local blurb = "[mcl_levelgen]: Replayed %d placement run requisitions"
			if n > 1 then
				core.log ("action", string.format (blurb, n))
			end
		end
	end
end

if not mcl_levelgen.load_feature_environment then
	core.register_globalstep (schedule_regeneration)
	core.register_on_shutdown (save_feature_placement_queue)
	restore_feature_placement_queue ()
end

------------------------------------------------------------------------
-- Supplemental generation.  This facility enables features with
-- immense vertical context requirements to request execution in an
-- isolated environment with additional context, subject to certain
-- handicaps documented in API.txt.
------------------------------------------------------------------------

-- local function supplemental_context_cb (run)
-- 	dbg ("Supplemental context is available for run: %s", dump (run))
-- end

function apply_feature_context_requisitions (run, features_requesting_additional_context,
					     above, below)
	if not (above > 0 or below > 0) then
		return nil
	end

	dbg ("Supplemental context requested by run: X: %d, Y: %d - %d, Z: %d: %d, %d",
	     run.x, run.y1, run.y2, run.z, above, below)

	local hash = hashmapblock (run.x, 0, run.z)
	local existing = additional_ctx_requisitions[hash] or {
		min = run.y1 * 16,
		max = run.y2 * 16 + 15,
		x = run.x,
		z = run.z,
		features = {},
	}
	additional_ctx_requisitions[hash] = existing
	existing.min = mathmax (mathmin (existing.min, run.y1 * 16 - below),
				OVERWORLD_MIN)
	existing.max = mathmin (mathmax (existing.max, run.y2 * 16 + 15 + above),
				OVERWORLD_MAX_BLOCK * 16)
	for _, feature in ipairs (features_requesting_additional_context) do
		if table.indexof (existing.features, feature) == -1 then
			table.insert (existing.features, feature)
		end
	end
	v1.x = (run.x - REQUIRED_CONTEXT_XZ - 1) * 16
	v1.z = (run.z - REQUIRED_CONTEXT_XZ - 1) * 16
	v1.y = existing.min
	v2.x = (run.x + REQUIRED_CONTEXT_XZ + 1) * 16 + 15
	v2.z = (run.z + REQUIRED_CONTEXT_XZ + 1) * 16 + 15
	v2.y = existing.max
	core.emerge_area (v1, v2)
end

function check_supplemental_generation (bx, bz)
	local hash = hashmapblock (bx, 0, bz)
	local requirements = additional_ctx_requisitions[hash]
	if requirements then
		-- Are the requirements met?
		local y1 = floor (requirements.min / 16)
		local y2 = ceil (requirements.max / 16)

		local first_locked = mathmax (OVERWORLD_MIN_BLOCK,
					      y1 - REQUIRED_CONTEXT_Y)
		local last_locked = mathmax (OVERWORLD_MIN_BLOCK,
					     y2 + REQUIRED_CONTEXT_Y)

		for by = first_locked, last_locked do
			if not adequate_context_exists_p (bx, by, bz) then
				return
			end
		end

		dbg ("Supplemental context has appeared from %d to %d at %d,%d",
		     y1, y2, bx, bz)
		queue_mapblock_run (bx, y1, y2, bz, 0, true, requirements)

		-- If any further requirements should arrive in the
		-- interim, defer posting them till this run completes
		-- if they overlap.
		additional_ctx_requisitions[hash] = nil
	end
end

------------------------------------------------------------------------
-- Heightmap provisioning.
--
-- Each generated MapChunk provides a heightmap that continues to
-- exist indefinitely; they are recorded when a horizontal MapChunk is
-- first generated, and are identified by 31-bit IDs recorded in the
-- tagging data of the bottommost 8 MapBlocks of each horizontal
-- column.  Heightmaps are liable partially to be modified by
-- decoration placement.
------------------------------------------------------------------------

local loaded_heightmaps = {}
local heightmap_ttl = {}
local HEIGHTMAP_TTL = 20

local function load_heightmap (id)
	local tem = loaded_heightmaps[id]
	if tem then
		heightmap_ttl[id] = HEIGHTMAP_TTL
		return tem
	end

	-- print ("Loading heightmap " .. id)
	local data = storage:get_string ("heightmap" .. id)
	local str = core.decompress (data, "zstd")
	if data == "" or not str then
		error ("Could not satisfy heightmap request; Level is corrupt")
	end
	local fn, err = loadstring (str)
	if not fn then
		error (string.format ("Heightmap %d is corrupt: %s", id, err))
	end
	tem = fn ()
	heightmap_ttl[id] = HEIGHTMAP_TTL
	loaded_heightmaps[id] = tem
	return tem
end

local function mapblock_heightmap (x, z, worldgen)
	local w1 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK, z)
	local w2 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 1, z)
	local w3 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 2, z)
	local w4 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 3, z)
	local w5 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 4, z)
	local w6 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 5, z)
	local w7 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 6, z)
	local w8 = mapblock_flagbyte (x, OVERWORLD_MIN_BLOCK + 7, z)
	-- print ("<- ", band (rshift (w1, 3), 0xf),
	--        band (rshift (w2, 3), 0xf),
	--        band (rshift (w3, 3), 0xf),
	--        band (rshift (w4, 3), 0xf),
	--        band (rshift (w5, 3), 0xf),
	--        band (rshift (w6, 3), 0xf),
	--        band (rshift (w7, 3), 0xf),
	--        band (rshift (w8, 3), 0xf))
	local value = bor (band (rshift (w1, 3), 0xf),
			   lshift (band (rshift (w2, 3), 0xf), 4),
			   lshift (band (rshift (w3, 3), 0xf), 8),
			   lshift (band (rshift (w4, 3), 0xf), 12),
			   lshift (band (rshift (w5, 3), 0xf), 16),
			   lshift (band (rshift (w6, 3), 0xf), 20),
			   lshift (band (rshift (w7, 3), 0xf), 24),
			   lshift (band (rshift (w8, 3), 0xf), 28))
	if worldgen then
		return value ~= 0 and value + 1 or 0
	else
		return value
	end
end

local function set_mapblock_heightmap (x, z, id)
	local w1 = lshift (band (id, 0xf), 3)
	local w2 = lshift (band (rshift (id, 4), 0xf), 3)
	local w3 = lshift (band (rshift (id, 8), 0xf), 3)
	local w4 = lshift (band (rshift (id, 12), 0xf), 3)
	local w5 = lshift (band (rshift (id, 16), 0xf), 3)
	local w6 = lshift (band (rshift (id, 20), 0xf), 3)
	local w7 = lshift (band (rshift (id, 24), 0xf), 3)
	local w8 = lshift (band (rshift (id, 28), 0xf), 3)
	local sx, sz = section (x, z)
	local section = load_section (sx, sz)
	local i, bit, mask
	-- print ("-> ", rshift (w1, 3),
	--        rshift (w2, 3),
	--        rshift (w3, 3),
	--        rshift (w4, 3),
	--        rshift (w5, 3),
	--        rshift (w6, 3),
	--        rshift (w7, 3),
	--        rshift (w8, 3))

	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w1, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 1, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w2, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 2, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w3, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 3, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w4, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 4, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w5, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 5, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w6, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 6, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w7, bit))
	i, bit = mapblock_index_1 (x, OVERWORLD_MIN_BLOCK + 7, z)
	mask = bnot (lshift (0x78, bit)) -- 0x78 = (0xf << 3)
	section[i] = bor (band (section[i], mask), lshift (w8, bit))
	assert (mapblock_heightmap (x, z) == id)
end

local function allocate_heightmap_id ()
	-- It is not realistic for a level to overflow this counter.
	local heightmap_id
	-- Not 0x80000000 as heightmap IDs are offset by 1.
		= storage:get_int ("next_heightmap_id", 0) % 0x7fffffff
	storage:set_int ("next_heightmap_id", heightmap_id + 2)
	return heightmap_id + 1
end

local function write_heightmap (id, x, y, z, chunksize, data)
	local heightmap_data = table.concat ({
		"return {",
		string.format ("x=%d, y=%d, z=%d, chunksize=%d, data={",
			       x, y, z, chunksize),
		table.concat (data, ","),
		"}}",
	})
	local compressed = core.compress (heightmap_data, "zstd")
	storage:set_string ("heightmap" .. id, compressed)
end

local function copy_table (heightmap)
	local value = {}
	for i = 1, #heightmap do
		value[i] = heightmap[i]
	end
	return value
end

function save_heightmap (bx, bx1, by, by1, bz, bz1, chunksize)
	local custom = core.get_mapgen_object ("gennotify").custom
	if not custom then
		return
	end
	local data = custom["mcl_levelgen:level_height_map"]
	if not data then
		return
	end

	-- Verify the dimensions of this heightmap.
	local idx_max = chunksize * chunksize
	assert (#data == idx_max)
	local id = allocate_heightmap_id ()
	local used = false

	for x = bx, bx1 do
		for z = bz, bz1 do
			local heightmap = mapblock_heightmap (x, z, false)
			-- Retain the heightmap assignments of
			-- existing MapBlocks.
			if heightmap == 0 then
				-- But write a heightmap as soon as it
				-- is referenced by a MapBlock.
				if not used then
					used = true

					-- Heightmap is written twice;
					-- the second map is assigned
					-- an ID 1 MapBlock greater
					-- than the first, which is
					-- never altered and as such
					-- always represents the
					-- terrain of the world at the
					-- time of generation.
					write_heightmap (id, bx, by, bz, chunksize, data)
					loaded_heightmaps[id] = {
						x = bx,
						y = by,
						z = bz,
						chunksize = chunksize,
						data = data,
					}
					heightmap_ttl[id] = HEIGHTMAP_TTL
					write_heightmap (id + 1, bx, by, bz, chunksize, data)
					loaded_heightmaps[id + 1] = {
						x = bx,
						y = by,
						z = bz,
						chunksize = chunksize,
						data = copy_table (data),
					}
					heightmap_ttl[id + 1] = HEIGHTMAP_TTL
				end
				set_mapblock_heightmap (x, z, id)
			end
		end
	end
end

local function manage_heightmaps (dtime)
	for id, ttl in pairs (heightmap_ttl) do
		if ttl - dtime < 0 then
			heightmap_ttl[id] = nil
			local heightmap = loaded_heightmaps[id]
			assert (heightmap)
			-- print ("Writing heightmap " .. id)
			write_heightmap (id, heightmap.x,
					 heightmap.y, heightmap.z,
					 heightmap.chunksize,
					 heightmap.data)
			loaded_heightmaps[id] = nil
		else
			heightmap_ttl[id] = ttl - dtime
		end
	end
end

local function save_heightmaps ()
	for id, heightmap in pairs (loaded_heightmaps) do
		heightmap_ttl[id] = nil
		local heightmap = loaded_heightmaps[id]
		assert (heightmap)
		-- print ("Writing heightmap " .. id)
		write_heightmap (id, heightmap.x,
				 heightmap.y, heightmap.z,
				 heightmap.chunksize,
				 heightmap.data)
		loaded_heightmaps[id] = nil
	end
end

if not mcl_levelgen.load_feature_environment then
	core.register_globalstep (manage_heightmaps)
	core.register_on_shutdown (save_heightmaps)
end

local HEIGHTMAP_SIZE = REQUIRED_CONTEXT_XZ * 2 + 1
local HEIGHTMAP_SIZE_NODES = HEIGHTMAP_SIZE * 16
mcl_levelgen.HEIGHTMAP_SIZE = HEIGHTMAP_SIZE
mcl_levelgen.HEIGHTMAP_SIZE_NODES = HEIGHTMAP_SIZE_NODES

local function unpack_augmented_height_map (vals)
	-- Bit 31 indicates that the true value of `surface' is only
	-- known to be an indeterminate value between the value
	-- returned and the bottom of the level.  Bit 32 means the
	-- same of `motion_blocking'.

	local bias = 512
	local bits = 10
	local mask = 0x3ff
	local surface = band (rshift (vals, bits), mask) - bias
	local motion_blocking = band (vals, mask) - bias
	return surface, motion_blocking, rshift (vals, 30)
end

local SURFACE_UNCERTAIN = 0x1
local MOTION_BLOCKING_UNCERTAIN = 0x2

mcl_levelgen.unpack_augmented_height_map = unpack_augmented_height_map
mcl_levelgen.SURFACE_UNCERTAIN = SURFACE_UNCERTAIN
mcl_levelgen.MOTION_BLOCKING_UNCERTAIN = MOTION_BLOCKING_UNCERTAIN

local function copy_heightmap_segment (run, dst, wg, dx, dz)
	-- Transform output coordinates.
	local x = 16 + dx * 16
	local z = (HEIGHTMAP_SIZE - (2 + dz)) * 16

	-- Transform heightmap coordinates.
	local id = mapblock_heightmap (run.x + dx, run.z + dz, wg)
	local heightmap = load_heightmap (id)
	assert (run.x + dx >= heightmap.x)
	assert (run.z + dz >= heightmap.z)
	local cs = heightmap.chunksize
	local run_x = (run.x + dx) * 16
	local origin_x = run_x - (heightmap.x * 16)
	local run_z = (run.z + dz) * 16
	local origin_z = cs - (run_z - (heightmap.z * 16)) - 16

	-- Write transformed data into the destination heightmap.
	assert (origin_x >= 0 and origin_z >= 0
		and origin_x < chunksize
		and origin_z < chunksize)
	local idx_dst = x * HEIGHTMAP_SIZE_NODES + z + 1
	local idx_src = origin_x * cs + origin_z + 1
	local src = heightmap.data

	for x1 = 1, 16 do
		for i = 0, 15 do
			assert (src[idx_src + i])
			dst[idx_dst + i] = src[idx_src + i]
		end

		idx_dst = idx_dst + HEIGHTMAP_SIZE_NODES
		idx_src = idx_src + cs
	end
end

-- Create heightmaps REQUIRED_CONTEXT_XZ * 2 + 1 Minecraft chunks in
-- width and length for the run RUN, represented in the Minecraft
-- coordinate system.  Value is the heightmap representing the current
-- and potentially modified state of the level followed by that which
-- represents the state of the level at the time of generation.

function construct_heightmaps_for_run (run)
	local heightmap, wg_heightmap = {}, {}
	local expected_size = HEIGHTMAP_SIZE_NODES * HEIGHTMAP_SIZE_NODES
	heightmap[expected_size] = nil

	copy_heightmap_segment (run, heightmap, false, -1, -1)
	copy_heightmap_segment (run, heightmap, false, -1, 0)
	copy_heightmap_segment (run, heightmap, false, -1, 1)
	copy_heightmap_segment (run, heightmap, false, 0, -1)
	copy_heightmap_segment (run, heightmap, false, 0, 0)
	copy_heightmap_segment (run, heightmap, false, 0, 1)
	copy_heightmap_segment (run, heightmap, false, 1, -1)
	copy_heightmap_segment (run, heightmap, false, 1, 0)
	copy_heightmap_segment (run, heightmap, false, 1, 1)
	assert (#heightmap == expected_size)

	copy_heightmap_segment (run, wg_heightmap, true, -1, -1)
	copy_heightmap_segment (run, wg_heightmap, true, -1, 0)
	copy_heightmap_segment (run, wg_heightmap, true, -1, 1)
	copy_heightmap_segment (run, wg_heightmap, true, 0, -1)
	copy_heightmap_segment (run, wg_heightmap, true, 0, 0)
	copy_heightmap_segment (run, wg_heightmap, true, 0, 1)
	copy_heightmap_segment (run, wg_heightmap, true, 1, -1)
	copy_heightmap_segment (run, wg_heightmap, true, 1, 0)
	copy_heightmap_segment (run, wg_heightmap, true, 1, 1)
	assert (#wg_heightmap == expected_size)
	return heightmap, wg_heightmap
end

local function restore_heightmap_segment (run, src, dx, dz)
	-- Transform output coordinates.
	local x = 16 + dx * 16
	local z = (HEIGHTMAP_SIZE - (2 + dz)) * 16

	-- Transform heightmap coordinates.
	local id = mapblock_heightmap (run.x + dx, run.z + dz, false)
	local heightmap = load_heightmap (id)
	assert (run.x + dx >= heightmap.x)
	assert (run.z + dz >= heightmap.z)
	local cs = heightmap.chunksize
	local run_x = (run.x + dx) * 16
	local origin_x = run_x - (heightmap.x * 16)
	local run_z = (run.z + dz) * 16
	local origin_z = cs - (run_z - (heightmap.z * 16)) - 16

	-- Restore transformed data from the destination heightmap.
	local idx_dst = x * HEIGHTMAP_SIZE_NODES + z + 1
	local idx_src = origin_x * cs + origin_z + 1
	local dst = heightmap.data

	for x1 = 1, 16 do
		for i = 0, 15 do
			dst[idx_src + i] = src[idx_dst + i]
		end

		idx_dst = idx_dst + HEIGHTMAP_SIZE_NODES
		idx_src = idx_src + cs
	end
end

function apply_heightmap_modifications (run, result)
	restore_heightmap_segment (run, result, -1, -1)
	restore_heightmap_segment (run, result, -1, 0)
	restore_heightmap_segment (run, result, -1, 1)
	restore_heightmap_segment (run, result, 0, -1)
	restore_heightmap_segment (run, result, 0, 0)
	restore_heightmap_segment (run, result, 0, 1)
	restore_heightmap_segment (run, result, 1, -1)
	restore_heightmap_segment (run, result, 1, 0)
	restore_heightmap_segment (run, result, 1, 1)
end

------------------------------------------------------------------------
-- Biome provisioning.
------------------------------------------------------------------------

-- Return a table of every biome data string of a MapBlock in RUN
-- indexed by MapBlock hash including its context.  Coordinates in
-- this table are expected to be represented in Minetest's standard
-- coordinate system.

local get_biome_meta = mcl_levelgen.get_biome_meta

function biome_data_for_run (run, result)
	local data = {}
	local x1 = run.x - REQUIRED_CONTEXT_XZ
	local z1 = run.z - REQUIRED_CONTEXT_XZ
	local y1 = mathmax (run.y1 - REQUIRED_CONTEXT_Y,
			    OVERWORLD_MIN_BLOCK)
	local y2 = mathmin (run.y2 + REQUIRED_CONTEXT_Y,
			    OVERWORLD_MAX_BLOCK)

	for x = x1, x1 + 1 + REQUIRED_CONTEXT_XZ do
		for z = z1, z1 + 1 + REQUIRED_CONTEXT_XZ do
			for y = y1, y2 do
				local hash = hashmapblock (x, y, z)
				data[hash] = get_biome_meta (x, y, z)
				if not data[hash] then
					local err
						= string.format ("Biome metadata for MapBlock %d,%d,%d is unavailable",
								 x, y, z)
					core.log ("warning", err)

					local plains
						= mcl_levelgen.biome_name_to_id_map["TheVoid"]
					data[hash] = string.char (64)
						.. string.char (plains)
				end
			end
		end
	end
	return data
end

------------------------------------------------------------------------
-- Mapblock flag HUD.
------------------------------------------------------------------------

local huds = {}

local function get_status_string (bx, by, bz)
	v.x = bx * 16
	v.y = by * 16
	v.z = bz * 16
	local state = mapblock_state (bx, by, bz)
	if core.compare_block_status (v, "loaded") then
		if state == MBS_UNKNOWN then
			return "U "
		elseif state == MBS_PROTO_CHUNK then
			return "P "
		elseif state == MBS_LOCKED or state == MBS_LOCKED_GENERATED then
			return "L "
		elseif state == MBS_REGENERATING then
			return "R "
		elseif state == MBS_GENERATED then
			return "G "
		else
			return "! "
		end
	else
		if state == MBS_UNKNOWN then
			return "? "
		elseif state == MBS_PROTO_CHUNK then
			return "x "
		elseif state == MBS_LOCKED or state == MBS_LOCKED_GENERATED then
			return "l "
		elseif state == MBS_REGENERATING then
			return "r "
		elseif state == MBS_GENERATED then
			return "g "
		else
			return "? "
		end
	end
end

local template
	= "ID: %d; X: %d, Y: %d, Z: %d; CS: %d\nWORLD_SURFACE: %s%3d MOTION_BLOCKING: %s%3d"

local function debug_index_heightmap (heightmap, node_x, node_z)
	local cs = heightmap.chunksize
	local x = node_x - heightmap.x * 16
	local z = node_z - heightmap.z * 16
	local surface, motion_blocking, flags
		= unpack_augmented_height_map (heightmap.data[x * chunksize + (cs - z - 1) + 1])
	return surface, motion_blocking, flags
end

local function get_heightmap_string (x, z, self_pos, generation_only)
	local id = mapblock_heightmap (x, z, generation_only)
	if id == 0 then
		return " (none)"
	else
		local heightmap = load_heightmap (id)
		local surface, motion_blocking, flags
			= debug_index_heightmap (heightmap, self_pos.x,
						 self_pos.z)
		local surface_quals
			= band (flags, SURFACE_UNCERTAIN) ~= 0 and "?" or ""
		local motion_blocking_quals
			= band (flags, MOTION_BLOCKING_UNCERTAIN) ~= 0 and "?" or ""
		return string.format (template, id,
				      heightmap.x, heightmap.y, heightmap.z,
				      heightmap.chunksize,
				      surface_quals, surface,
				      motion_blocking_quals, motion_blocking)
	end
end

local function hud_text (player)
	local self_pos = mcl_util.get_nodepos (player:get_pos ())
	local x = floor (self_pos.x / 16)
	local y = floor (self_pos.y / 16)
	local z = floor (self_pos.z / 16)

	if y < OVERWORLD_MIN_BLOCK or y > OVERWORLD_MAX_BLOCK then
		return "Outside confines of level"
	end

	local tbl = {}
	for z1 = 12, -11, -1 do
		for x1 = -11, 12 do
			table.insert (tbl, get_status_string (x + x1, y, z + z1))
		end
		table.insert (tbl, "\n")
	end
	table.insert (tbl, string.format ("You: %d, %d, %d, %s\n", x, y, z,
					  get_status_string (x, y, z)))
	table.insert (tbl, string.format ("Heightmap: %s\n",
					  get_heightmap_string (x, z, self_pos, false)))
	table.insert (tbl, string.format ("Heightmap (Generation time): %s",
					  get_heightmap_string (x, z, self_pos, true)))
	return table.concat (tbl)
end

local function init_hud (player)
	local meta = player:get_meta ()
	meta:set_int ("mcl_levelgen:debug_hud_enabled", 1)
	huds[player] = player:hud_add ({
		type = "text",
		alignment = {
			x = 1,
			y = -1,
		},
		text = core.colorize ("#808080", hud_text (player)),
		style = 5,
		position = {x = 0.0073, y = 0.889},
	})
end

local function delete_hud (player)
	local meta = player:get_meta ()
	meta:set_int ("mcl_levelgen:debug_hud_enabled", 0)
	if huds[player] then
		player:hud_remove (huds[player])
		huds[player] = nil
	end
end

local function update_hud (player)
	local hud = huds[player]
	if hud then
		player:hud_change (hud, "text",
				   core.colorize ("#808080", hud_text (player)))
	end
end

if not mcl_levelgen.load_feature_environment then

mcl_player.register_globalstep_slow (update_hud)

core.register_chatcommand ("level_generation_status", {
	privs = { debug = true, },
	description = S ("Enable or disable the level generation HUD"),
	func = function (name, toggle)
		local player = core.get_player_by_name (name)
		if toggle == "on" then
			init_hud (player)
		elseif toggle == "off" then
			delete_hud (player)
		end
	end,
})

core.register_on_joinplayer (function (player)
	local meta = player:get_meta ()
	if meta:get_int ("mcl_levelgen:debug_hud_enabled", 0) == 1 then
		init_hud (player)
	end
end)

core.register_on_leaveplayer (function (player)
	huds[player] = nil
end)

------------------------------------------------------------------------
-- Scripting interface.
------------------------------------------------------------------------

function mcl_levelgen.register_notification_handler (name, handler)
	assert (type (name) == "string")
	registered_notification_handlers[name] = handler
end

------------------------------------------------------------------------
-- Async environment registration.
------------------------------------------------------------------------

core.register_async_dofile (mcl_levelgen.prefix .. "/init.lua")

end -- if not mcl_levelgen.load_feature_environment
