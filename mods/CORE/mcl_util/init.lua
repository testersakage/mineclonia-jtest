-- mineclonia/mods/CORE/mcl_util/init.lua
minetest.log("action", "[CORE/mcl_util/init.lua] init. start.")

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

mcl_util = rawget(_G, "mcl_util") or {}
mclcapi = rawget(_G, "mclcapi") or {}

-- `table` extensions
dofile(modpath .. "/table.lua")
core.register_mapgen_script (modpath .. "/table.lua")
core.register_async_dofile (modpath .. "/table.lua")
-- Utilities for environment access (nodes, mapgen)
dofile(modpath .. "/environment.lua")
-- Item-related utilities
dofile(modpath .. "/item.lua")
-- Functions operating on ObjectRefs
dofile(modpath .. "/object.lua")
-- Misc. utility functions
dofile(modpath .. "/misc.lua")
-- Queue class
mcl_util.queue = dofile(modpath .. "/queue.lua")
-- Ringbuffer class
mcl_util.ringbuffer = dofile(modpath .. "/ringbuffer.lua")
-- Conversion to roman numerals
dofile(modpath .. "/roman.lua")
-- Backwards compatibility
dofile(modpath .. "/compat.lua")
-- Shape library.
dofile(modpath.."/shape.lua")
core.register_mapgen_script (modpath .. "/shape.lua")
core.register_async_dofile (modpath .. "/shape.lua")
-- Spatial index library.
dofile (modpath .. "/spatialindex.lua")
dofile (modpath .. "/control.lua")


minetest.register_chatcommand("native_apis", {
	params = "",
	description = "現在Luantiにバインドされている 'native' を名前に持つC++ APIの一覧を取得する",
	privs = {server = true},
	func = function(name)
		local api_table = rawget(_G, "mclcapi")
		if not api_table then
			return false, "[API_CHECK] ❌ C++窓口テーブル 'mclcapi' がこの宇宙に実在しません。"
		end

		local found_apis = {}
		local count = 0

		-- mclcapiの胎内を総当たりループ走査
		for key, val in pairs(api_table) do
--			if type(key) == "string" and key:find("native") then
				count = count + 1
				table.insert(found_apis, string.format("%02d. %s (%s)", count, key, type(val)))
--			end
		end

		if count == 0 then
			return true, "[API_CHECK] ⚠️ 'mclcapi' は存在しますが、'native' を含むAPIは0件です。"
		end

		-- アルファベット順にお片付け（ソート）して画面へ一斉出荷
		table.sort(found_apis)
		local result_text = "\n=== 👑 開通済み C++ Native API 一覧 (" .. count .. "件) ===\n"
		result_text = result_text .. table.concat(found_apis, "\n")
		
		return true, result_text
	end,
})