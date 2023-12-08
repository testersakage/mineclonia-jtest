# mcl_settings

This API allows per world settings. These settings can be based on game settings
visible in the main minetest menu, or hidden settings.

To take advantage of this use `mcl_settings.` instead of `minetest.settings.`.

All settings can be managed in game via the `wset` chat command by users with
the `server` privilege.

## Getting settings

### mcl_settings.get(name, [default])

### mcl_settings.get_bool(name, [default])

## SettingUpdating settings

Note that how you structure the command to the setting will control if the value
gets automatically added to the mcl_settings.con file.

If you want the default value to be automatically written to the world config
file then you supply a default, like this:

```lua
local fu = tonumber(mcl_settings.get("fu", 11))
```

If you do not want the default value to be automatically written to the world
config file then you set the default outside the function call, like this:

```lua
local fu = tonumber(mcl_settings.get("fu")) or 11
```

### mcl_settings.set(name, value)

### mcl_settings.set_bool(name, value)

## Chat command

Users with the `server` privilege can interact with the world settings via the
```wset``` chat command.

```/wset``` with no arguments displays all current settings and their
values.

```/wset name``` displays the value of the named setting.

```/wset name value``` changes the value of the named setting to the
provided value.
