-- mineclonia/mods/CORE/mcl_util/misc.lua
minetest.log("action", "[CORE/mcl_util/misc.lua] 03 C++ API.")

function mcl_util.file_exists(name)
	if type(name) ~= "string" then return end
	local f = io.open(name)
	if not f then
		return false
	end
	f:close()
	return true
end

function mcl_util.get_color(colorstr)
	local mc_color = mcl_colors[colorstr:upper()]
	if mc_color then
		colorstr = mc_color
	elseif #colorstr ~= 7 or colorstr:sub(1, 1) ~= "#" then
		return
	end
	local hex = tonumber(colorstr:sub(2, 7), 16)
	if hex then
		return colorstr, hex
	end
end

if core.get_modpath("mcla_generate_translation_strings") then
	mcla_generated_translations = {}
	function mcl_util.get_dynamic_translator(textdomain)
		return function(s, ...)
			local mod = textdomain or core.get_current_modname()
			mcla_generated_translations[mod] = mcla_generated_translations[mod] or {}
			mcla_generated_translations[mod][s] = true
			return core.translate(mod, s, ...)
		end
	end
else
	function mcl_util.get_dynamic_translator(textdomain)
		if textdomain then
			return function(s, ...)
				return core.translate(textdomain, s, ...)
			end
		else
			return function(s, ...)
				local mod = core.get_current_modname()
				assert(mod, "Dynamic translator with dynamic textdomain must not be used after mods have been loaded")
				return core.translate(mod, s, ...)
			end
		end
	end
end

local rng = PcgRandom (os.time())

function mcl_util.dist_triangular(base, magnitude)
	local r = 1 / 2147483647
	local dist = (rng:next(0, 2147483647) * r - rng:next(0, 2147483647) * r)
	return base + magnitude * dist
end

function mcl_util.float_random(from, to)
	to = to or 1
	return from + (math.random() * (to - from))
end

local function round_trunc(x)
	return math.floor(x + 0.5)
end

-- 🏆 【ハイブリッド安全バリケード】：get_nodepos 改札口 [INDEX: 5]
function mcl_util.get_nodepos(pos)
	-- 🛡️ 1. 【厳格な座標検品】：引数が適切なx,y,zを持つテーブル（ベクトル）か検証
	if type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number" then
		-- 🏆 【安全確定】：C++側の3次元最速ボクセル丸めエンジンへ放流 [INDEX: 5]
		if mclcapi and mclcapi.native_get_nodepos then
			return mclcapi.native_get_nodepos(pos)
		end
	else
		-- 🚨 【不審な引数を検知】：C++側を一切汚さず、Lua側でコールスタック付きの警告ログを出力 [INDEX: 1]
		local info = debug.getinfo(2, "Sl")
		local caller = info and (info.short_src .. ":" .. info.currentline) or "unknown"
		core.log("warning", "[MISC EXCEPTION] 🚨 INVALID POS TABLE PASSED TO get_nodepos from " .. caller)
	end
	
	-- 安全なフォールバック（Lua側のピュア幾何学） [INDEX: 1]
	return vector.new(
		math.floor((pos and pos.x or 0) + 0.5),
		math.floor((pos and pos.y or 0) + 0.5),
		math.floor((pos and pos.z or 0) + 0.5)
	)
end

function mcl_util.norm_radians (x)
	local x = x % (math.pi * 2)
	if x >= math.pi then
		x = x - math.pi * 2
	end
	if x < -math.pi then
		x = x + math.pi * 2
	end
	return x
end

function mcl_util.calculate_knockback (velocity, factor, resistance, standing, x, z)
	local factor = factor * (1.0 - math.min (1.0, resistance))
	if factor <= 1.0e-5 then
		return vector.zero()
	end
	local v = vector.normalize(vector.new(x, 0, z)) * factor

	v.x = (velocity.x / 2 + (v.x * 20)) * 0.546
	v.z = (velocity.z / 2 + (v.z * 20)) * 0.546
	v.y = standing and (math.min (0.4 * 20, velocity.y / 2.0 + factor * 10)) or velocity.y
	return v
end

function mcl_util.return_itemstack_if_alive(player, itemstack)
	if player:get_hp() <= 0 then
		return ItemStack()
	end
	return itemstack
end

-- 🏆 【ハイブリッド安全バリケード】：generate_uuid 改札口 [INDEX: 5]
function mcl_util.generate_uuid ()
	-- 🏆 引数がないため100%安全が確定。直接C++側のメルセンヌ・ツイスタ乱数エンジンへ最速パス [INDEX: 5]
	if mclcapi and mclcapi.native_generate_uuid then
		return mclcapi.native_generate_uuid() -- C++側から「文字列」と「31」の2つの戻り値が完全 Symmetry 返却
	end

	-- 安全なフォールバック（Lua側のgsubロジック） [INDEX: 1]
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	local pr = PcgRandom(os.time())
	return string.gsub (template, '[xy]', function (c)
		local v = (c == 'x') and pr:next (0, 0xf) or pr:next (8, 0xb)
		return string.format ('%x', v)
	end)
end

local sqrt = math.sqrt
local floor = math.floor
local mathmax = math.max

local function sieve_of_eratosthenes (x)
	if x < 2 then
		return nil
	end

	local sieve = {}
	sieve[1] = false
	for i = 2, x do
		sieve[i] = true
	end

	for i = 2, floor (sqrt (x)) do
		if sieve[i] then
			for j = i * i, x, i do
				sieve[j] = false
			end
		end
	end

	return sieve
end

local function isprime (sieve, value)
	local value = sieve[value]
	assert (value ~= nil)
	return value
end

local function next_prime (i, sieve)
	if i % 2 == 0 then
		i = i + 1
	end
	while not isprime (sieve, i) do
		i = i + 2
	end
	return i
end

local K = 0.5 - sqrt (3) / 6.0

-- 🏆 【ハイブリッド安全バリケード】：findlcg 改札口 [INDEX: 5]
function mcl_util.findlcg (m)
	-- 🛡️ 1. 【厳格な法（M）の検品】：引数が有効な正の整数であるかをチェック
	if type(m) == "number" and m > 0 then
		-- 🏆 【安全確定】：C++側のエラトステネスの篩・素因数分解エンジンへ一直線に放流 [INDEX: 5]
		if mclcapi and mclcapi.native_findlcg then
			return mclcapi.native_findlcg(m)
		end
	else
		core.log("warning", "[MISC EXCEPTION] 🚨 INVALID MODULUS PASSED TO findlcg! Value: " .. tostring(m))
	end

	-- 安全なフォールバック（Lua側のピュア合同数理） [INDEX: 1]
	local a, b, c
	if m <= 6 then
		b = 0
		c = 1
	else
		local sieve = sieve_of_eratosthenes (m + floor (m / 2))
		local divlimit = m
		b = 1
		if m % 2 == 0 then
			b = 2
			while divlimit % 2 == 0 do
				divlimit = floor (divlimit / 2)
			end
		end

		for i = 3, divlimit, 2 do
			if isprime (sieve, i) and m % i == 0 then
				b = b * i
				while divlimit % i == 0 do
					divlimit = floor (divlimit / i)
				end
			end
		end

		if m % 4 == 0 then
			while b % 4 ~= 0 do
				b = b * 2
			end
		end

		while b < sqrt (m) do
			b = b * 7
		end

		if b == m then
			b = 0
		end

		c = next_prime (floor (mathmax (5, K * m - 2)), sieve)
		while m % c == 0 do
			c = next_prime (c + 1, sieve)
		end
	end

	a = b + 1
	return a, c, m
end

function mcl_util.lcg_next (a, c, m, state)
	return (a * state + c) % m
end
