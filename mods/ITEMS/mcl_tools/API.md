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
    - groups: _table_

- `tools`: _table_ that can contain the following fields:

    - ["pick"]: _table_ containing **pickaxe** definitions;
    - ["shovel"]: _table_ containing **shovel** definitions;
    - ["sword"]: _table_ containing **sword** definitions;
    - ["axe"]: _table_ containing **axe** definitions;
    - ["hoe"]: _table_ containing **hoe** definitions;

- `overrides`(**optional**): _table_

### `mcl_tools.add_to_sets(toolname, commondefs, tools, overrides)`:
Adds a new tool to existing material sets.

- `toolname`: _string_ with the name of the tool (for example **shovel**).
- `commondefs`: _table_
- `tools`: _table_ that can contain the same fiels as `tools` from `register_set`.
- `overrides` (**optional**): _table_

## Licenses
* `default_shears_cut.ogg` from [Free Sound](https://freesound.org/people/SmartWentCody/sounds/179015/) by SmartWentCody, CC-BY-SA 3.0.
