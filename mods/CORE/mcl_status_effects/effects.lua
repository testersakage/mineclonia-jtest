minetest.register_on_mods_loaded(function()
	local prms = "<"
	for k,_ in pairs(mcl_status_effects.registered_effects) do
		prms = prms .. k .. "|"
	end

	minetest.register_chatcommand("start_effect",{
		description = "Apply a status effect to yourself",
		params = prms.."> <factor>",
		privs = { debug = true },
		func = function(pn,param)
			local effect = param:split()[1]
			local factor = tonumber(param:split()[2])
			if mcl_status_effects.registered_effects[effect] then
				mcl_status_effects.start_effect(minetest.get_player_by_name(pn), effect, { factor = factor })
				return true, "Effect ".. tostring(effect) .. " started"
			end
			return false, "Effect ".. tostring(effect) .. " does not exist"
		end
	})
end)

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
			mcl_status_effects.add_hp(obj, hp, "healing")
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
			mcl_status_effects.add_hp(obj, hp, "healing")
		end
	end,
})

mcl_status_effects.register_effect("night_vision",{
	color = "#1F1FA1",
	on_start = function(obj, def, data)
		if obj:is_player() then
			local meta = obj:get_meta()
			meta:set_int("nigh_vision",1)
			mcl_weather.skycolor.update_sky_color({obj})
		end
	end,
	on_stop = function(obj, def, data)
		if obj:is_player() then
			local meta = obj:get_meta()
			meta:set_int("nigh_vision",0)
			mcl_weather.skycolor.update_sky_color({obj})
		end
	end,
	factor = 1.2,
	duration = 30,
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
	factor = 1.15,
	duration = 30,
})


