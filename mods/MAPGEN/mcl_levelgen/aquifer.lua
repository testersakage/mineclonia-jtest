------------------------------------------------------------------------
-- Aquifer processing.
------------------------------------------------------------------------

local cid_air, cid_water_source, cid_lava_source

if core and core.get_content_id then
	cid_air = core.CONTENT_AIR
	cid_water_source = core.get_content_id ("mcl_core:water_source")
	cid_lava_source = core.get_content_id ("mcl_core:lava_source")
else
	cid_air = 0
	cid_water_source = 3
	cid_lava_source = 4
end

local aquifer = {
	preset = nil,
	sea_level = nil,
	cid_default_fluid = nil,
}

-- Default Overworld aquifer.
local mathmin = math.min

function aquifer:get_node (x, y, z, density)
	local sea_level = self.sea_level
	if y < mathmin (-54, sea_level) then
		return cid_lava_source, 0
	elseif y <= sea_level then
		return self.cid_default_fluid, 0
	end
	return cid_air
end

function mcl_levelgen.create_default_aquifer (preset)
	local aquifer = table.copy (aquifer)
	aquifer.sea_level = preset.sea_level
	if core then
		aquifer.cid_default_fluid
			= core.get_content_id (preset.default_fluid)
	else
		aquifer.cid_default_fluid = cid_water_source
	end
	return aquifer
end

------------------------------------------------------------------------
-- Noise-based aquifers.
-- https://maven.fabricmc.net/docs/yarn-1.21.5+build.1/net/minecraft/world/gen/chunk/AquiferSampler.Impl.html
------------------------------------------------------------------------

local PROPAGATION_XZ = 10
local PROPAGATION_Y = 9
local PROPAGATION_Z = 10

local XZ_SEPARATION = 6
local Y_SEPARATION = 3

local GRID_XZ = 16
local GRID_Y = 12

local CHUNK_POS_OFFSETS = {
	{0, 0},
	{-2, -1},
	{-1, -1},
	{0, -1},
	{1, -1},
	{-3, 0},
	{-2, 0},
	{-1, 0},
	{1, 0},
	{-2, 1},
	{-1, 1},
	{0, 1},
	{1, 1},
}
