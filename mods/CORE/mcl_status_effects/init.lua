mcl_status_effects = {}
mcl_status_effects.registered_effects = {}
local effect_players = {}

--[[
{
	on_start = function(player,def) end,
	on_stop = function(player,def) end,
	on_step = functionn(player,def,data,dtime) end,
	--function that is run every step. data is the player entry in player_effects
	--containing by default:
	--	{
			time_started = --gametime when the effect was started.
			duration = --time in seconds this instance of the effect is going to last.
			particlespawner = --the particlespawner ID
	--	}
	duration = seconds,
	--default duration for the effect if duration == 0 only the start function is taken into account
	-- and the effect is considered a "one-off" instant effect like healing.
}

--]]
function mcl_status_effects.get_hp_max(obj)
	if obj:is_player() then
		return obj:get_properties().hp_max
	end
	local l = obj:get_luaentity()
	if l and l.is_mob then
		return l.hp_max
	end
end

function mcl_status_effects.get_hp(obj)
	if obj:is_player() then
		return obj:get_hp()
	end
	local l = obj:get_luaentity()
	if l and l.is_mob then
		return l.health
	end
end

function mcl_status_effects.set_hp(obj, hp, reason)
	if obj:is_player() then
		return obj:set_hp(math.min(hp, mcl_status_effects.get_hp_max(obj)), { type = "set_hp", other = reason })
	end
	local l = obj:get_luaentity()
	if l and l.is_mob then
		l.health = math.min(hp, mcl_status_effects.get_hp_max(obj))
		return true
	end
end

function mcl_status_effects.add_hp(obj, hp)
	local ohp = mcl_status_effects.get_hp(obj)
	if ohp then
		return mcl_status_effects.set_hp(obj, ohp + hp)
	end
end


function mcl_status_effects.register_effect(name, def)
	def.name = name
	mcl_status_effects.registered_effects[name] = def
	if def.duration and def.duration > 0 then
		effect_players[name] = {}
	end
end

function mcl_status_effects.start_effect(object, effect, overrides)
	local def = table.merge(mcl_status_effects.registered_effects[effect],overrides or {})
	if def.on_start then
		def.on_start(object,def)
	end
	if def.duration and def.duration > 0 then
		effect_players[effect][object] = {
			time_started = minetest.get_gametime(),
			duration = def.duration,
			factor = def.factor or 1
			--particlespawner = minetest.add_particlespawner(...)
		}
	end
end

function mcl_status_effects.stop_effect(object,effect)
	if not effect_players[effect][object] then return end
	local def = mcl_status_effects.registered_effects[effect]
	if def.on_stop then
		def.on_stop(object, def)
	end
	effect_players[effect][object] = nil
end

--function mcl_status_effects.save_player_effects(player)

--end

--function mcl_status_effects.restore_player_effects(player)

--end

minetest.register_globalstep(function(dtime)
	for effect,objects in pairs(effect_players) do
		local def = mcl_status_effects.registered_effects[effect]
		for object, data in pairs(objects) do
			data.etime = ( data.etime or 0 ) + dtime
			if data.etime > (data.duration or 0) then
				mcl_status_effects.stop_effect(object,effect)
			elseif def.on_step then
				def.on_step(object, def, data, dtime)
			end
		end
	end
end)

mcl_status_effects.register_effect("test_start_stop",{
	on_start = function(obj, def)
		minetest.log(def.name.." started for player "..obj:get_player_name())
	end,
	on_stop = function(obj, def)
		minetest.log(def.name.." stopped for player "..obj:get_player_name())
	end
})

mcl_status_effects.register_effect("test_step",{
	on_start = function(obj, def)
		minetest.log(def.name.." started for player "..obj:get_player_name())
	end,
	on_stop = function(obj, def)
		minetest.log(def.name.." stopped for player "..obj:get_player_name())
	end,
	on_step = function(obj, def, data, dtime)
		data.timer = (data.timer or 0) + dtime
		if data.timer < 1 then return end
		data.timer = 0
		minetest.log(def.name.." step for player .."..obj:get_player_name())
	end,
	duration = 10,
})

mcl_status_effects.register_effect("healing",{
	on_start = function(obj, def)
		local hp = math.max(1,4 * def.factor)
		local l = obj:get_luaentity()
		if l and l.harmed_by_heal then
			mcl_util.deal_damage(obj, hp, {type = "magic"})
		else
			mcl_status_effects.add_hp(obj, hp, "healing")
		end
	end,
	factor = 1,
})

minetest.register_chatcommand("start_effect",{
	func = function(pn,param)
		if mcl_status_effects.registered_effects[param] then
			local pl = minetest.get_player_by_name(pn)
			mcl_status_effects.start_effect(pl,param)
		end
	end
})
