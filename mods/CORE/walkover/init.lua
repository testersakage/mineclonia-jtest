-- register extra flavours of a base nodedef
walkover = {}

local on_walk = {}
local on_entity_inside = {}
local registered_globals = {}

walkover.registered_globals = registered_globals

function walkover.register_global(func)
	table.insert(registered_globals, func)
end

core.register_on_mods_loaded(function()
	for name,def in pairs(core.registered_nodes) do
		if def.on_walk_over then
			on_walk[name] = def.on_walk_over
		end
		if def._on_entity_inside then
			on_entity_inside[name] = def._on_entity_inside
		end
	end
end)

mcl_player.register_globalstep(function(player)
	local pos = player:get_pos()
	local npos = vector.add(pos, mcl_player.node_offsets.stand)
	local node = core.get_node(npos)
	if on_walk[mcl_player.players[player].nodes.stand] then
		on_walk[mcl_player.players[player].nodes.stand](npos, node, player)
	end
	for i = 1, #registered_globals do
		registered_globals[i](npos, node, player)
	end
	if on_entity_inside[mcl_player.players[player].nodes.feet] then
		local npos = vector.add(pos, mcl_player.node_offsets.feet)
		on_entity_inside[mcl_player.players[player].nodes.feet](npos, core.get_node(npos), player)
	end
	if on_entity_inside[mcl_player.players[player].nodes.head] then
		local npos = vector.add(pos, mcl_player.node_offsets.head)
		on_entity_inside[mcl_player.players[player].nodes.head](npos, core.get_node(npos), player)
	end
end)
