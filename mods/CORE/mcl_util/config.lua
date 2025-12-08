config = {}

function config.load_json_file(modpath, name)
	local path = modpath .. "/" .. name .. ".json"
	local file = assert(io.open(path, "r"))
	local data = core.parse_json(file:read("*all"))
	file:close()
	return data
end
