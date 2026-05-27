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

local g_util = rawget(_G, "mclcapi")
if g_util and g_util.native_decompose_aabbs then

	-- shape.lua 関連の関数すげ替え
	mcl_util.decompose_AABBs                   = g_util.native_decompose_aabbs
	mcl_util.region_op                         = g_util.native_region_op
	mcl_util.region_evaluate                   = g_util.native_region_evaluate
	mcl_util.any_occupied_p                    = g_util.native_any_occupied_p
	mcl_util.region_volume                     = g_util.native_region_volume
	mcl_util.region_equal_p                    = g_util.native_region_equal_p
	mcl_util.region_walk                       = g_util.native_region_walk
	mcl_util.region_simplify                   = g_util.native_region_simplify
	mcl_util.region_select_face                = g_util.native_region_select_face

	-- table.lua 関連の関数すげ替え
	mcl_util.table_update                      = g_util.native_table_update
	mcl_util.table_reverse                     = g_util.native_table_reverse
	mcl_util.table_max_index                   = g_util.native_table_max_index

	if _G.region_class then
		_G.region_class.intersect_p    = g_util.native_intersect_p
		_G.region_class.op             = g_util.native_region_op
		_G.region_class.evaluate       = g_util.native_region_evaluate
		_G.region_class.any_occupied_p = g_util.native_any_occupied_p
		_G.region_class.volume         = g_util.native_region_volume
		_G.region_class.equal_p        = g_util.native_region_equal_p -- 👈 🏆 コロン構文アクセスへの鉄壁の防衛バリケード！！！
		_G.region_class.walk           = g_util.native_region_walk
		_G.region_class.simplify       = g_util.native_region_simplify
		_G.region_class.select_face    = g_util.native_region_select_face
	end

	-- 毎フレームの最速環境ステップ更新（globalstep）を、ここで C++ 筋肉へと直撃大開通！
	core.register_globalstep(g_util.native_environment_globalstep)

	minetest.log("action", "[util/init.lua] Resister C++ API (shape,table).")
end
