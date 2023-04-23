local u = {}

require("metalua.loader")
u.fs = require("lfs")
u.lua = require("metalua.compiler").new()
u.ast_to_src = require("tools/static/ast_to_src").new() -- https://github.com/LizzyFleckenstein03/metalua/blob/master/metalua/compiler/ast_to_src.mlua

function u.iter_dir(path, callback, ...)
	for file in u.fs.dir(path) do
		if file:sub(1,1) ~= "." then
			callback(path .. "/" .. file, ...)
		end
	end
end

function u.dump_node(node, ident)
	ident = ident or ""
	io.write(ident)

	if type(node) ~= "table" then
		print(node)
		return
	end

	print(node.tag)
	for _, c in ipairs(node) do
		u.dump_node(c, ident .. "  ")
	end
end

function u.is_ident(node, id)
	return type(node) == "table" and #node == 1 and node.tag == "Id" and node[1] == id
end

function u.match_node(n1, n2)
	if u.is_ident(n2, "XXX") then
		return n1
	end

	if type(n1) ~= "table" or type(n2) ~= "table" then
		return n1 == n2
	end

	if n1.tag ~= n2.tag or #n1 ~= #n2 then
		return
	end

	local result = true

	for i, c1 in ipairs(n1) do
		local x = u.match_node(c1, n2[i])

		if not x then
			return
		end

		if x ~= true then
			result = x
		end
	end

	return result
end

function u.lineinfo(node)
	return node.lineinfo.first.source .. ":" .. node.lineinfo.first.line
end

function u.match_string(node)
	return u.match_node(node, { tag = "String", { tag = "Id", "XXX" } })
end

function u.match_concat(node)
	local x = u.match_string(node)

	if x then
		return x
	end

	if type(node) == "table" and node[1] == "concat" then
		local a, b = u.match_concat(node[2]), u.match_concat(node[3])

		if a and b then
			return a .. b
		end
	end
end

function u.iter_sources(path, callback)
	if u.fs.attributes(path).mode == "directory" then
		u.iter_dir(path, u.iter_sources, callback)
		return
	end

	if not path:match("%.lua$") then
		return
	end

	callback(path)
end

function u.loop_replace(path, callback)
	local old_source = io.open(path, "r"):read("*all")

	local source = old_source
	while true do
		local new_source = callback(source, u.lua:src_to_ast(source))
		if not new_source then
			break
		end
		source = new_source
	end

	if source ~= old_source then
		io.open(path, "w"):write(source)
	end
end

function u.find_mods(callback)
	local mods = {}

	local function proc_mod(path, modpack)
		if modpack or io.open(path .. "/modpack.conf") then
			u.iter_dir(path, proc_mod)
			return
		end

		local f = io.open(path .. "/mod.conf")
		if not f then
			return
		end

		local conf = {}

		for l in f:lines() do
			local key, value = l:match("%s*([%w_]+)%s*=%s*([%w_]+)%s*")
			if key and value then
				conf[key] = value
			end
		end

		assert(conf.name, path .. " mod.conf does not contain name")

		if mods[conf.name] then
			error(conf.name .. " exists twice at " .. path .. " and " .. mods[conf.name].path)
		end

		mods[conf.name] = {
			path = path,
			conf = conf,
		}

		if callback then
			callback(mods[conf.name])
		end
	end

	proc_mod("mods", true)

	return mods
end

function u.iter_mods(mods, callback)
	local num_mods = 0
	for _ in pairs(mods) do
		num_mods = num_mods + 1
	end

	local cols = io.popen("stty size", "r"):read("*all"):match("%d+ (%d+)")

	if cols then
		cols = cols - 2

		io.write("[" .. string.rep(" ", cols) .. "]\r[")
		io.flush()
	end

	local i, c = 0, 0
	for _, mod in pairs(mods) do
		callback(mod)

		i = i + 1
		if cols then
			local col = math.floor(cols*i/num_mods)

			while col > c do
				io.write("#")
				c = c + 1
			end
		else
			io.write(".")
		end
		io.flush()
	end

	if cols then
		print("]")
	else
		print()
	end
end

return u
