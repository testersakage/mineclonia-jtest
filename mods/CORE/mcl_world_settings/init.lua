--[[
TODO

* UI for changes
* help and description localisation
	* is it possible to handle since the translations are in a different mod?

	local lang = minetest.get_player_information(playername).lang_code
	minetest.get_translated_string(lang, description)

Handy for testing: storage:from_table(nil)

]]

local storage = minetest.get_mod_storage()
local S = minetest.get_translator(minetest.get_current_modname())

mcl_world_settings = {}

local mcl_world_settings_meta = {}

function mcl_world_settings.register_string(name, default, description, help)
	if not storage:contains(name) then
		minetest.log("info", S("Registering setting @1", name))
		storage:set_string(name, default)
	end

	mcl_world_settings_meta[name] = { type = "string", default = default, description = description, help = help }
end

function mcl_world_settings.register_bool(name, default, description, help)
	if not storage:contains(name) then
		minetest.log("info", S("Registering setting @1", name))
		storage:set_int(name, default and 1 or 0)
	end
	mcl_world_settings_meta[name] = { type = "bool", default = default, description = description, help = help }
end

function mcl_world_settings.register_float(name, default, description, help)
	if not storage:contains(name) then
		minetest.log("action", S("Registering setting @1", name))
		storage:set_float(name, default)
	end
	mcl_world_settings_meta[name] = { type = "float", default = default, description = description, help = help }
end

function mcl_world_settings.register_int(name, default, description, help)
	if not storage:contains(name) then
		minetest.log("warning", S("Registering setting @1", name))
		storage:set_int(name, default)
	end
	mcl_world_settings_meta[name] = { type = "int", default = default, description = description, help = help }
end

function mcl_world_settings.unregister(name)
	if not storage:contains(name) then
		minetest.log("warning", S("Can't unregister the setting @1, it has not been registered", name))
		return
	end

	storage:set_string(name, nil)
end

function mcl_world_settings.get(name)
	if not storage:contains(name) then
		return S("Can't get the setting @1, it has not been registered", name)
	end

	local type = mcl_world_settings_meta[name]["type"]

	if type == "bool" then
		return storage:get_int(name) and 1 or 0
	elseif type == "int" then
		return storage:get_int(name)
	elseif type == "float" then
		return storage:get_float(name)
	else
		return storage:get_string(name)
	end
end

function mcl_world_settings.set(name, value)
	if not storage:contains(name) then
		minetest.log("warning", S("Can't set the setting @1, it has not been registered", name))
		return
	end

	local type = mcl_world_settings_meta[name]["type"]

	if type == "bool" then
		storage:set_int(name, tonumber(value) and 1 or 0)
	elseif type == "int" then
		storage:set_int(name, tonumber(value))
	elseif type == "float" then
		storage:set_float(name, tonumber(value))
	else
		storage:set_string(name, value)
	end

	minetest.log("action", S("Setting @1 is set to @2", name, value))
end

minetest.register_chatcommand("world_settings", {
	description = S("Display or set world settings"),
	params = S("[info | help | <name> <value>]"),
	privs = { server = true },
	func = function(name, param)
		if param == "" then
			for _, key in pairs(storage:get_keys()) do
				minetest.chat_send_player(name, string.format("%s: %s", key, mcl_world_settings.get(key)))
			end
		elseif param == "info" then
			for _, key in pairs(storage:get_keys()) do
				minetest.chat_send_player(
					name,
					string.format("%s: %s", key, S(mcl_world_settings_meta[key]["description"]))
				)
			end
		elseif param == "help" then
			for _, key in pairs(storage:get_keys()) do
				minetest.chat_send_player(
					name,
					string.format("%s: %s", key, S(mcl_world_settings_meta[key]["help"]))
				)
			end
		else
			local sparam = param:split(" ")
			local key = sparam[1]
			local value = sparam[2]
			if value ~= nil then
				mcl_world_settings.set(key, value)
			else
				minetest.chat_send_player(name, string.format("%s: %s", key, mcl_world_settings.get(key)))
			end
		end
	end,
})
