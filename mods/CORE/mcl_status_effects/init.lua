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

function mcl_status_effects.add_particlespawnerdef(obj, color)
	if not color then return end
	local d = 0.2
	return minetest.add_particlespawner({
		amount = 10,
		time = 0,
		minpos = vector.new(-d,1,-d),
		maxpos = vector.new(d,2,d),
		minvel = vector.new(0.1,0, -0.1),
		maxvel = vector.new(0.1, 0.1,0.1),
		minacc = vector.new(-0.1, 0,0.1),
		maxacc = vector.new(0.1, .1, 0.1),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		texture = "mcl_particles_effect.png^[colorize:"..color..":127",
		attached = obj,
	})
end

local function reorder_hud_icons(player)
	if not player:is_player() then return end
	local i = 1
	for effect,v in pairs(effect_players) do
		if v[player] and v[player].hud_icon then
			local x = -52 * i - 2
			i = i + 1
			player:hud_change(v[player].hud_icon, "offset", { x = x, y = 3 })
		end
	end
end

function mcl_status_effects.add_hud_icon(player, icon)
	if not player:is_player() then return end
	local id = player:hud_add({
		hud_elem_type = "image",
		text = icon.."^[resize:128x128",
		position = { x = 1, y = 0 },
		offset = { x = -54, y = 3 },
		scale = { x = 0.375, y = 0.375 },
		alignment = { x = 1, y = 1 },
		z_index = 100,
	})
	return id
end
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
	if effect_players[effect][object] then return end
	local def = table.merge(mcl_status_effects.registered_effects[effect],overrides or {})
	local data = {}
	if def.on_start then
		def.on_start(object, def, data)
	end
	if def.duration and def.duration > 0 then
		effect_players[effect][object] = table.merge({
			time_started = minetest.get_gametime(),
			duration = def.duration,
			factor = def.factor or 1,
			particlespawner = mcl_status_effects.add_particlespawnerdef(object, def.color),
			hud_icon = mcl_status_effects.add_hud_icon(object, "mcl_potions_effect_"..def.name..".png"),
		},data)
		reorder_hud_icons(object)
	end
end

function mcl_status_effects.stop_effect(object, effect, data)
	if not effect_players[effect][object] then return end
	local def = mcl_status_effects.registered_effects[effect]
	if def.on_stop then
		def.on_stop(object, def)
	end
	if data.particlespawner then
		minetest.delete_particlespawner(data.particlespawner)
	end
	if data.hudbar then
		hb.change_hudbar(object, "health", nil, nil, "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
	end
	if data.hud_icon then
		object:hud_remove(data.hud_icon)
		reorder_hud_icons(object)
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
				mcl_status_effects.stop_effect(object, effect, data)
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
	color = "#F82423",
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

mcl_status_effects.register_effect("swift",{
	color = "#7CAFC6",
	on_start = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.add_physics_factor(obj, "speed", "mcl_potions:swiftness", def.factor)
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			local factor = def.factor
			if def.factor < 0 then
				factor = 1 / ( -def.factor)
			end
			data.walk_velocity = l.walk_velocity
			data.run_velocity = l.run_speed
			l.walk_velocity = factor * l.walk_velocity
			l.run_velocity = factor * l.run_velocity
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.remove_physics_factor(obj, "speed", "mcl_potions:swiftness")
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			l.walk_velocity = data.walk_velocity
			l.run_velocity = data.run_velocity
		end
	end,
	factor = 1.2,
	duration = 30,
})

mcl_status_effects.register_effect("slow",{
	color = "#5A6C81",
	on_start = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.add_physics_factor(obj, "speed", "mcl_potions:swiftness", def.factor)
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			local factor = def.factor
			if def.factor < 0 then
				factor = 1 / ( -def.factor)
			end
			data.walk_velocity = l.walk_velocity
			data.run_velocity = l.run_speed
			l.walk_velocity = factor * l.walk_velocity
			l.run_velocity = factor * l.run_velocity
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.remove_physics_factor(obj, "speed", "mcl_potions:swiftness")
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			l.walk_velocity = data.walk_velocity
			l.run_velocity = data.run_velocity
		end
	end,
	factor = 0.85,
	duration = 30,
})

minetest.register_chatcommand("start_effect",{
	func = function(pn,param)
		if mcl_status_effects.registered_effects[param] then
			local pl = minetest.get_player_by_name(pn)
			mcl_status_effects.start_effect(pl,param)
		end
	end
})
