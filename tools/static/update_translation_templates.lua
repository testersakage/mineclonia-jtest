#!/usr/bin/env lua5.1
--[[

dependencies: luarocks install --lua-version 5.1 metalua luafileystem utf8

rules for lua code this script enforces:

- a local variable S may be assigned to minetest.get_translator(...) where it's argument is one of:
	- minetest.get_current_modname() - current modname will be used as textdomain
	- modname - current modname will be used as textdomain
	- "..." - any string literal that will be used as textdomain
- S may be called with a string literal or concatenation of string literals as first argument. in this case, the first argument will be interpreted as translation template string.
- a local variable W may be assigned to mcl_curry(S)
- S may be called with a string literal or concatenation of string literals as argument. in this case, the argument will be interpreted as translation template string.
- S and W may not we used in any other way
- S may not be assigned twice in a scope
- minetest.get_translator may not be used in any other way
- minetest.translate may not be used

=> Translation strings can not be generated programmatically.

These conditions are very strict to keep the logic of the script minimal while ensuring all translation strings are caught, and cases that can't be handled will throw an error.
If necessary, the set of handled cases may be extended in the future.

for translation files:
- @n must be used for newline escapes
- the script will move unused ("dead") translation strings to a seperate section after used ("alive") translation strings
- the script will add new translation strings at the end of the alive section
- the script will revive strings that are used again and move them back to the alive section
- a line '##### not used anymore ##### is treated as a marker for the begging of the dead section
- comments (with the exception of the textdomain comment) will be treated as referring to the line that follows the comments. they will be moved together with lines. multiple comment lines following each other will be treated as a block and moved together.

]]

local u = require("tools/static/util")
local utf8 = require("utf8")

local node_assign_S = u.lua:src_to_ast("local S = minetest.get_translator(XXX)")[1]
local node_get_modname = u.lua:src_to_ast("minetest.get_current_modname()")[1]
local node_assign_W = u.lua:src_to_ast("local W = mcl_curry(S)")[1]

local function is_translator(node)
	return u.is_ident(node, "S") or u.is_ident(node, "W")
end

-- process an AST node
local function proc_node(node, mod, mods, target)
	local target_node = u.match_node(node, node_assign_S)
	if target_node then
		assert(not target, "get_translator called twice " .. u.lineinfo(target_node))

		local target_name
		if u.is_ident(target_node, "modname") or u.match_node(target_node, node_get_modname) then
			target_name = mod.conf.name
		else
			target_name = u.match_string(target_node)
			assert(target_name, "malformed get_translator argument " .. u.lineinfo(target_node))
		end

		target = mods[target_name]
		assert(target, "absent mod: " .. target_name .. " " .. u.lineinfo(target_node))

		return target
	elseif u.match_node(node, node_assign_W) then
		assert(target, "currying translator before getting it " .. u.lineinfo(node))
	elseif u.is_ident(node, "get_translator") or u.is_ident(node, "translate") then
		error("malformed occurence of get_translator/translate " .. u.lineinfo(node))
	elseif is_translator(node) then
		error("malformed occurence of translator " .. u.lineinfo(node))
	elseif type(node) == "table" and node.tag == "Call" and is_translator(node[1]) then
		local template = u.match_concat(node[2])

		assert(template, "malformed argument to call to translator " .. u.lineinfo(node))
		assert(target, "call to translator before assigned ", u.lineinfo(node))

		template = utf8.gsub(template, "@[^@=0-9]", "@@")
		template = utf8.gsub(template, '\\"', '"')
		template = utf8.gsub(template, "\\'", "'")
		template = utf8.gsub(template, "\n", "@n")
		template = utf8.gsub(template, "\\n", "@n")
		template = utf8.gsub(template, "=", "@=")

		if not target.template_set[template] then
			target.template_set[template] = true
			table.insert(target.template_list, template)
		end
	elseif type(node) == "table" then
		for _, child in ipairs(node) do
			target = proc_node(child, mod, mods, target) or target
		end
	end
end

local function update_template(mod)
	local filename = mod.path .. "/locale/template.txt"
	local f = io.open(filename, "r")

	local has = {}

	local alive = {}

	local dead_add = {}
	local dead_keep = {}

	local unused_line = "##### not used anymore #####"

	if f then
		local current = alive
		local dead = dead_add

		local comments = {}
		local function emit(into, line)
			for _, c in ipairs(comments) do
				table.insert(into, c)
			end
			comments = {}

			table.insert(into, line)
		end

		local function process_line(line)
			local lhs = utf8.match(line, "^(.-)=$")
			local textdomain = utf8.match(line, "# textdomain:%s?(.-)$")

			if textdomain then
				assert(textdomain == mod.conf.name, "invalid textdomain, expected '"
					.. mod.conf.name .. "', got '" .. textdomain .. "'")
			elseif line == unused_line then
				dead = dead_keep
				current = dead_keep

				emit(current)
			elseif utf8.sub(line, 1, 1) == "#" then
				table.insert(comments, line)
			elseif lhs then
				if not has[lhs] then
					has[lhs] = true
					emit(mod.template_set[lhs] and alive or dead, line)
				end
			elseif line == "" then
				emit(current, line)
			else
				error("invalid line: '" .. line .. "' in file " .. filename)
			end
		end

		for line in f:lines() do
			process_line(line)
		end

		if #comments > 0 then
			emit(current)
		end

		f:close()
	elseif #mod.template_list > 0 then
		u.fs.mkdir(mod.path .. "/locale")
	else
		return
	end

	table.insert(alive, 1, "# textdomain: " .. mod.conf.name)

	f = io.open(filename, "w")
	local function emit(str)
		f:write(str .. "\n")
	end

	-- emit old lines that have not been killed
	for _, l in ipairs(alive) do
		emit(l)
	end

	-- emit newly spawned lines, in order of occurence in source code
	for _, t in ipairs(mod.template_list) do
		if not has[t] then
			emit(t .. "=")
		end
	end

	if #dead_keep > 0 or #dead_add > 0 then
		emit(unused_line)

		-- emit old dead lines that have not been revived
		for _, l in ipairs(dead_keep) do
			emit(l)
		end

		-- emit newly killed lines
		for _, l in ipairs(dead_add) do
			emit(l)
		end
	end

	f:close()
end

local mods = u.find_mods(function(mod)
	mod.template_set = {}
	mod.template_list = {}
end)

print("extracting template strings...")
u.iter_mods(mods, function(mod)
	u.iter_sources(mod.path, function(path)
		proc_node(u.lua:srcfile_to_ast(path), mod, mods, nil)
	end)
end)

print("updating template files...")
u.iter_mods(mods, update_template)
