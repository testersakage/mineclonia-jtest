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
        --self._stars = core.deserialize(properties.stars)

        core.add_particlespawner({
            attached = self.object,
            amount = math.ceil(15 * self._flight_duration),
            maxpos = vector.new(0.25, -1, 0.25),
            minpos = vector.new(-0.25, -1, -0.25),
            maxexptime = 0.75,
            minexptime = 1.25,
            maxvel = vector.zero(),
            minvel = vector.zero(),
            maxsize = 1.25,
            minsize = 0.75,
            collisiondetection = false,
            vertical = true,
            texture =  "mcl_particles_instant_effect.png"
        })
    end,
    on_step = function(self, dtime)
        self.object:set_velocity(vector.new(0, self.initial_properties._climb_speed, 0))
        self._flight_duration = self._flight_duration - dtime

        if self._flight_duration <= 0 then
            self.object:remove()
        end
    end
})
