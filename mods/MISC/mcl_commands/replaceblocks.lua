local S = minetest.get_translator(minetest.get_current_modname())

local function is_bad_node_name(nodestring)
	local _stack = ItemStack(nodestring)
	local _miss = _stack:is_empty() or not minetest.registered_nodes[_stack:get_name()]
	_stack = nil
	return _miss
end

local function replaceblocks_callback(ctx, nn)
	for i=1,#nn do
		ctx.current_blocks = ctx.current_blocks + 1
		if not nn[i] then
			goto next
		end

		local node = minetest.get_node_or_nil(nn[i])
		if not node then
			-- missing block?
			goto next
		end

		if minetest.is_protected(nn[i], ctx.requestor_name) and not ctx.force_replace then
			ctx.unchanged_blocks = ctx.unchanged_blocks + 1
			-- excessive?
			-- minetest.record_protection_violation(nn[i], ctx.requestor_name)
			goto next
		end

	--	minetest.set_node(nn[i], {name=ctx.new_nodestring})
		minetest.after(0.001, minetest.set_node, nn[i], {name=ctx.new_nodestring})
		ctx.replaced_blocks = ctx.replaced_blocks + 1

		::next::
	end

	minetest.chat_send_player(ctx.requestor_name,
		S("Finished replacing blocks in @1ms: @2 replaced, @3 unchanged, @4 total.",
			string.format("%.2f", (os.clock() - ctx.start_time) * 1000),
			ctx.replaced_blocks, ctx.unchanged_blocks, ctx.total_blocks)
		)
end

local function replaceblocks_progress_update(ctx)
	if ctx.current_blocks == ctx.total_blocks then
		return
	end

	minetest.chat_send_player(ctx.requestor_name,
		S("replaceblocks update: @1/@2 blocks processed (@3%)",
		ctx.current_blocks, ctx.total_blocks,
		string.format("%.1f", (ctx.current_blocks / ctx.total_blocks) * 100)))

	minetest.after(2, replaceblocks_progress_update, ctx)
end

minetest.register_chatcommand("replaceblocks", {
	params = S("<old node> <new node> (here [<radius>]) | (<pos1> <pos2>)"),
	description = S("Replace existing map blocks contained in area (<pos1> and <pos2> must be in parentheses)"),
	privs = {give=true, interact=true},
	func = function(name, param)
		local params = {}
		for w in param:gmatch("%S+") do
			table.insert(params, w)
		end

		if table.getn(params) < 3 then
			return false, S("Not enough arguments (see /help replaceblocks)")
		end

		if is_bad_node_name(params[1]) then
			return false, S("Invalid old node definition")
		end

		if is_bad_node_name(params[2]) then
			return false, S("Invalid new node definition")
		end

		local p1, p2
		if params[3] == "here" then
			p1, p2 = minetest.get_player_radius_area(name, tonumber(params[4]))
			if p1 == nil then
				return false, S("Unable to get position of player @1.", name)
			end
		else
			if table.getn(params) < 4 then
				return false, S("Not enough arguments (see /help replaceblocks)")
			end
	
			local player = minetest.get_player_by_name(name)
			local relpos
			if player then
				relpos = player:get_pos()
			end
			p1, p2 = minetest.string_to_area(params[3] .. " " .. params[4], relpos)
			if p1 == nil or p2 == nil then
				return false, S("Incorrect area format. Expected: (x1,y1,z1) (x2,y2,z2)")
			end
		end

		local privs = minetest.get_player_privs(name)
		local nn = minetest.find_nodes_in_area(p1, p2, { params[1] })
		local context = {
			replaced_blocks  = 0,
			unchanged_blocks = 0,
			current_blocks   = 0,
			total_blocks     = #nn,
			start_time       = os.clock(),
			new_nodestring   = params[2],
			force_replace    = privs.server or privs.maphack or privs.protection_bypass,
			requestor_name   = name
		}

		minetest.after(0.001, replaceblocks_callback, context, nn)
		minetest.after(2, replaceblocks_progress_update, context)

		return true, S("Started replace of map blocks in area ranging from @1 to @2.",
			minetest.pos_to_string(p1, 1), minetest.pos_to_string(p2, 1))
	end,
})
