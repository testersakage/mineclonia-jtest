--------------------------------------------------------------------------
-- Feature generation environment registration.
--------------------------------------------------------------------------

print ("* Initializing async environment")

mcl_levelgen.load_feature_environment = true

-- Load `features.lua' a second time to define the feature generation
-- environment.
dofile (mcl_levelgen.prefix .. "/post_processing.lua")
dofile (mcl_levelgen.prefix .. "/features.lua")
mcl_levelgen.initialize_biome_features ()
mcl_levelgen.initialize_nodeprops_in_async_env ()
mcl_levelgen.initialize_portable_schematics ()
