# mcl_tools

## Description
This mod is responsible for adding tools to Mineclonia. An API that registers a complete set based on a material or adds a new tool to existing material sets.

## API functions
### `mcl_tools.register_set(setname, materialdefs, tools, overrides)`:
Registers a complete set of tools based on a material.

- `setname`: _string_ with the name of the set (recommended to use the name of the material, for example **iron**).
- `materialdefs`: _table_ that must contain the following fields:

    - craftable: _boolean_ that determines whether tools can be crafted at the crafting table (false for netherite tools).
    - material: _string_ with the name or group of items used as crafting/repair material for tools.
    - uses: _integer_ number of tool uses.
    - level: _integer_
    - speed: _number_ which acts as a multiplier for the group's digging speed. If omitted, it will receive the value 1, defined by _mcl_autogroup.
    - max_drop_level: _integer_ that contains the tool's tier level. This number determines whether certain blocks will drop items.
    - groups: _table_ containing groups for all tools on the set. Tools typically use the `dig_speed_class` and `enchantability` groups. Other groups can be determined from this table.

- `tools`: _table_ that can contain the following fields (See the Examples section in the tools subsection):

    - ["pick"]: _table_ containing **pickaxe** definitions;
    - ["shovel"]: _table_ containing **shovel** definitions;
    - ["sword"]: _table_ containing **sword** definitions;
    - ["axe"]: _table_ containing **axe** definitions;
    - ["hoe"]: _table_ containing **hoe** definitions;

- `overrides`(**optional**): _table_ containing optional parameters for all tools in the set (e.g. _mcl_cooking_output, _doc_items_hidden).

### `mcl_tools.add_to_sets(toolname, commondefs, tools, overrides)`:
Adds a new tool to existing material sets.

- `toolname`: _string_ with the name of the tool (for example **shovel**).
- `commondefs`: _table_ that can contain the following fields:

    - `longdesc`: _string_ containing a long description for the tool type (used on _doc_items_longdesc).
    - `usagehelp`: _string_
    - `groups`: _table_ containing groups related to the tool type (e.g. hoe, sword, pickaxe) and a group to determine whether it is a tool or a weapon(tool or weapon).
    - `diggroups`: _table_ containing the diggroups for this tool type (e.g hoey, swordy, swordy_cobweb).
    - `craft_shapes`: _table_ containing craft shapes for the tool (see examples in the Examples section).

- `tools`: _table_ that can contain the same fiels as `tools` from `register_set`.
- `overrides` (**optional**): _table_ that can contain the same fiels as `overrides` from `register_set`.

## Examples

### `groups` on `register_set`:

```lua
-- groups of Netherite Pickaxe. Note the usage of fire_immune group.
groups = { dig_class_speed = 6, enchantability = 10, fire_immune = 1 }
```

### `groups` on `add_to_sets`

```lua
-- groups of a pickaxe.
groups = { pickaxe = 1, tool = 1 }
```

### `tools`:

```lua
-- Definitions for Wooden Pickaxe. If any of these fields are omitted, problems may occur using the tool.
["pick"] = {
    description = S("Wooden Pickaxe"),
    inventory_image = "default_tool_woodpick.png",
    tool_capabilities = {
        full_punch_interval = 0.83333333,
        damage_groups = { fleshy = 2 }
    }
}
```

### `craft_shapes`:

```lua
-- Craft shapes for hoes
-- "material" will be replaced by material from materialdefs.
-- Note that the definition already contains "mcl_core:stick" as another crafting material.
-- The use of "mcl_core:stick" is not mandatory. Other items may be used.
-- A tool can have more than one craft_shape if its crafting recipe can be mirrored on the crafting grid.
craft_shapes = {
	{
		{ "material", "material" },
		{ "mcl_core:stick", "" },
		{ "mcl_core:stick", "" }
	},
	{
		{ "material", "material" },
		{ "", "mcl_core:stick" },
		{ "", "mcl_core:stick" }
	}
}
```

## Licenses
* `default_shears_cut.ogg` from [Free Sound](https://freesound.org/people/SmartWentCody/sounds/179015/) by SmartWentCody, CC-BY-SA 3.0.
