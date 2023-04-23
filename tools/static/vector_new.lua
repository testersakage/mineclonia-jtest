#!/usr/bin/env lua5.1
-- this script automatically replaces deprecated vector tables {x=...,y=...,z=...} by vector.new(x, y, z)
-- dependencies: luarocks install --lua-version 5.1 metalua luafileystem
local u = require("tools/static/util")

local order = {x = 1, y = 2, z = 3}

local function proc_node(source, node)
	if type(node) ~= "table" then
		return
	end

	if node.tag == "Table" then
		local comp = {}

		for _, pair in ipairs(node) do
			local key

			if pair.tag == "Pair" then
				key = u.match_string(pair[1])
			end

			if key and order[key] then
				comp[order[key]] = u.ast_to_src(pair[2])
			else
				comp = {}
				break
			end
		end

		if #comp == 3 then
			return source:sub(1, node.lineinfo.first.offset-1)
				.. "vector.new(" .. table.concat(comp, ", ") .. ")"
				.. source:sub(node.lineinfo.last.offset+1)
		end
	end

	for _, child in ipairs(node) do
		local ret = proc_node(source, child)
		if ret then
			return ret
		end
	end
end

u.iter_mods(u.find_mods(), function(mod)
	u.iter_sources(mod.path, function(path)
		u.loop_replace(path, proc_node)
	end)
end)
