# mcl_torches
## Description:
This mod changes the default torch drawtype from "torchlike" to "mesh",
giving the torch a three dimensional appearance. The mesh contains the
proper pixel mapping to make the animation appear as a particle above
the torch, while in fact the animation is just the texture of the mesh.

Originally, this mod created in-game alternatives with several
draw styles.  The alternatives have been removed and instead of
providing alternate nodes, this mod now directly modifies the existing
nodes. Conversion from the wallmounted style is done through an LBM.

Torches is meant for minetest-0.4.14, and does not directly support
older minetest releases. You'll need a recent git, or nightly build.

## Changes for Mineclonia:
- Torch does not generate light when wielding
- Torch drops when near water
- Torch can't be placed on ceiling
- Simple API

## API functions:
* `mcl_torches.register_torch(def)`: Used to register torches. Automatically registers wall-mounted variants. `def` must be a table that contains the following keys:
    * `name`: _string_ used as torch name;
    * `description`: _string_ used as description in game inventory (can be translated);
    * `doc_items_longdesc`: _string_ used to give descriptions about the torch item in in-game documentation (can be translated);
    * `doc_items_hidden`: _boolean_
    * `icon`: _string_ with the file name of the torch icon texture in the inventory and when held by the player (`inventory_image` and `wield_image`);
    * `tiles`: _table_ used to determine the torch textures.
    * `light`: _int_ used to determine how much light the torch produces (light_source).
    * `groups`: _table_ containing individual groups for the torch. Other groups are automatically defined by the function.
    * `sounds`: _table_ containing the sounds used by the engine. These sounds are used in certain actions such as placing, digging, walking on, etc.
    * `particles`: _table_ containing definitions of particles that torches emit when placed in the world. See the explanation below to better understand how to use this key.

    ### `particles`:
    `particles` table uses two special keys: `smoke` and `flame`. `smoke` must be a table containing three special keys, which are:
    * `maxpos_to_add`: _vector_ used to determine the maximum position where the smoke particle can spawn relative to the torch.
    * `minpos_to_add`: _vector_ which, like the previous key, is used to limit the spawn range of the smoke particles in relation to the torch.
    * `ps_defs`: _table_ containing the particlespawner definition parameters. See [Definition Tables](https://api.luanti.org/definition-tables/), in the `ParticleSpawner` section. All parameters listed there can be used here.

    `flame`, for now, must be a _string_ containing the texture of the flame particle that the torch emits. If omitted, the torch will not generate flame particles, as is the case with redstone torches. You can also omit the use of `smoke` to make the torch not emit smoke particles.

