# `mcl_immortality`

Adds utils to control players immortality.

## ``mcl_immortality.is_immortal(player: ObjectRef)``

Check whether `player` is immortal. Return bool on success, nil on error.

## ``mcl_immortality.set_immortal(player: ObjectRef, [flag: bool])``

Sets immortality for `player` to `flag`.

`flag` is optional. If absent, flips the setting (`true` -> `false` and `false` -> `true`).

`/!\` Does not perform any privilege checks `/!\`

## Privileges

### `immortality`

Grants ability to change immortality for self.

On revoke: sets user back to mortal and revokes `immortality_others` if present.

### `immortality_others`

Grants ability to change others immortality.

Cannot exist without plain `immortality` priv, grants it if absent.
