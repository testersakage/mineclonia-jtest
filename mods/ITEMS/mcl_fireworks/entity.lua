core.register_entity("mcl_fireworks:rocket", {
    _flight_duration = 0,
    _stars = {},
    initial_properties = {
        _climb_speed = 15,
        collide_with_objects = false,
        glow = 14,
        physical = true,
        pointable = false,
        textures = {"mcl_fireworks_rocket.png"},
        visual = "sprite",
    },
    on_activate = function(self, staticdata)
        local properties = core.deserialize(staticdata)

        if not properties then return end

        self._flight_duration = properties.flight_duration
    end,
    on_step = function(self, dtime, moveresult)
        self.object:set_velocity(vector.new(0, self.initial_properties._climb_speed, 0))
        self._flight_duration = self._flight_duration - dtime

        core.add_particle({
            pos = self.object:get_pos(),
            expirationtime = 1,
            velocity = vector.zero(),
            size = 1,
            collisiondetection = false,
            vertical = true,
            texture = "mcl_particles_instant_effect.png"
        })

        if self._flight_duration <= 0 then
            self.object:remove()
        end
    end
})
