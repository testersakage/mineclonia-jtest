-- mineclonia/mods/CORE/mcl_util/init.lua
minetest.log("action", "[util/init.lua] init. start.")

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


-- ─── 【AABBs動的スピードリミッター・チャットコマンド】 ───
--     C++側の処理が速すぎて警告が出る現象に対処するため、
--     動的にミリ秒単位のウェイト（一時停止）をC++へ直接

minetest.register_chatcommand("aabb_weight", {
	params = "<milliseconds> or 0",
	description = "AABBsネイティブ分解エンジンの内部ウェイト（ミリ秒）を動的に指定・変更する",
	privs = {server = true},
	func = function(name, param)
		local ms = tonumber(param)
		if not ms or ms < 0 then
			minetest.chat_send_player(name, " [AABB LIMITER] 正しい数値を指定してください。 (例: /aabb_weight 5)")
			return
		end
		
		-- 【C++側の変数同期窓口（var_規律）へ、数値をセット！
		if mclcapi and mclcapi.var_set_aabb_weight then
			mclcapi.var_set_aabb_weight(ms)
			if ms == 0 then
				minetest.chat_send_player(name, " [AABB LIMITER] ウェイトを解除しました。C++ネイティブ状態で処理します。")
			else
				minetest.chat_send_player(name, " [AABB LIMITER] C++の AABBs 分解に 『 " .. ms .. " ミリ秒 』 のディレイを注入しました。")
			end
		else
			minetest.chat_send_player(name, " [AABB LIMITER] C++側の var_set_aabb_weight が検出できません。")
		end
	end,
})
