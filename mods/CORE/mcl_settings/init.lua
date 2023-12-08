--[[
TODO

* formspec for making changes in game?

]]

local S = minetest.get_translator(minetest.get_current_modname())

mcl_settings = {}

local settings = Settings(minetest.get_worldpath() .. DIR_DELIM .. "mcl_settings.conf")

function mcl_settings.get(name, default)
	if settings then
		local val = settings:get(name)
		if val == nil then
			val = minetest.settings:get(name, default)
			if val then
				mcl_settings.set(name, val)
				if not settings:write() then
					minetest.log("warning", S("Setting @1 could not be saved!", name))
				end
			end
		end

		return val
	end

	return minetest.settings:get(name, default)
end

function mcl_settings.get_bool(name, default)
	if settings then
		local val = settings:get_bool(name)
		if val == nil then
			val = minetest.settings:get_bool(name, default)
			if val ~= nil then
				mcl_settings.set_bool(name, val)
				if not settings:write() then
					minetest.log("warning", S("Setting @1 could not be saved!", name))
				end
			end
		end

		return val
	end

	return minetest.settings:get_bool(name, default)
end

function mcl_settings.set(name, value)
	settings:set(name, value)

	if settings:write() then
		minetest.log("info", S("Setting @1 is set to @2", name, value))
	else
		minetest.log(S("warning", "Setting @1 could not be saved!", name, value))
	end
end

function mcl_settings.set_bool(name, value)
	settings:set_bool(name, value)

	if settings:write() then
		minetest.log("info", S("Setting @1 is set to @2", name, tostring(value)))
	else
		minetest.log(S("warning", "Setting @1 could not be saved!", name, tostring(value)))
	end
end

minetest.register_chatcommand("wset", {
	description = S("Display or set world settings"),
	params = S("[<name> | <name> <value>]"),
	privs = { server = true },
	func = function(name, param)
		if param == "" then
			for _, key in pairs(settings:get_names()) do
				minetest.chat_send_player(name, string.format("%s: %s", key, mcl_settings.get(key)))
			end
		else
			local sparam = param:split(" ")
			local key = sparam[1]
			local value = sparam[2]
			if value ~= nil then
				mcl_settings.set(key, value)
			else
				minetest.chat_send_player(name, string.format("%s: %s", key, mcl_settings.get(key)))
			end
		end
	end,
})

-- Override global settings
if settings then
	for _, key in pairs(settings:get_names()) do
		local val = mcl_settings.get(key)
		minetest.settings:set(key, val)
	end
end
