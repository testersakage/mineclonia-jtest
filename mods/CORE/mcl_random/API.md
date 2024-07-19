# mcl_random

This mod provides a central place to configure than rng backend to be used for a
world as well as access to oneoff random numbers and PseudoRandom compatible rng
instances.

The rng backend should normally not be changed in an existing world, because
that will break mapgen reproducability/continuity.


## Rng backends
* `"PseudoRandom"`
    * backwards compatible with worlds created using older Mineclonia versions,
      but not recommended for new worlds, because of the various quirks of
      PseudoRandom
* `"PseudoRandom_limited"`
    * uses PseudoRandom, but limits all seeds to the range 0..2^15-1
    * this avoids PseudoRandom problems, but is not backwards compatible with
      worlds created using older Mineclonia versions
    * not recommended, but usable for new worlds
* `"PcgRandom"`
    * uses PcgRandom
    * recommended for new worlds
* `"PcgRandom_secure"`
    * uses PcgRandom
    * generates seeds for oneoff rngs using SecureRandom
    * experimental, compatible with `"PcgRandom"`, usable for new worlds

## Settings
* `"use_world_rng"` in `mcl_random.conf` in the world path
    * this setting overrides default and `minetest.conf` settings
    * if this setting doesn't exist during startup of the world, it is set to
      the appropriate default value
* `"mcl_secret_setting_use_world_rng"` in `minetest.conf`
    * the setting to be used for worlds that don't yet have their config
      updated
* if none of the above is set, the `"PseudoRandom"` backend is used


## Functions

`mcl_random.get_random(seed)`
    * returns a `PseudoRandom` compatible rng instance
    * if `seed` is `nil`, a random seed is used
`mcl_random.random(min, max, context)`
    * use a `context` specific rng to return a random number between `min` and
      `max` inclusive
    * if `context` is `nil`, the global context is used
    * `context`s that are allowed player names, [a-zA-Z0-9-_]+, are reserved for
      player related contexts; mods should use `mod_name:context` for non player
      related contexts