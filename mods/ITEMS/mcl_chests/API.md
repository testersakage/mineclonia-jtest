# mcl_chests

This mod alllows registering chests.

## Registering a Chest

`mcl_chests.register_chest` simplifies the process of creating a chest.

```lua
mcl_chests.register_chest({
	--name of the chest
	basename = "modname:custom_chest",
	
	--localized description of the chest
        desc = S("Custom Chest"),
	
	--long description of the chest in the item tooltip
        long_desc = S("Long description."),
        
	--usage help
	usage_help = S("Usage help."),
	
	--tooltip help
        tt_help = S("27 inventory slots") .. "\n" .. S("Can be combined to a large chest"),
        
	--textures for the chests
	tiles_table = {
		--textures for the small chest
                small = { "modname_chest_normal.png" },
		
		--textures for the double chest
                double = { "modname_chest_double.png" },
		
		--textures shown in the inventory
                inv = { "modname_chest_top.png", "modname_chest_bottom.png",
                        "modname_chest_right.png", "modname_chest_left.png",
                        "modname_chest_back.png", "modname_chest_front.png" },
        },
	
	--whether is help entry is hidden
        hidden = false,
	
	--definition table (for adding additional entries to the definition table)
	overrides = {
		
	}
},
--called when small chest is right-clicked
function(node, pos, clicker),

--called when left part of the double chest is right-clicked
function(node, pos, clicker),

--called when right part of the double chest is right-clicked
function(node, pos, clicker),
)
```
