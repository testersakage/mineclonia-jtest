-- mineclonia/mods/CORE/mcl_damage/init.lua
minetest.log("action", "[damage] 03 C++ API.")

mcl_damage = {
	modifiers = {},
	damage_callbacks = {},
	death_callbacks = {},
	types = {
		in_fire = {is_fire = true},
		lightning_bolt = {is_lightning = true},
		on_fire = {is_fire = true, bypasses_armor = true},
		lava = {is_fire = true},
		hot_floor = {is_fire = true},
		in_wall = {bypasses_armor = true},
		drown = {bypasses_armor = true},
		freeze = {bypasses_armor = true},
		starve = {bypasses_armor = true, bypasses_magic = true},
		cactus = {},
		sweet_berry = {},
		fall = {bypasses_armor = true},
		fly_into_wall = {},
		out_of_world = {bypasses_armor = true, bypasses_magic = true, bypasses_invulnerability = true, bypasses_totem = true},
		generic = {bypasses_armor = true},
		magic = {is_magic = true, bypasses_armor = true, bypasses_guardian = true,},
		dragon_breath = {is_magic = true, bypasses_armor = true},	-- this is only used for dragon fireball; dragon fireball does not actually deal impact damage tho, so this is unreachable
		wither = {bypasses_armor = true},
		wither_skull = {is_magic = true, is_explosion = true},
		anvil = {},
		falling_node = {},	-- this is falling_block in MC
		spit = {is_projectile = true},
		mob = {},
		player = {},
		arrow = {is_projectile = true},
		fireball = {is_projectile = true, is_fire = true},
		thorns = {is_magic = true, bypasses_guardian = true,},
		explosion = {is_explosion = true, scales = true, always_affects_dragons = true},
		cramming = {bypasses_armor = true},
		fireworks = {is_explosion = true}, -- unused
		environment = {},
		light = {},
		trident = {},
	}
}

local damage_enabled = core.settings:get_bool("enabled_damage",true)

function mcl_damage.register_modifier(func, priority)
	table.insert(mcl_damage.modifiers, {func = func, priority = priority or 0})
end

function mcl_damage.register_on_damage(func)
	table.insert(mcl_damage.damage_callbacks, func)
end

function mcl_damage.register_on_death(func)
	table.insert(mcl_damage.death_callbacks, func)
end

function mcl_damage.run_modifiers(obj, damage, reason)
	for _, modf in ipairs(mcl_damage.modifiers) do
		damage = modf.func(obj, damage, reason) or damage
		if damage == 0 then
			return 0
		end
	end

	return damage
end

local function run_callbacks(funcs, ...)
	for _, func in pairs(funcs) do
		func(...)
	end
end

function mcl_damage.run_damage_callbacks(obj, damage, reason)
	run_callbacks(mcl_damage.damage_callbacks, obj, damage, reason)
end

function mcl_damage.run_death_callbacks(obj, reason)
	run_callbacks(mcl_damage.death_callbacks, obj, reason)
end

function mcl_damage.from_punch(mcl_reason, object)
	if object then
		mcl_reason.direct = object
		local luaentity = object:get_luaentity()
		if luaentity then
			if luaentity._is_arrow then
				mcl_reason.type = "arrow"
			elseif luaentity._is_fireball then
				mcl_reason.type = "fireball"
			elseif luaentity.is_mob then
				mcl_reason.type = "mob"
			end
			mcl_reason.source = mcl_reason.source or luaentity._source_object
		else
			mcl_reason.type = "player"
		end
	else
		mcl_reason.type = "generic"
	end
end

function mcl_damage.finish_reason(mcl_reason)
	mcl_reason.source = mcl_reason.source or mcl_reason.direct
	mcl_reason.flags = mcl_damage.types[mcl_reason.type] or {}

	if mcl_reason.source then
		if not mcl_reason.source:is_player () then
			local entity = mcl_reason.source:get_luaentity ()
			if entity and entity.is_mob then
				mcl_reason.mob_name = entity.name
			end
		end
	end
end

function mcl_damage.from_mt(mt_reason)
	if mt_reason._mcl_cached_reason then
		return mt_reason._mcl_cached_reason
	end

	local mcl_reason

	if mt_reason._mcl_reason then
		mcl_reason = mt_reason._mcl_reason
	else
		mcl_reason = {type = "generic"}

		if mt_reason._mcl_type then
			mcl_reason.type = mt_reason._mcl_type
		elseif mt_reason.type == "fall" then
			mcl_reason.type = "fall"
		elseif mt_reason.type == "drown" then
			mcl_reason.type = "drown"
		elseif mt_reason.type == "punch" then
			mcl_damage.from_punch(mcl_reason, mt_reason.object)
		elseif mt_reason.type == "node_damage" and mt_reason.node then
			if core.get_item_group(mt_reason.node, "fire") > 0 then
				mcl_reason.type = "in_fire"
			end
			if core.get_item_group(mt_reason.node, "lava") > 0 then
				mcl_reason.type = "lava"
			end
		end

		for key, value in pairs(mt_reason) do
			if key:find("_mcl_") == 1 then
				mcl_reason[key:sub(6, #key)] = value
			end
		end
	end

	mcl_damage.finish_reason(mcl_reason)
	mt_reason._mcl_cached_reason = mcl_reason

	return mcl_reason
end

function mcl_damage.register_type(name, def)
	mcl_damage.types[name] = def
end

-- games/mineclonia-jtest/mods/CORE/mcl_damage/init.lua （★後半部分・148行目付近からの完全上書き用）

local function emulate_damage_tick (player)
	core.sound_play ("player_damage", { to_player = player:get_player_name (), gain = 0.5, }, true)
end

-- 👑 【1回目のロード（起動初期フェーズ）】：本家のガワの関数をメモリにカチ揃えさせる
function mcl_damage.damage_player (player, amount, mcl_reason)
	if not mcl_reason.flags then mcl_damage.finish_reason (mcl_reason) end
	if amount < 0 then mcl_damage.heal_player (player, -amount) end

	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()

	if math.ceil (mcl_health) ~= engine_hp then mcl_health = engine_hp end
	amount = mcl_damage.run_modifiers (player, amount, mcl_reason)
	mcl_health = math.max (0, mcl_health - amount)
	meta:set_float ("mcl_health", mcl_health)

	mcl_health = math.ceil (mcl_health)
	if mcl_health < engine_hp then
		player:set_hp (mcl_health, { type = "set_hp", mcl_damage = true, _mcl_reason = mcl_reason, })
	elseif amount > 0 then
		emulate_damage_tick (player)
	end
end

function mcl_damage.heal_player (player, amount)
	if amount < 0 then return end
	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()
	if math.ceil (mcl_health) ~= engine_hp then mcl_health = engine_hp end
	mcl_health = math.min (player:get_properties ().hp_max, mcl_health + amount)
	meta:set_float ("mcl_health", mcl_health)
	mcl_serverplayer.update_vitals (player)

	mcl_health = math.ceil (mcl_health)
	if mcl_health > engine_hp then
		player:set_hp (mcl_health, { type = "set_hp", mcl_damage = true, })
	end
end

function mcl_damage.get_hp (player)
	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()
	if math.ceil (mcl_health) ~= engine_hp then mcl_health = engine_hp end
	return mcl_health
end

core.register_on_player_hpchange(function(player, hp_change, mt_reason)
	if not damage_enabled then return 0 end
	if mt_reason.mcl_damage then return hp_change end

	if mt_reason.type == "node_damage" and mt_reason.node then
		local nodedef = core.registered_nodes[mt_reason.node]
		if nodedef.damage_per_second then hp_change = -nodedef.damage_per_second end
	end

	if hp_change < 0 then
		if player:get_hp() <= 0 then return 0 end
		hp_change = -mcl_damage.run_modifiers (player, -hp_change, mcl_damage.from_mt (mt_reason))
	end

	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()

	if math.ceil (mcl_health) ~= engine_hp then mcl_health = engine_hp end
	mcl_health = math.max (0, mcl_health + hp_change)
	meta:set_float ("mcl_health", mcl_health)
	mcl_serverplayer.update_vitals (player)

	local difference = math.ceil (mcl_health) - engine_hp
	if mt_reason.type ~= "fall" and difference == 0 and hp_change < 0 then
		emulate_damage_tick (player)
	end
	return difference
end, true)

core.register_on_punchplayer (function (player, hitter, _, _, _, damage)
	if damage > 0 then
		local mcl_reason = { type = "generic", }
		mcl_damage.from_punch (mcl_reason, hitter)
		mcl_damage.damage_player (player, damage, mcl_reason)
		return true
	end
end)

-- 👑 【ログイン・ログアウトの電線をC++メモリの2重装甲へと直結！】
core.register_on_joinplayer (function (player, _)
	local g_util = rawget(_G, "mclcapi")
	if g_util and g_util.native_damage_sync_to_engine then
		g_util.native_damage_sync_to_engine(player, "join") -- C++側のキャッシュを確定
	else
		local meta = player:get_meta ()
		if meta:get_float ("mcl_health") == 0 then
			meta:set_float ("mcl_health", player:get_hp ())
			mcl_serverplayer.update_vitals (player)
		end
	end
end)

core.register_on_dieplayer(function(player, mt_reason)
	local g_util = rawget(_G, "mclcapi")
	if g_util and g_util.native_damage_sync_to_engine then
		g_util.native_damage_sync_to_engine(player, "die") -- C++側で0リセット＆即DISK同期
	else
		local meta = player:get_meta ()
		meta:set_float ("mcl_health", 0)
	end
	mcl_damage.run_death_callbacks(player, mcl_damage.from_mt(mt_reason))
end)

-- 👑 サーバー終了時（ログアウト時）にC++メモリからDISKへ一括セーブさせる自動同期の網
core.register_on_leaveplayer(function(player)
	local g_util = rawget(_G, "mclcapi")
	if g_util and g_util.native_damage_sync_to_engine then
		g_util.native_damage_sync_to_engine(player, "sync")
	end
end)

local function is_mob (source)
	if not source then return false end
	local entity = source:get_luaentity ()
	return entity and entity.is_mob
end

mcl_damage.register_modifier (function (obj, damage, reason)
	if not obj:is_player () then return damage end
	-- 👑 【FPU倍率計算筋肉への一本釣り】：実務中の難易度計算をC++側へ身代わりリダイレクト！
	local g_util = rawget(_G, "mclcapi")
	if g_util and g_util.native_damage_calculate_modifier then
		return g_util.native_damage_calculate_modifier(damage, reason)
	end
	if (reason.flags.scales == true) or is_mob (reason.source) then
		if mcl_vars.difficulty == 0 then return 0
		elseif mcl_vars.difficulty == 1 then return math.min (damage / 2.0 + 1.0, damage)
		elseif mcl_vars.difficulty == 3 then return damage * 1.5 end
	end
	return damage
end, -1000)

core.register_on_mods_loaded(function()
	table.sort(mcl_damage.modifiers, function(a, b) return a.priority < b.priority end)
end)

-- ─── 👑 【これにて完全大開通】：すべてのModが読み込み終わった直後の「この大トリの部屋」で、
--      C++製内部メモリ加減算処理（native_damage_tick_health）へと一直線に上書き完全乗っ取り！ ───
local g_util = rawget(_G, "mclcapi")
if g_util and g_util.native_damage_tick_health then

	-- 🏆 毎フレーム・持続被ダメの瞬間にDISKをノックしていた処理を、C++メモリ処理へと完全直結！
	mcl_damage.damage_player = function(player, amount, mcl_reason)
		if not mcl_reason.flags then mcl_damage.finish_reason (mcl_reason) end
		if amount < 0 then mcl_damage.heal_player (player, -amount) end
		
		-- 難易度モディファイアを回す
		amount = mcl_damage.run_modifiers(player, amount, mcl_reason)
		
		-- C++ハッシュマップの内部メモリのみを減算更新（DISKアクセス完全消滅！）
		local current_hp = g_util.native_damage_tick_health(player, amount, false)
		
		local engine_hp = player:get_hp()
		local next_ceil = math.ceil(current_hp)
		if next_ceil < engine_hp then
			player:set_hp(next_ceil, { type = "set_hp", mcl_damage = true, _mcl_reason = mcl_reason, })
		elseif amount > 0 then
			emulate_damage_tick(player)
		end
	end

	mcl_damage.heal_player = function(player, amount)
		if amount < 0 then return end
		
		-- C++ハッシュマップの内部メモリのみを加算更新（DISKアクセス完全消滅！）
		local current_hp = g_util.native_damage_tick_health(player, amount, true)
		
		mcl_serverplayer.update_vitals(player)
		local engine_hp = player:get_hp()
		local next_ceil = math.ceil(current_hp)
		if next_ceil > engine_hp then
			player:set_hp(next_ceil, { type = "set_hp", mcl_damage = true, })
		end
	end

	mcl_damage.get_hp = function(player)
		-- C++ハッシュマップのメモリから数値を1ナノ秒で無音回収
		return g_util.native_damage_tick_health(player, 0, false)
	end

--	minetest.log("action", "[damage] Damage & Health cache  3 C++ API.")
end

local save_timer = 0
local save_interval = tonumber(core.settings:get("mcl_save_interval")) or 10

minetest.log("action", "[damage] save timer: " .. save_interval .. "sec.")

core.register_globalstep(function(dtime)
	save_timer = save_timer + dtime
	if save_timer >= save_interval then -- 👑 minetest.conf から吸い出した可変の規律をロック！
		local g_util = rawget(_G, "mclcapi")
		if g_util and g_util.native_damage_bulk_save_all then
			g_util.native_damage_bulk_save_all() -- 🏆 贅肉無しのC++バルクセーブAPIを1行でキック！
		end
		save_timer = 0
	end
end)

--[[
--- Player damage.

local function emulate_damage_tick (player)
	core.sound_play ("player_damage",
			{ to_player = player:get_player_name (), gain = 0.5, },
			true)
end

--- An independent floating point health statistic is associated with
--- players which is synchronized with the engine HP whenever damage
--- is sustained or healing takes place.  If the engine HP changes
--- independently of this statistic, the change is adjusted by the
--- statistic.

function mcl_damage.damage_player (player, amount, mcl_reason)
	if not mcl_reason.flags then
	  mcl_damage.finish_reason (mcl_reason)
	end
	if amount < 0 then
	  mcl_damage.heal_player (player, -amount)
	end

	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()

	-- It's probably wise to be cautious and verify that the engine and
	-- internal HPs match.

	if math.ceil (mcl_health) ~= engine_hp then
	  core.log ("warning", ("Engine health of player "
				.. player:get_player_name ()
				.. " disagrees with MCL health "
				.. mcl_health ..""))
	  -- Reset internal health to the engine value.
	  mcl_health = engine_hp
	end
	amount = mcl_damage.run_modifiers (player, amount, mcl_reason)
	mcl_health = math.max (0, mcl_health - amount)
	meta:set_float ("mcl_health", mcl_health)

	mcl_health = math.ceil (mcl_health)
	if mcl_health < engine_hp then
	  player:set_hp (mcl_health, { type = "set_hp", mcl_damage = true,
					_mcl_reason = mcl_reason, })
	elseif amount > 0 then
	  -- Play a damage sound to the player.  Minetest affords games no
	  -- control over the tilt animation, unfortunately.
	  emulate_damage_tick (player)
	end
end

function mcl_damage.heal_player (player, amount)
	if amount < 0 then
	  return
	end

	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()
	if math.ceil (mcl_health) ~= engine_hp then
	  core.log ("warning", ("Engine health of player "
				.. player:get_player_name ()
				.. " disagrees with MCL health "
				.. mcl_health ..""))
	  -- Reset internal health to the engine value.
	  mcl_health = engine_hp
	end
	mcl_health = math.min (player:get_properties ().hp_max,
			  mcl_health + amount)
	meta:set_float ("mcl_health", mcl_health)
	mcl_serverplayer.update_vitals (player)

	mcl_health = math.ceil (mcl_health)
	if mcl_health > engine_hp then
	  player:set_hp (mcl_health, { type = "set_hp", mcl_damage = true, })
	end
end

function mcl_damage.get_hp (player)
	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()
	if math.ceil (mcl_health) ~= engine_hp then
	  core.log ("warning", ("Engine health of player "
				.. player:get_player_name ()
				.. " disagrees with MCL health "
				.. mcl_health ..""))
	  -- Reset internal health to the engine value.
	  mcl_health = engine_hp
	end
	return mcl_health
end

core.register_on_player_hpchange(function(player, hp_change, mt_reason)
	if not damage_enabled then return 0 end
	-- Take engine damage modifications from mcl_damage at face value.
	if mt_reason.mcl_damage then
		return hp_change
	end

	-- Detect damage from hazardous nodes and deduct the full
	-- amount of the damage, rather than hp_change, which is
	-- restricted to the player's remaining health and may be
	-- attenuated by armor or other protection.

	if mt_reason.type == "node_damage" and mt_reason.node then
		local nodedef = core.registered_nodes[mt_reason.node]

		if nodedef.damage_per_second then
		  hp_change = -nodedef.damage_per_second
		end
	end

	if hp_change < 0 then
		if player:get_hp() <= 0 then
		  return 0
		end
		hp_change = -mcl_damage.run_modifiers (player, -hp_change,
						  mcl_damage.from_mt (mt_reason))
	end

	-- Apply this as internal damage.
	local meta = player:get_meta ()
	local mcl_health = meta:get_float ("mcl_health")
	local engine_hp = player:get_hp ()

	-- It's probably wise to be cautious and verify that the
	-- engine and internal HPs match.

	if math.ceil (mcl_health) ~= engine_hp then
		core.log ("warning", ("Engine health of player "
					 .. player:get_player_name ()
					 .. " disagrees with MCL health "
					 .. mcl_health ..""))
		-- Reset internal health to the engine value.
		mcl_health = engine_hp
	end

	-- Deduct engine damage.
	mcl_health = math.max (0, mcl_health + hp_change)
	meta:set_float ("mcl_health", mcl_health)
	mcl_serverplayer.update_vitals (player)

	-- Return the difference in engine damage.
	local difference = math.ceil (mcl_health) - engine_hp
	if mt_reason.type ~= "fall" and difference == 0 and hp_change < 0 then
		emulate_damage_tick (player)
	end
	return difference
end, true)

core.register_on_punchplayer (function (player, hitter, _, _, _, damage)
	  -- Inflict the Minetest-computed damage by means of
	  -- mcl_damage.damage_player.
	  if damage > 0 then
	 local mcl_reason = { type = "generic", }
	 mcl_damage.from_punch (mcl_reason, hitter)
	 mcl_damage.damage_player (player, damage, mcl_reason)
	 return true
	  end
end)

core.register_on_joinplayer (function (player, _)
	  -- Convert the player's engine HP into a floating point internal
	  -- value if none already exists.
	  local meta = player:get_meta ()
	  if meta:get_float ("mcl_health") == 0 then
	 meta:set_float ("mcl_health", player:get_hp ())
	mcl_serverplayer.update_vitals (player)
	  end
end)

core.register_on_dieplayer(function(player, mt_reason)
	  -- Clear the internal HP of players who die.
	  local meta = player:get_meta ()
	  meta:set_float ("mcl_health", 0)
	  mcl_damage.run_death_callbacks(player, mcl_damage.from_mt(mt_reason))
end)

-- Register a modifier that adjusts damage by difficulty.

local function is_mob (source)
	if not source then
		return false
	end
	local entity = source:get_luaentity ()
	return entity and entity.is_mob
end

mcl_damage.register_modifier (function (obj, damage, reason)
	if not obj:is_player () then
		return damage
	end
	if (reason.flags.scales == true) or is_mob (reason.source) then
		if mcl_vars.difficulty == 0 then
			return 0
		elseif mcl_vars.difficulty == 1 then
			return math.min (damage / 2.0 + 1.0, damage)
		elseif mcl_vars.difficulty == 3 then
			return damage * 1.5
		end
	end
	return damage
end, -1000)

core.register_on_mods_loaded(function()
	table.sort(mcl_damage.modifiers, function(a, b) return a.priority < b.priority end)
end)
]]
