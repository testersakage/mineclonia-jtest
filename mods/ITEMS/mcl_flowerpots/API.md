# mcl_flowerpots

## Functions:
* `mcl_flowerpots.register_potted(name, def)`: Used to register a plant that can be
  potted in a flower pot. Below is a description of the function parameters:
  * `name`: _itemstring_ of the item that will be potted when placed in the flower pot.
  As an example, to set the cactus as pottable, the `name` parameter must contain the cactus _itemstring_ ("mcl_core:cactus").
  * `def`: _table_ that should contain some parameters about the newly registered node. These
  parameters are:
    * `name`: _string_ that will serve as a suffix for the name of the new node to be created.
    Following the previous example, if you want to define the cactus as pottable, you can use
    the _string_ "cactus" as a suffix of the node to be created, which makes it called "mcl_flowerpots:flower_pot_cactus".
    * `desc`: _string_ with the node description. Like the node registry description, this can
    be translated using the engine translator.
    * `image`: _string_ with the name of the texture of the item that will be potted. The use of
    these parameters must follow some rules. For simple X-shaped flowers, the texture should be
    16x16 in size, as the default model's UV mapping predicts that the simple flower texture should
    be contained in the top left corner of a 32x32 texture, occupying the entire first quadrant
    (0,0 > 15,15) of that texture. For models other than the default, it is still possible for this parameter to contain 32x16 images (see mcl_bamboo/nodes.lua as an example). The default model
    still uses the second quadrant (16,0 > 31,15) of the 32x32 texture as the "root" texture. This
    is specifically used for the cactus (see "mcl_core/nodes_cactuscane.lua" as an example). The bottom quadrants (0,16 > 31,31) are intended exclusively for the flower pot texture with the default model. Unless otherwise desired, no texture should overlap these quadrants, i.e., they cannot be more than 16 pixels high.
    * `mesh` (**optional**): _string_ with the name of the model to use. If not defined, the function will use the default model and UV mapping will follow the rules described above.
    * `tiles` (**optional**): _table_ containing the textures you want to use. This parameter is optional so that it is possible to use more complex models that may require textures larger than 32x32. It can also be used in specific cases such as the cases defined in mcl_lush_caves/init.lua, where textures are reused from other nodes and it is not allowed to use the "combine" modifier in the `image` parameter.
* `mcl_flowerpots.register_potted_flower(name, def)` (**Deprecated**): Used to register flower
  pots containing simple flowers. Kept only for compatibility with older code.
* `mcl_flowerpots.register_potted_cube(name, def)` (**Deprecated**): Used to register pottable
  "roots", such as cactus. Kept only for compatibility with older code.
