# mcla_settings

This API allows creating and modifying per world settings.

Settings can be managed via chat command by users with the `server` privilege.

Setting names consist of 2 parts, a domain and a name. The domain should be
unique for your mod. This is used to allow settings in different mods to use the
same name.

Domain and name cannot contains a dot '.', if they do they will be rejected.

## Registering Settings

There is a function for each data type to register settings.

If the setting exists in the mod storage for this world then the value is not
changed when calling the register functions.

"help" is the help text for the setting.

### mcla_settings.register_bool(domain, name, default, help)

### mcla_settings.register(domain, name, default, help)

## Un-Registering settings

If a setting is no longer required it can be removed.

### mcla_settings.unregister(domain, name)

## Getting settings

### mcla_settings.get(domain, name)

## Updating settings

### mcla_settings.set(domain, name, value)

## Chat command

Users with the `server` privilege can interact with the world settings via the
`wset` chat command.

```/wset``` with no arguments displays all current settings and their values.

```/wset help``` displays all current settings with their help text.

```/wset name``` displays the value of the named setting.

```/wset name value``` changes the value of the named setting to the provided
value.
