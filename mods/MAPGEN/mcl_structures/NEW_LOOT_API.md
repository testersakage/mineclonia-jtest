## Schematic metadata format

place_schematic will support a new argument type:

schematic = {main= ..., meta=(filename or lua table)}
The filename refers to a zstd compressed file containing a lua table accepted by `core.deserialize`
If a filename is given, the table cannot contain functions as loading will happen via core.deserialize with safe=true
The table's keys are arrays of the form {x, y, z} (in structure-space)
The values are themselves tables, of which each key-value pair is loaded into the metadata of the node at {x, y, z}

BREAKAGES:
    - Schematic tables with the `main` and `meta` attributes will now be misinterpreted as the new format
    However, neither of these keys are part of the schematic format so it seems unlikely they would be used

## Loot filling

After placement, containers are filled with loot
Any nodes in the metadata file whose new metadata had the key "mcl_structures_loot_table" will have loot metadata added to them and this key removed
You should NOT set the "loot_table" meta directly as this will make mapgen non-deterministic as the seed will be unspecified