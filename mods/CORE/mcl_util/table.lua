-- mineclonia/mods/CORE/mcl_util/table.lua
--minetest.log("action", "[CORE/mcl_util/table.lua] 03 C++ API.")
local current_thread = "[" .. (core.get_current_thread_name and core.get_current_thread_name() or "Main/Emerge") .. "]"
core.log("action", string.format("[CORE/mcl_util/table.lua]: %s: 03 C++ API.", current_thread))

-- 【絶対存在保証】：table.update は最初から実名で常駐
function table.update(t, ...)
	--  1. 第1引数の厳格な型検品（改札）
	if type(t) == "table" then
		-- 実行されたその瞬間に C++ が実在すれば、バイパス
		local api = rawget(_G, "mclcapi")
		if api and api.native_table_update then
			return api.native_table_update(t, ...)
		end
	else
		local info = debug.getinfo(2, "Sl")
		local caller = info and (info.short_src .. ":" .. info.currentline) or "unknown"
		core.log("warning", "[TABLE EXCEPTION] INVALID BASE TABLE IN table.update from " .. caller)
	end

	--  2. C++未検出時、または非同期の0手目は、安全にオリジナルのLuaでゲームの即死をガード
	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from ...
function table.update_nil(t, ...)
	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

-- table.update_deep 実名常駐
function table.update_deep(t, ...)
	if type(t) == "table" then
		-- 実行時の動的内部リレー
		local api = rawget(_G, "mclcapi")
		if api and api.native_table_update_deep then
			return api.native_table_update_deep(t, ...)
		end
	else
		local info = debug.getinfo(2, "Sl")
		local caller = info and (info.short_src .. ":" .. info.currentline) or "unknown"
		core.log("warning", "[TABLE EXCEPTION] INVALID BASE TABLE IN table.update_deep from " .. caller)
	end

	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			if type(t[k]) == "table" and type(v) == "table" then
				table.update_deep(t[k], v)
			else
				t[k] = v
			end
		end
	end
	return t
end

-- Merges t with ..., returning a new table
function table.merge(t, ...)
	local t2 = table.copy(t)
	return table.update(t2, ...)
end

-- Recursively merges t with ..., returning a new table
function table.merge_deep(t, ...)
	local t2 = table.copy(t)
	return table.update_deep(t2, ...)
end

-- Reverses the order of elements inside t
function table.reverse(t)
	local a, b = 1, #t
	while a < b do
		t[a], t[b] = t[b], t[a]
		a, b = a + 1, b - 1
	end
end

-- Returns the maximum numerical index of t
function table.max_index(t)
	local max = 0
	for k, _ in pairs(t) do
		if type(k) == "number" and k > max then max = k end
	end
	return max
end

-- Returns the amount of elements of t that are suitable by does_it_count (optional)
function table.count(t, does_it_count)
	local r = 0
	for k, v in pairs(t) do
		if does_it_count == nil or (type(does_it_count) == "function" and does_it_count(k, v)) then
			r = r + 1
		end
	end
	return r
end

-- table.keyset 実名常駐
function table.keyset(t, f)
	if type(t) == "table" then
		-- 実行時の動的内部リレー
		local api = rawget(_G, "mclcapi")
		if api and api.native_table_keyset then
			return api.native_table_keyset(t, f)
		end
	else
		local info = debug.getinfo(2, "Sl")
		local caller = info and (info.short_src .. ":" .. info.currentline) or "unknown"
		core.log("warning", "[TABLE EXCEPTION] INVALID BASE TABLE IN table.keyset from " .. caller)
	end

	local ks = {}
	for k, v in pairs(t) do
		if not f or f(k, v) then
			table.insert(ks, k)
		end
	end
	return ks
end

-- Returns a random element out of t
function table.random_element(t, f)
	local keyset = table.keyset(t, f)
	local rk = keyset[math.random(1, #keyset)]
	return t[rk], rk
end

-- Stable sorting.

-- Attribution: https://github.com

local function sort_setup (array, less)
	local n = #array
	local trivial = (n <= 1)
	if not trivial then
		if less (array[1], array[1]) then
			error ("invalid order function for sorting;"
			       .. " less(v, v) should not be true for any v.")
		end
	end
	return trivial, n, less
end

local function insertion_sort_impl (array, first, last, less)
	for i = first + 1, last do
		local k = first
		local v = array[i]
		for j = i, first + 1, -1 do
			if less (v, array[j - 1]) then
				array[j] = array[j - 1]
			elseif array[j - 1] == nil then
				k = j
				break
			else
				k = j
				break
			end
		end
		array[k] = v
	end
end

local function stable_sort (array, less)
	local trivial, n
	trivial, n, less = sort_setup (array, less)
	if not trivial then
		insertion_sort_impl (array, 1, n, less)
	end
	return array
end

table.stable_sort = stable_sort
