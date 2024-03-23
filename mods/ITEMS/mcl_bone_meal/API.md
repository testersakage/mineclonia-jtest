# mcl_bone_meal

## Bone meal API

### _on_bone_meal = function(itemstack, placer, pointed_thing)
This function is called when the field is defined in a node definition
and the node is righclicked (on_place) with bone meal.

It will check for protection and creative mode, show the bone meal particles
and take an item from the wielded bonemeal stack unless the function return false.
