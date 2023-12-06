--[[
TODO

* UI for changes?
* help and description localisation
	* is it possible to handle since the translations may be in a different mod?

	local lang = minetest.get_player_information(playername).lang_code
	minetest.get_translated_string(lang, description)

]]

local S = minetest.get_translator(minetest.get_current_modname())

mcl_world_settings = {}

local settings = Settings(minetest.get_worldpath() .. DIR_DELIM .. "mcl_settings.conf")

local mcl_world_settings_meta = {}

function mcl_world_settings.register(name, default, description, help)
	if not settings:get(name) then
		minetest.log("info", S("Registering setting @1", name))
		settings:set(name, default)
		if not settings:write() then
			minetest.log("action", S("Setting @1 could not be saved!", name))
		end
	end

	mcl_world_settings_meta[name] = { type = "string", default = default, description = description, help = help }
end

function mcl_world_settings.register_bool(name, default, description, help)
	if not settings:get_bool(name) then
		minetest.log(S("Registering setting @1 = @2", name, tostring(default)))
		settings:set_bool(name, default)
		if not settings:write() then
			minetest.log("action", S("Setting @1 could not be saved!", name))
		end
	end
	mcl_world_settings_meta[name] = { type = "bool", default = default, description = description, help = help }
end

function mcl_world_settings.unregister(name)
	if not settings:get(name) then
		minetest.log("warning", S("Can't unregister the setting @1, it has not been registered", name))
		return
	end

	if settings:remove(name) then
		minetest.log("action", S("The setting @1 has been removed", name))
	else
		minetest.log("action", S("The setting @1 could not be removed", name))
	end
end

function mcl_world_settings.get(name)
	if not settings:get(name) then
		return S("Can't get the setting @1, it has not been registered", name)
	end

	local type = mcl_world_settings_meta[name]["type"]

	if type == "bool" then
		return settings:get_bool(name)
	else
		return settings:get(name)
	end
end

function mcl_world_settings.set(name, value)
	minetest.log("set 1")
	if not settings:get(name) then
		minetest.log("warning", S("Can't set the setting @1, it has not been registered", name))
		return
	end

	local type = mcl_world_settings_meta[name]["type"]

	if type == "bool" then
		if value == "false" or value == "0" then
			value = false
		end
		settings:set_bool(name, value)
	else
		settings:set(name, value)
	end

	if settings:write() then
		minetest.log("info", S("Setting @1 is set to @2", name, tostring(value)))
	else
		minetest.log(S("warning", "Setting @1 could not be saved!", name, tostring(value)))
	end
end

minetest.register_chatcommand("world_settings", {
	description = S("Display or set world settings"),
	params = S("[info | help | <name> <value>]"),
	privs = { server = true },
	func = function(name, param)
		if param == "" then
			for _, key in pairs(settings:get_names()) do
				minetest.chat_send_player(name, string.format("%s: %s", key, mcl_world_settings.get(key)))
			end
		elseif param == "info" then
			for _, key in pairs(settings:get_names()) do
				minetest.chat_send_player(
					name,
					string.format("%s: %s", key, S(mcl_world_settings_meta[key]["description"]))
				)
			end
		elseif param == "help" then
			for _, key in pairs(settings:get_names()) do
				minetest.chat_send_player(name, string.format("%s: %s", key, S(mcl_world_settings_meta[key]["help"])))
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
