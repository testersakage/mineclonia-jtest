# mcl_settings

This APi allows creating and modifying epr world settings. These settings can be
based on game settings available in the main minetest menu, or code only
settings.

Once defined settings can be managed via chat command by users with the `server`
privilege.

## Registering Settings

There is a function for each data type to register settings.

If the setting exists in the mod storage for this world then the value is not
changed when calling the register functions.

### mcl_world_settings.register(name, default, description, help)

### mcl_world_settings.register_bool(name, default, description, help)

## Un-Registering settings

If a setting is no longer required it can be removed.

### mcl_world_settings.unregister(name)

## Getting settings

### mcl_world_settings.get(name)

## Updating settings

### mcl_world_settings.set(name, value)

## Chat command

Users with the `server` privilege can interact with the world settings via the
```world_settings``` chat command.

```/world_settings``` with no arguments displays all current settings and their
values.

```/world_settings info``` displays all current settings with their
descriptions.

```/world_settings help``` displays all current settings with their help text.

```/world_settings name``` displays the value of the named setting.

```/world_settings name value``` changes the value of the named setting to the
provided value.
