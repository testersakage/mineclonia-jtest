# API for `mcl_furnaces`

Register your own furnaces.

## Quick start

Simple way of registering a new furnace, the `spongedryer`:

```
mcl_wood.register_furnace("spongedryer",{
	_mcl_furnace_groups = {
		sponge = 2, --items of group sponge will cook at twice the rate
	},
	normal = {
		tiles = { "spongedryer.png" }, --tiles for the inactive furnace
		--any node definition overrides for the inactive furnace
	},
	active = {
		tiles = { "spongedryer.png" }, --tiles for the active furnace
		--any node definition overrides for the active furnace
	}
})
```
