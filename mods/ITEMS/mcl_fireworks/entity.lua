core.register_entity("mcl_fireworks:rocket", {
	_flight_duration = 1.5,
	_climb_speed = 15,
	_effect = {
		colors = { "red", "green", "orange", "blue" },
		shape = "burst",
		effects = { "trail" },
	},
	initial_properties = {
		collide_with_objects = false,
		glow = 14,
		physical = true,
		pointable = false,
		textures = {"mcl_fireworks_rocket.png"},
		visual = "upright_sprite",
	},
	on_activate = function(self, staticdata)
		local properties = core.deserialize(staticdata)

		if not properties then return end

		self._flight_duration = properties.flight_duration or self._flight_duration
		--self._effect = properties.effect or self._effect

		self._trail_spawner = core.add_particlespawner({
			attached = self.object,
			amount = math.ceil(15 * self._flight_duration),
			maxpos = vector.new(0.25, -1, 0.25),
			minpos = vector.new(-0.25, -1, -0.25),
			maxvel = vector.zero(),
			minvel = vector.zero(),
			maxsize = 1.25,
			minsize = 0.75,
			collisiondetection = false,
			vertical = true,
			texture =  "mcl_particles_instant_effect.png",
			time = 0,
		})
		self.object:set_velocity(vector.new(0, self._climb_speed, 0))
	end,
	on_deactivate = function(self)
		if self._trail_spawner then
			core.delete_particlespawner(self._trail_spawner)
		end
	end,
	on_step = function(self, dtime)
		self._flight_duration = self._flight_duration - dtime

		if self._flight_duration <= 0 then
			self:_explode()
		end
	end,
	_explode = function(self)
		local shape = self._effect.shape or "ball"
		if shape then
			local effect = mcl_fireworks.registered_shapes[shape]
			if effect then
				if effect.func then
					effect.func(self)
				end
			end
		end

		self.object:remove()
	end,
})
