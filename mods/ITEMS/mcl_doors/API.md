# mcl_doors

## mcl_doors:register_door(name, def)
Function used to register a new door
* `name`: the name of the door (itemstring, modname:door_name)
* `defs`: A table with the following fields:
    * `description`: door description
    * `groups`: door groups
    * `inventory_image`: door item inventory image
    * `tiles_bottom`: the tiles of the bottom part of the door {front, side}
    * `tiles_top`: the tiles of the bottom part of the door {front, side}

If the following fields are not defined the default values are used:

* `node_box_bottom`: box, default value is {-0.5, -0.5, -0.5, 0.5. 0.5, -0.3125}
* `node_box_top`: box, default value is {-0.5, -0.5, -0.5, 0.5. 0.5, -0.3125}
* `only_placer_can_open`: if true only the player who placed the door can open it
* `only_redstone_can_open`: if true, the door can only be opened by redstone, not by rightclicking it
* `selection_box_bottom`: box, default value is {-0.5, -0.5, -0.5, 0.5. 0.5, -0.3125}
* `selection_box_top`: box, default value is {-0.5, -0.5, -0.5, 0.5. 0.5, -0.3125}

## mcl_doors:register_trapdoor(name, def)
