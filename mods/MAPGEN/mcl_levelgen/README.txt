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
