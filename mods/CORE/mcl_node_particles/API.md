# API for `mcl_node_particles`
Register particlespawners for node types

## `mcl_node_particles.register_particlespawner(nodename, psdef, overrides)`
* nodename - the nodename this particlespawners applies to
* psdef - particlespawner definition
* overrides - function(pos, player) - function that shall return nil or a table
    containing particlespawner definition fields that will override the
    particlespawner ultimately used
