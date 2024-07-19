# mcl_tools

## Description
This mod is responsible for adding tools to Mineclonia.

## API functions

### `mcl_tools.register_set(material, tools, overrides)`

#### Description
This function registers the complete set of tools from the same material. The three parameters of the function must be tables containing certain information. For each table, we have:

##### `material`
This table must contain this information:
* `name`: a string with the tool material register name (e.g. <span style="color:gold">"iron"</span>).
* `craftable`: a boolean value to define whether the set can be crafted normally at the crafting table. Recommended to use false only for a set of tools that are only obtained through upgrades or through looting.
* `material`: a string containing the itemstring or group of items that can be used to craft and/or repair tools (e.g. <span style="color:gold">"mcl_core:iron_ingot"</span> or <span style="color:gold">"group:wood"</span>).
* `uses`: an integer with the total number of uses that the material can provide for the tools.
* `level`: an integer that contains the tool's tier level. This number determines whether certain blocks will drop items.
    ###### Mineclonia materials level
    * <span style="color:sienna">**1: wood**</span>
    * <span style="color:gold">**2: gold**</span>
    * <span style="color:gray">**3: stone**</span>
    * <span style="color:gainsboro">**4: iron**</span>
    * <span style="color:cyan">**5: diamond**</span>
    * <span style="color:black">**6: netherite**</span>
* `speed`:
* `max_drop_level`:
* `groups`: a table containing common groups relating to the material. Groups are common to all registered tools in the set.

##### `tools`
This table contains subtables, indexed by tool names according to the following format:
```lua
{
    ["tool_name"] = {}
}
```

Mineclonia has five tool names that are recognized by this API:
* <span style="color:firebrick">**axe**</span>
* <span style="color:firebrick">**hoe**</span>
* <span style="color:firebrick">**pick**</span>
* <span style="color:firebrick">**shovel**</span>
* <span style="color:firebrick">**sword**</span>

Each subtable must contain individual information for each tool. All definitions in the material and overrides tables apply to all tools in the set. However, the definitions of these subtables only apply to the tool relative to the tool name. All subtables must contain the following fields:
* `description`: must contain the description relating to the tool (e.g. S(<span style="color:gold">"Iron Pickaxe"</span>)).
* `inventory_image`: also a string with the name of the texture that should be used in the inventory. If omitted, the function will attempt to search for a texture with a default name. The pattern followed is: <span style="color:green">**mod_name**</span><span style="color:red"> **..** </span><span style="color:gold">**"_"**</span><span style="color:red"> **..** </span><span style="color:green">**tool_name**</span><span style="color:red"> **..** </span><span style="color:gold">**"_"**</span><span style="color:red"> **..** </span><span style="color:green">**material_name**</span><span style="color:red"> **..** </span><span style="color:gold">**".png"**</span>

* `tool_capabilities`:

##### `overrides`
The `overrides` table is optional. The use of this table is intended to use special fields in all tools in the set. An example of the use of `overrides` is the wooden tool set. These tools can be used as fuel. To do this, they use the `_mcl_burntime` field which is passed to all tools through `overrides`.

```lua
-- mcl_tools/register.lua/line 49
{ _mcl_burntime = 10 }
```

## Credits

### Sounds
* `default_shears_cut.ogg`
    * Author: SmartWentCody (CC BY 3.0)
    * Source: <https://freesound.org/people/SmartWentCody/sounds/179015/>

### Textures
