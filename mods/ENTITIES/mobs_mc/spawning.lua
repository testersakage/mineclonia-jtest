-------------------------------------------------------------------------
-- Spawning initialization.
-------------------------------------------------------------------------

local only_peaceful_mobs
	= core.settings:get_bool ("only_peaceful_mobs", false)

mobs_mc.overworld_biomes = {
	"IcePlains",
	"IcePlainsSpikes",
	"ColdTaiga",
	"ExtremeHills",
	"ExtremeHillsM",
	"ExtremeHills+",
	"Taiga",
	"MegaTaiga",
	"MegaSpruceTaiga",
	"StoneBeach",
	"Plains",
	"SunflowerPlains",
	"Forest",
	"FlowerForest",
	"BirchForest",
	"BirchForestM",
	"RoofedForest",
	"Swampland",
	"Jungle",
	"JungleM",
	"JungleEdge",
	"JungleEdgeM",
	"BambooJungle",
	"MushroomIsland",
	"Desert",
	"Savanna",
	"SavannaM",
	"Mesa",
	"MesaBryce",
	"MesaPlateauF",
	"MesaPlateauFM",
	"MangroveSwamp",
	"LushCaves",
}

local n = #mobs_mc.overworld_biomes
for i = 1, n do
	local biome = mobs_mc.overworld_biomes[i]
	table.insert (mobs_mc.overworld_biomes, biome .. "_underground")
	table.insert (mobs_mc.overworld_biomes, biome .. "_ocean")

	if biome ~= "LushCaves" then
		table.insert (mobs_mc.overworld_biomes, biome .. "_deep_ocean")
		table.insert (mobs_mc.overworld_biomes, biome .. "_deep_underground")
	end
end
table.insert (mobs_mc.overworld_biomes, "DripstoneCave")

mobs_mc.farm_animal_biomes = {
	"ExtremeHills",
	"ExtremeHillsM",
	"ExtremeHills+",
	"Taiga",
	"MegaTaiga",
	"MegaSpruceTaiga",
	"StoneBeach",
	"Plains",
	"SunflowerPlains",
	"Forest",
	"FlowerForest",
	"BirchForest",
	"BirchForestM",
	"RoofedForest",
	"Swampland",
	"Jungle",
	"JungleM",
	"JungleEdge",
	"JungleEdgeM",
	"BambooJungle",
	"Savanna",
	"SavannaM",
	"MangroveSwamp",
}

local n = #mobs_mc.farm_animal_biomes
for i = 1, n do
	local biome = mobs_mc.farm_animal_biomes[i]
	table.insert (mobs_mc.farm_animal_biomes, biome .. "_underground")
	table.insert (mobs_mc.farm_animal_biomes, biome .. "_ocean")
	table.insert (mobs_mc.farm_animal_biomes, biome .. "_deep_ocean")
	table.insert (mobs_mc.farm_animal_biomes, biome .. "_deep_underground")
end

mobs_mc.monster_biomes = {
	"IcePlains",
	"IcePlainsSpikes",
	"ColdTaiga",
	"ExtremeHills",
	"ExtremeHillsM",
	"ExtremeHills+",
	"Taiga",
	"MegaTaiga",
	"MegaSpruceTaiga",
	"StoneBeach",
	"Plains",
	"SunflowerPlains",
	"Forest",
	"FlowerForest",
	"BirchForest",
	"BirchForestM",
	"RoofedForest",
	"Swampland",
	"Jungle",
	"JungleM",
	"JungleEdge",
	"JungleEdgeM",
	"BambooJungle",
	"Desert",
	"Savanna",
	"SavannaM",
	"Mesa",
	"MesaBryce",
	"MesaPlateauF",
	"MesaPlateauFM",
	"MangroveSwamp",
	"LushCaves",
}

local n = #mobs_mc.monster_biomes
for i = 1, n do
	local biome = mobs_mc.monster_biomes[i]
	table.insert (mobs_mc.monster_biomes, biome .. "_underground")
	table.insert (mobs_mc.monster_biomes, biome .. "_ocean")
	if biome ~= "LushCaves" then
		table.insert (mobs_mc.overworld_biomes, biome .. "_deep_ocean")
		table.insert (mobs_mc.overworld_biomes, biome .. "_deep_underground")
	end
end
table.insert (mobs_mc.monster_biomes, "DripstoneCave")

-------------------------------------------------------------------------
-- Default spawners.
-------------------------------------------------------------------------

-- Land animals.

local default_spawner = mcl_mobs.default_spawner
local animal_spawner = {
	spawn_category = "creature",
	spawn_placement = "ground",
}

function animal_spawner:test_supporting_node (node)
	return core.get_item_group (node.name, "grass_block") > 0
end

function animal_spawner:test_spawn_position (spawn_pos, node_pos, sdata, node_cache)
	local light = core.get_node_light (node_pos)
	if not light or light <= 8 then
		return false
	end
	local node_below = self:get_node (node_cache, -1, node_pos)
	if self:test_supporting_node (node_below) then
		if default_spawner.test_spawn_position (self, spawn_pos,
							node_pos, sdata,
							node_cache) then
			return true
		end
	end
	return false
end

mobs_mc.animal_spawner = animal_spawner

-- Aquatic animals.

local default_spawner = mcl_mobs.default_spawner
local aquatic_animal_spawner = {
	spawn_category = "water_ambient",
	spawn_placement = "aquatic",
}

function aquatic_animal_spawner:test_spawn_position (spawn_pos, node_pos, sdata, node_cache)
	if spawn_pos.y > 0.5 or spawn_pos.y < -12.5 then
		return false
	end

	local node_below = self:get_node (node_cache, -1, node_pos)
	local node_above = self:get_node (node_cache, 1, node_pos)
	if core.get_item_group (node_below.name, "water") > 0
		and core.get_item_group (node_above.name, "water") > 0 then
		if default_spawner.test_spawn_position (self, spawn_pos,
							node_pos, sdata,
							node_cache) then
			return true
		end
	end
	return false
end

mobs_mc.aquatic_animal_spawner = aquatic_animal_spawner

-- Monsters.

local monster_spawner = {
	spawn_placement = "ground",
	spawn_category = "monster",
	pack_min = 4,
	pack_max = 4,
	max_artificial_light = 0,
	max_light = 6,
}

function monster_spawner:test_spawn_position (spawn_pos, node_pos, sdata, node_cache)
	if mcl_vars.difficulty == 0 or only_peaceful_mobs then
		return false
	end

	local node_data = self:get_node (node_cache, 0, node_pos)
	local light = core.get_artificial_light (node_data.param1)
	if not light or light > self.max_artificial_light then
		return false
	end

	if default_spawner.test_spawn_position (self, spawn_pos, node_pos,
						sdata, node_cache) then
		-- Natural light tests are expensive...
		local natural_light = core.get_natural_light (node_pos)
		if not natural_light
			or natural_light > self.max_light
			or natural_light > math.random (0, 31) then
			return false
		end
		return true
	end
	return false
end

mobs_mc.monster_spawner = monster_spawner
