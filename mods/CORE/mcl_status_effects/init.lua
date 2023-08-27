mcl_status_effects = {}
mcl_status_effects.registered_effects = {}
local effect_players = {}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

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
		return obj:set_hp(math.min(hp, mcl_status_effects.get_hp_max(obj)), table.merge({ type = "set_hp" }, reason or {}))
	end
	local l = obj:get_luaentity()
	if l and l.is_mob then
		l.health = math.min(hp, mcl_status_effects.get_hp_max(obj))
		return true
	end
end

function mcl_status_effects.add_hp(obj, hp, reason)
	local ohp = mcl_status_effects.get_hp(obj)
	if ohp then
		return mcl_status_effects.set_hp(obj, ohp + hp, reason)
	end
end


function mcl_status_effects.register_effect(name, def)
	def.name = name
	mcl_status_effects.registered_effects[name] = def
	if def.duration and def.duration > 0 then
		effect_players[name] = {}
	end
end

function mcl_status_effects.is_active(obj, effect)
	return effect_players[effect] and effect_players[effect][obj]
end

function mcl_status_effects.get_effect_def(effect)
	return mcl_status_effects.registered_effects[effect]
end

function mcl_status_effects.start_effect(object, effect, overrides, restore)
	if not restore and mcl_status_effects.is_active(object, effect) then return end
	if mcl_status_effects.get_hp(object) <= 0 then return end

	if not mcl_status_effects.registered_effects[effect] then
		minetest.log("warning","["..tostring(minetest.get_current_modname()).."] trying to start non existent status effect: "..tostring(effect))
		return end

	local def = table.merge(mcl_status_effects.registered_effects[effect],overrides or {})
	local data = {}
	if def.on_start then
		def.on_start(object, def, data)
	end
	local hudbar
	local hbicon = data.hudbar_icon or def.hudbar_icon or nil
	if object:is_player() and hbicon then
		hudbar = hb.change_hudbar(object, "health", nil, nil, hbicon, nil, "hudbars_bar_health.png")
	end
	if def.on_stop and def.duration and def.duration > 0 then
		if not restore then
			effect_players[effect][object] = table.merge({
				time_started = minetest.get_gametime(),
				duration = def.duration,
				factor = def.factor or 1,
			},data)
		end
		effect_players[effect][object].particlespawner = mcl_status_effects.add_particlespawnerdef(object, def.color)
		if object:is_player() then
			effect_players[effect][object].hud_icon = mcl_status_effects.add_hud_icon(object, def.icon or "mcl_potions_effect_"..def.name..".png")
			effect_players[effect][object].hudbar = hudbar
			reorder_hud_icons(object)
		end
	end
	if not object:is_player() then
		local l = object:get_luaentity()
		if l and l.is_mob and effect_players[effect] then
			l.status_effects[effect] = effect_players[effect][object]
		end
	end
end

function mcl_status_effects.stop_effect(object, effect)
	if not mcl_status_effects.is_active(object, effect) then return end
	local def = mcl_status_effects.registered_effects[effect]
	local data = effect_players[effect][object]
	if def.on_stop then
		def.on_stop(object, def, data)
	end
	if data.particlespawner then
		minetest.delete_particlespawner(data.particlespawner)
	end
	if object:is_player() and data.hudbar then
		hb.change_hudbar(object, "health", nil, nil, data.hudbar_reset or "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
	end
	if object:is_player() and data.hud_icon then
		object:hud_remove(data.hud_icon)
		data.hud_icon = nil
		reorder_hud_icons(object)
	end
	if not object:is_player() then
		local l = object:get_luaentity()
		if l and l.is_mob then
			l.status_effects[effect] = nil
		end
	end
	effect_players[effect][object] = nil
end

function mcl_status_effects.get_active_effects(obj, stop) --players only, mob data is saved in luaentity
	local r = {}
	local i = 0
	for effect,obs in pairs(effect_players) do
		for o,data in pairs (obs) do
			if obj:is_player() and o:is_player() and obj:get_player_name() == o:get_player_name() then
				r[effect] = table.copy(data)
				if stop then mcl_status_effects.stop_effect(obj, effect) end
				i = i + 1
			end
		end
	end
	return r, i
end

function mcl_status_effects.clear_player(player)
	mcl_status_effects.get_active_effects(player, true)
end

function mcl_status_effects.save_player_effects(player)
	local meta = player:get_meta()
	local efs, count = mcl_status_effects.get_active_effects(player, true)
	if count > 0 then
		meta:set_string("status_effects",minetest.serialize(efs))
	end

end
minetest.register_on_leaveplayer(mcl_status_effects.save_player_effects)

minetest.register_on_shutdown(function()
	for _,pl in pairs(minetest.get_connected_players()) do
		mcl_status_effects.save_player_effects(pl)
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	mcl_status_effects.get_active_effects(player, true)
end)

function mcl_status_effects.restore_player_effects(player)
	local meta = player:get_meta()
	local efs = meta:get_string("status_effects")
	if efs ~= "" then
		for effect,data in pairs(minetest.deserialize(efs)) do
			effect_players[effect][player] = data
			mcl_status_effects.start_effect(player, effect, {}, true)
		end
	end
	meta:set_string("status_effects","")
end
minetest.register_on_joinplayer(mcl_status_effects.restore_player_effects)

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
			if not object:is_player() then
				local l = object:get_luaentity()
				if l and l.is_mob and effect_players[effect] then
					l.status_effects[effect] = data
				end
			end
		end
	end
end)

dofile(modpath.."/effects.lua")
