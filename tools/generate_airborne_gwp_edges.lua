local gwp_airborne_directions = {
	-- North (1).
	{ 0, 0, 1, },
	-- West (2).
	{-1, 0, 0, },
	-- South (3).
	{ 0, 0, -1, },
	-- East (4).
	{ 1, 0, 0, },

	-- Bottom (5).
	{ 0, -1, 0, },
	-- Top (6).
	{ 0, 1, 0, },

	-- North (7).
	{ 0, 1, 1,	6, 1, },
	-- West (8).
	{-1, 1, 0,	6, 2, },
	-- South (9).
	{ 0, 1, -1,	6, 3, },
	-- East (10).
	{ 1, 1, 0,	6, 4, },

	-- North (11).
	{ 0, -1, 1,	5, 1, },
	-- West (12).
	{-1, -1, 0,	5, 2, },
	-- South (13).
	{ 0, -1, -1,	5, 3, },
	-- East (14).
	{ 1, -1, 0,	5, 4, },

	-- Northwest (15).
	{ -1, 0, 1,	1, 2, },
	-- Northeast (16).
	{ 1, 0, -1,	1, 4, },
	-- Southwest (17).
	{ -1, 0, -1,	3, 2, },
	-- Southeast (18),
	{ 1, 0, -1,	3, 4, },

	-- Northwest (19).
	{ -1, 1, 1,	15, 1, 2, 6, 7, 8, },
	-- Northeast (20).
	{ 1, 1, -1,	16, 1, 4, 6, 7, 10, },
	-- Southwest (21).
	{ -1, 1, -1,	17, 3, 2, 6, 9, 8, },
	-- Southeast (22),
	{ 1, 1, -1,	18, 3, 4, 6, 9, 10, },

	-- Northwest (23).
	{ -1, -1, 1,	15, 1, 2, 5, 11, 12, },
	-- Northeast (24).
	{ 1, -1, -1,	16, 1, 4, 5, 11, 14, },
	-- Southwest (25).
	{ -1, -1, -1,	17, 3, 2, 5, 13, 12, },
	-- Southeast (26),
	{ 1, -1, -1,	18, 3, 4, 5, 13, 14, },
}

local airborne_gwp_edges = "local function airborne_gwp_edges (self, context, node)\
\tlocal results = airborne_gwp_edges_buffer\
\tlocal n = 0\
\tlocal v = airborne_gwp_edges_scratch\n\n"

for i, direction in ipairs (gwp_airborne_directions) do
	airborne_gwp_edges = airborne_gwp_edges
		.. string.format ("\tv.x = node.x + %d\n\tv.y = node.y + %d\n\tv.z = node.z + %d\n",
				  direction[1], direction[2], direction[3])
		.. string.format ("\tlocal e%d = airborne_gwp_edges_1 (self, context, v)\n",
				  i)
	airborne_gwp_edges = airborne_gwp_edges
		.. string.format ("\tif e%d", i)
	for i = 4, #direction do
		airborne_gwp_edges = airborne_gwp_edges
			.. "\n\t\tand "
			.. string.format ("e%d", direction[i])
	end
	airborne_gwp_edges = airborne_gwp_edges
		.. " then\n"
		.. string.format ("\t\tn = n + 1; results[n] = e%d\n", i)
		.. "\tend\n"
end

airborne_gwp_edges = airborne_gwp_edges .. "\tresults[n + 1] = nil\n\treturn results\nend\n"
print (airborne_gwp_edges)
