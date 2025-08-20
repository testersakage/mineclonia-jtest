------------------------------------------------------------------------
-- Skybox and weather support for client-side players.
------------------------------------------------------------------------

function mcl_serverplayer.update_skybox (state, player, dtime)
	local self_pos = player:get_pos ()
	local node_pos = mcl_util.get_nodepos (self_pos)
	local _, dim = mcl_worlds.y_to_layer (node_pos.y)
	local skybox_data = state.skybox_data or {}
	local biome_sky_color
		= mcl_biome_dispatch.get_sky_color (node_pos)
	local biome_fog_color
		= mcl_biome_dispatch.get_fog_color (node_pos)
	local weather_state = mcl_weather.state
	local update_p = false

	if biome_sky_color ~= skybox_data.biome_sky_color
		or biome_fog_color ~= skybox_data.biome_fog_color
		or weather_state ~= skybox_data.weather_state then
		update_p = true
	end

	skybox_data.biome_sky_color = biome_sky_color
	skybox_data.biome_fog_color = biome_fog_color
	skybox_data.weather_state = weather_state

	if update_p then
		mcl_serverplayer.send_effect_ctrl (player, skybox_data)
	end

	local tod_update_timer = (state.tod_update_timer or 0) + dtime
	if tod_update_timer > 0.5 or dim ~= state.last_dimension then
		tod_update_timer = 0
		if dim == "end" then
			player:override_day_night_ratio (0.5)
		elseif dim == "nether" or dim == "void" then
			player:override_day_night_ratio (nil)
		elseif weather_state == "rain" then
			local tod = core.get_timeofday ()
			local ratio = core.time_to_day_night_ratio (tod) * 0.85
			player:override_day_night_ratio (ratio)
		elseif weather_state == "thunder" then
			local tod = core.get_timeofday ()
			local ratio = core.time_to_day_night_ratio (tod) * 0.675
			player:override_day_night_ratio (ratio)
		else
			player:override_day_night_ratio (nil)
		end
	end

	state.last_dimension = dim
	state.tod_update_timer = tod_update_timer
	state.skybox_data = skybox_data
end
