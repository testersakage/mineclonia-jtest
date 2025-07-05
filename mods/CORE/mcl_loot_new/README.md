
## API

### Loot materialisation

Loot is materialised in a 
(barrel, chest, trapped chest, hopper, dispenser, dropper, shulker box, dyed shulker box, and decorated pot)
whenever:
    - The container node is rightclicked by a player (`on_rightclick`)
        - [ ] Barrel
        - [x] Chest
        - [x] Trapped chest
        - [ ] Hopper
        - [ ] Dispenser
        - [ ] Dropper
        - [x] Shulker Box
        - [ ] Decorated pot
    - An item is transferred into or out of the container node by any means (`on_metadata_inventory_*`)
        - [ ] Barrel
        - [x] Chest
        - [x] Trapped chest
        - [ ] Hopper
        - [ ] Dispenser
        - [ ] Dropper
        - [x] Shulker Box 
        - [ ] Decorated pot
    - A hopper pulls/pushes an item out of/into the container node (`_on_hopper_*`)
        - [ ] Barrel
        - [x] Chest
        - [x] Trapped chest
        - [ ] Hopper
        - [ ] Dispenser
        - [ ] Dropper
        - [x] Shulker Box
        - [ ] Decorated pot
    - The container node is dug (`after_dig_node`)
        - This is done even for shulker boxes (I don't know if this is consistent with MC)
        - [ ] Barrel
        - [x] Chest
        - [x] Trapped chest
        - [ ] Hopper
        - [ ] Dispenser
        - [ ] Dropper
        - [x] Shulker Box
        - [ ] Decorated pot

### `mcl_loot_new`

Functions:
- `register_loot_table(table_name, table_spec)`: Register a new loot table
    `table_name`: Name of new table
    `table_spec`: Table definition in the loot table format
    Returns: nil
- `loot_table_exists(table_name)`: Check whether a loot table exists
    `table_name`: Name of table to check
    Returns: boolean value
- `container_insert_loot(pos, inv, loot_table, context, seed)`
- `sample_table(table_name, context, pr)`
- `materialise_container_loot(pos, player)`

Tables:
- `loot_context`: Contains functions for generating loot context
- `loot_tables`: Please don't touch, these is where the loot table definitions are stored

#### `mcl_loot_new.loot_context`

Functions:
- `generate_for_chest(pos, player)`


## Loot Context Parameters

`origin`: table with keys x, y, z representing a 3D coordinate
`doer`: (corresponds to `this` in Java) an entity which is the 'source' of the action which generates loot

Loot context types:

| Loot context type | Uses                                    | Non-nil parameters      | Maybe `nil` parameters                               |
|-------------------|-----------------------------------------|-------------------------|------------------------------------------------------|
| `chest`           | A container with a loot table is opened | `origin`: container pos | `doer`: player ObjRef which opened container, if any |
|                   |                                         |                         |                                                      |
|                   |                                         |                         |                                                      |