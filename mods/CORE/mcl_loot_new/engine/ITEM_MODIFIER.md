# Item Modifiers

An item modifier modifies an itemstack in some way. It is specified as a table with a "function" field, and other optional fields

Optional fields for all functions:
- "conditions": Array of predicates all of which must pass in order for this modifier to be used

## List of item modifier types ("function" values):

### "set_count"

Sets the number of items in the itemstack

Params:
- count (required): number provider
- add: bool (default = false) - whether add `count` items on to the current stack size, or set the stack size to `count` items

### "enchant_randomly"

Applies one random enchantment to the itemstack, or none if no applicable enchantments can be applied
See `mcl_enchanting.enchant_uniform_randomly_from`

Params:
- options: array[enchantment name] (default = mcl_enchanting.all_enchantments) - which enchantments to select from
- only_compatible: bool (default = true) - whether to limit enchantments to those "compatible" with the item being enchanted (UNTESTED)

### "lua_function"

NON-MC item modifier: applies a lua function to the itemstack
This is discouraged, try to use a standard item modifier or implement a new one instead

- value (required): function[(ItemStack, loot context) -> ItemStack] - The lua function to apply. No fields of "loot_context" are guarunteed