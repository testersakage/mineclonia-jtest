minetest.register_on_mods_loaded(function()
	local prms = "<"
	for k,_ in pairs(mcl_status_effects.registered_effects) do
		prms = prms .. k .. "|"
	end
	prms = prms:gsub("|$","")
	minetest.register_chatcommand("start_effect",{
		description = "Apply a status effect to yourself",
		params = prms.."> <factor>",
		privs = { debug = true },
		func = function(pn,param)
			local effect = param:split(" ")[1]
			local factor = tonumber(param:split(" ")[2])
			if mcl_status_effects.registered_effects[effect] then
				mcl_status_effects.start_effect(minetest.get_player_by_name(pn), effect, { factor = factor })
				return true, "Effect ".. tostring(effect) .. " started"
			end
			return false, "Effect ".. tostring(effect) .. " does not exist"
		end
	})
end)

--missing:
--- x - prob requires engine change
--- e - easy to implement
--- p - possible but probably not so easy currently
--- h - could be done but probably hacky
-- Haste           x?
-- Mining Fatigue  x?
-- Nausea          x / h (maybe with particle spawner tricks ?)
-- Resistance      p
-- Blindness       h
-- strength        p
-- weakness        p
-- Hunger          e
-- Health Boost    e
-- Absorption      h
-- Saturation      e
-- Glowing         h
-- Luck            p
-- Fatal Poison    e
-- Slow Falling    x
-- Conduit Power   x?
-- Dolphin's Grace p
-- Hero of the Village e
-- Darkness        x


mcl_status_effects.register_effect("test_start_stop",{
	on_start = function(obj, def)
		minetest.log(def.name.." started for player "..obj:get_player_name())
	end,
	on_stop = function(obj, def)
		minetest.log(def.name.." stopped for player "..obj:get_player_name())
	end,
	duration = 10,
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
		local hp = def.factor or 4
		local l = obj:get_luaentity()
		if l and l.harmed_by_heal then
			mcl_util.deal_damage(obj, hp, {type = "magic"})
		else
			mcl_status_effects.add_hp(obj, hp, {other = "healing"})
		end
	end,
})

mcl_status_effects.register_effect("harming",{
	color = "#430A09",
	on_start = function(obj, def)
		local hp = def.factor or -6
		local l = obj:get_luaentity()
		if l and l.harmed_by_heal then
			mcl_util.deal_damage(obj, hp, {type = "magic"})
		else
			mcl_status_effects.add_hp(obj, hp, {other = "healing"})
		end
	end,
})

mcl_status_effects.register_effect("night_vision",{
	color = "#1F1FA1",
	on_start = function(obj, def, data)
		if obj:is_player() then
			mcl_weather.skycolor.update_sky_color({obj})
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			mcl_weather.skycolor.update_sky_color({obj})
		end
	end,
	factor = 1.2,
	duration = 30,
})

mcl_status_effects.register_effect("swiftness",{
	icon = "mcl_potions_effect_swift.png",
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

mcl_status_effects.register_effect("slowness",{
	icon = "mcl_potions_effect_slow.png",
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

mcl_status_effects.register_effect("leaping",{
	color = "#22FF4C",
	on_start = function(obj, def, data)
		if obj:is_player() then
			playerphysics.add_physics_factor(obj, "jump", "mcl_potions:leaping", def.factor)
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			local factor = def.factor
			if def.factor < 0 then
				factor = 1 / ( -def.factor)
			end
			data.jump_height = l.jump_height
			l.jump_height = factor * l.jump_height
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.remove_physics_factor(obj, "jump", "mcl_potions:leaping")
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			l.jump_height = data.jump_height
		end
	end,
	factor = 2.5,
	duration = 30,
})

mcl_status_effects.register_effect("poison",{
	icon = "mcl_potions_effect_poisoned.png",
	color = "#4E9331",
	hudbar_icon = "hbhunger_icon_health_poison.png",
	on_start = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "regeneration") then
				data.hudbar_icon = "hbhunger_icon_regen_poison.png"
			end
			return
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "regeneration") then
				data.hudbar_reset = "hudbars_icon_regenerate.png"
			end
			return
		end
	end,
	on_step = function(obj, def, data, dtime)
		data.timer = (data.timer or 0) + dtime
		if data.timer < def.factor then return end
		data.timer = 0
		if mcl_util.get_hp(obj) - 1 > 0 then
			mcl_util.deal_damage(obj, 1, {type = "magic"})
		end
	end,
	factor = 2.5,
	duration = 30,
})

mcl_status_effects.register_effect("wither",{
	icon = "mcl_potions_effect_withering.png",
	color = "#4E9331",
	hudbar_icon = "mcl_potions_icon_wither.png",
	on_start = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "regeneration") then
				data.hudbar_icon = "mcl_potions_icon_regen_wither.png"
			end
			return
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "regeneration") then
				data.hudbar_reset = "hudbars_icon_regenerate.png"
			end
			return
		end
	end,
	on_step = function(obj, def, data, dtime)
		data.timer = (data.timer or 0) + dtime
		if data.timer < def.factor then return end
		data.timer = 0
		if mcl_util.get_hp(obj) > 0 then
			mcl_util.deal_damage(obj, 1, {type = "magic"})
		end
	end,
	factor = 2.5,
	duration = 30,
})

mcl_status_effects.register_effect("regeneration",{
	icon = "mcl_potions_effect_regenerating.png",
	color = "#CD5CAB",
	hudbar_icon = "hudbars_icon_regenerate.png",
	on_start = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "regeneration") then
				data.hudbar_icon = "hbhunger_icon_regen_poison.png"
			end
			return
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			if mcl_status_effects.is_active(obj, "poison") then
				data.hudbar_reset = "hbhunger_icon_health_poison.png"
			end
			return
		end
	end,
	on_step = function(obj, def, data, dtime)
		data.timer = (data.timer or 0) + dtime
		if data.timer < def.factor then return end
		data.timer = 0
		mcl_status_effects.add_hp(obj, 1, {other = "regeneration"})
	end,
	factor = 2.5,
	duration = 30,
})

mcl_status_effects.register_effect("invisibility",{
	icon = "mcl_potions_effect_invisible.png",
	color = "#7F8392",
	on_start = function(obj, def, data)
		if obj:is_player() then
			mcl_player.player_set_visibility(obj, false)
			obj:set_nametag_attributes({ color = { a = 0 } })
			return
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			data.old_size = l.visual_size
			obj:set_properties({ visual_size = { x = 0, y = 0 } })
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			mcl_player.player_set_visibility(obj, true)
			obj:set_nametag_attributes({ color = { r = 255, g = 255, b = 255, a = 255 } })
			return
		end
		local l = obj:get_luaentity()
		if l and l.is_mob then
			obj:set_properties({ visual_size = data.old_size })
		end
	end,
	duration = 30,
})

mcl_status_effects.register_effect("water_breathing",{
	color = "#2E5299",
	on_step = function(obj, def, data, dtime)
		if obj:get_breath() then
			hb.hide_hudbar(obj, "breath")
			if obj:get_breath() < 10 then obj:set_breath(10) end
		end
	end,
	duration = 30,
})

mcl_status_effects.register_effect("fire_resistance",{
	icon = "mcl_potions_effect_fire_proof.png",
	color = "#E49A3A",
	duration = 30,
	on_start = function(obj, def, data) --mostly implemented in mcl_burning
		mcl_burning.extinguish(obj)
	end,
})

-- Prevent damage to player with Fire Resistance enabled
mcl_damage.register_modifier(function(obj, damage, reason)
	if mcl_status_effects.is_active(obj, "fire_resistance") and not reason.flags.bypasses_magic and reason.flags.is_fire then
		return 0
	end
end, -50)

mcl_status_effects.register_effect("bad_omen",{
	color = "#E49A3A",
	duration = 360,
})

mcl_status_effects.register_effect("hero_of_the_village",{
	color = "#AAF57F",
	duration = 360,
})

mcl_status_effects.register_effect("levitation",{
	icon = "mcl_potions_effect_levitation.png",
	color = "#18191D",
	on_start = function(obj, def, data)
		if obj:is_player() then
			obj:set_pos(vector.offset(obj:get_pos(),0,0.2,0))
			return playerphysics.add_physics_factor(obj, "gravity", "mcl_status_effects:levitation", -0.1)
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			return playerphysics.remove_physics_factor(obj, "gravity", "mcl_status_effects:levitation")
		end
	end,
	on_step = function(obj, def, data, dtime)
		data.timer = (data.timer or 0) + dtime
		if data.timer > 1 then return end
		data.timer = 0
		obj:add_velocity(vector.new(0,3,0))
	end,
	duration = 5,
})
