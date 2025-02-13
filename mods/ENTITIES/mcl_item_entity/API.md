# mcl_item_entity
## Credits
Originally ported from mtg item entity by Pilzadam (WTFPL)
## Callbacks
### Item definition
#### _on_set_item_entity = function(stack, luaentity)
* Called when an item is converted to an item entity (i.e. "dropped").
* Should return the stack and optionally as a second argument modified object properties to be applied to the entity.
#### _on_entity_step = function(luaentity, dtime, itemstring)
* Called on every step when the item is in entity form (item entity, itemframe).
* May return the modified itemstring which will be applied to the item entity.
