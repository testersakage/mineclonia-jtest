This mod implements a level generator whose object is to reproduce
Minecraft's terrain and biome system, generating identical worlds from
identical seeds.  It is enabled by selecting the mapgen "singlenode".

Three flags may be set in map_meta.txt to configure this level
generator in a world-specific manner:

1. mcl_levelgen_use_large_biomes = true

Enable ``Large Biomes'' level generation, where the biome noise maps
are roughly 8x larger than in standard levels.

2. mcl_levelgen_enable_ersatz = true

Enable the generation of select structures when a standard Luanti
mapgen is enabled.  This option presently requires a modified version
Luanti/Minetest, available at:

  https://codeberg.org/halon/Minetest

3. mcl_init_disable_levelgen = true

Disable this level generator when the "singlenode" mapgen is active,
effectively restoring the usual significance of "singlenode".

Mods (such as implement Lua map generators themselves) may also
request that the original significance of "singlenode" be restored by
creating a single file in their root directories as
`mcl_levelgen.conf' with the following directive:

  disable_mcl_levelgen = true



The question has been raised how this level generator was implemented
without reference to decompiled Minecraft source code (or other
encumbered material).  During its implementation, the author was at
great pains to avoid any contamination by Minecraft source code, and
in its place, exploited the copious quantity of public documentation
on Minecraft level generation in such locations as the Mojang issue
tracker, the Spigot/Bukkit forums, Minecraft-related IRC channels,
GitHub "gists", and the all-important Yarn project, by which the
author was informed in writing and linking numerous tests and
experiments against unaltered and standalone Minecraft class files;
this being the means by which features not otherwise specified below
were reverse-engineered and reimplemented.

Carvers were initially drafted by the author, but a programmer who
stood on personally familiar terms with the author and with some
experience in Minecraft modding was recruited to render their
execution consistent with Minecraft.

Surface rules and level presets were obtained by tracing the execution
of an unmodified copy of the Minecraft data generator
(https://docs.minecraftforge.net/en/latest/datagen/) by means of
`btrace' (https://github.com/btraceio/btrace) and a number of other
JVM instrumentation tools without the involvement of any decompiler or
Microsoft-copyrighted deobfuscation mappings.  The same is true of the
procedurally generated structures: Mineshafts, Nether Fortresses,
Strongholds, Ocean Monuments, Desert Pyramids, and so forth.
Execution tracing was also used to establish the precise placement
conditions of most other structures.

https://misode.github.io/ was used as a reference as regards built-in
structure, feature, and biome definitions, for comparative
benchmarking, and for debugging the aquifer and density function
implementations.  Its implementation appeared to be an overt
transcription of Mojang source code into Javascript and was never
consulted.

All documentary sources which contributed to one component of the
level generator are referenced in the commentary of the file
implementing the component at issue.

No effort whatever has been expended towards replicating the
generation of structures which are derived from Mojang-copyrighted
schematics/templates.
