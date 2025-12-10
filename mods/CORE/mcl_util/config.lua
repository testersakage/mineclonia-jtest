local function get_modpath()
    return core.get_modpath(core.get_current_modname())
end

function mcl_util.load_json_file(name, modpath)
	local path = (modpath or get_modpath()) .. "/" .. name .. ".json"
	local file = assert(io.open(path, "r"))
	local data = core.parse_json(file:read("*all"))
	file:close()
	return data
end

function mcl_util.update_table_from_json_file(table, name, modpath)
	for k, v in pairs(mcl_util.load_json_file(name, modpath or get_modpath())) do
		table[k] = v
	end
end

function mcl_util.register_craft_from_json_file(name, modpath)
	for output, recipe in pairs(mcl_util.load_json_file(name, (modpath or get_modpath()) .. "/crafting")) do
		core.register_craft({ output = output, recipe = recipe })
	end
end
