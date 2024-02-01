local S = minetest.get_translator(minetest.get_current_modname())

mcla_settings = {}

local settings = Settings(minetest.get_worldpath() .. DIR_DELIM .. "mcla_settings.conf")

local mcla_settings_meta = {}

local function full_name(domain, name)
	if string.find(domain, ".", 1, true) or string.find(name, ".", 1, true) then
		minetest.log("error", S("Setting domains and names cannot contain a dot"))
		return
	end

	return domain .. "." .. name
end

local full_name_regex = "^([^.]+)%.([^.]+)$"

function mcla_settings.split_fullname(full_name)
	return string.match(full_name, full_name_regex)
end

function mcla_settings.register(domain, name, default, help)
	local full_name = full_name(domain, name)
	if not full_name then
		return
	end

	if not settings:has(full_name) then
		minetest.log("info", S("Registering setting @1 = @2", full_name, tostring(default)))
		settings:set(full_name, default)
		if not settings:write() then
			minetest.log("action", S("Setting @1 could not be saved!", full_name))
			return
		end
	end

	mcla_settings_meta[full_name] = { type = "string", default = default, help = help }

	return mcla_settings.get(domain, name)
end

function mcla_settings.register_bool(domain, name, default, help)
	local full_name = full_name(domain, name)
	if not full_name then
		return
	end

	if not settings:has(full_name) then
		minetest.log("info", S("Registering setting @1 = @2", full_name, tostring(default)))
		settings:set_bool(full_name, default)
		if not settings:write() then
			minetest.log("action", S("Setting @1 could not be saved!", full_name))
		end
	end

	mcla_settings_meta[full_name] = { type = "bool", default = default, help = help }

	return mcla_settings.get(domain, name)
end

function mcla_settings.unregister(domain, name)
	local full_name = full_name(domain, name)
	if not full_name then
		return
	end

	if not settings:has(full_name) then
		minetest.log("warning", S("Can't unregister the setting @1, it has not been registered", full_name))
		return
	end

	if settings:remove(full_name) then
		minetest.log("action", S("The setting @1 has been removed", full_name))
	else
		minetest.log("action", S("The setting @1 could not be removed", full_name))
	end
end

function mcla_settings.get(domain, name)
	local full_name = full_name(domain, name)
	if not full_name then
		return
	end

	if not settings:has(full_name) then
		return S("Can't get the setting @1, it has not been registered", full_name)
	end

	local type = mcla_settings_meta[full_name]["type"]

	if type == "bool" then
		return settings:get_bool(full_name)
	else
		return settings:get(full_name)
	end
end

function mcla_settings.set(domain, name, value)
	local full_name = full_name(domain, name)
	if not full_name then
		return
	end

	if not settings:has(full_name) then
		minetest.log("warning", S("Can't set the setting @1, it has not been registered", full_name))
		return
	end

	local type = mcla_settings_meta[full_name]["type"]

	if type == "bool" then
		if value == "false" or value == "0" then
			value = false
		end
		settings:set_bool(full_name, value)
	else
		settings:set(full_name, value)
	end

	if settings:write() then
		minetest.log("info", S("Setting @1 is set to @2", full_name, tostring(value)))
	else
		minetest.log(S("warning", "Setting @1 could not be saved!", full_name, tostring(value)))
	end
end

minetest.register_chatcommand("wset", {
	description = S("Display or change Mineclonia world settings"),
	params = S("[ help | <name> | <name> <value>]"),
	privs = { server = true },
	func = function(name, param)
		if param == "" then
			for _, key in pairs(settings:get_names()) do
				local domain, sname = mcla_settings.split_fullname(key)
				minetest.chat_send_player(name, string.format("%s: %s", key, mcla_settings.get(domain, sname)))
			end
		elseif param == "help" then
			for _, key in pairs(settings:get_names()) do
				minetest.chat_send_player(name, string.format("%s: %s", key, S(mcla_settings_meta[key]["help"])))
			end
		else
			local sparam = param:split(" ")
			local key = sparam[1]
			local value = sparam[2]
			if value ~= nil then
				local domain, sname = mcla_settings.split_fullname(key)
				mcla_settings.set(domain, sname, value)
			else
				local domain, sname = mcla_settings.split_fullname(key)
				minetest.chat_send_player(name, string.format("%s: %s", key, mcla_settings.get(domain, sname)))
			end
		end
	end,
})
