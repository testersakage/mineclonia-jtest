-------------------------------------------------------------------------
-- Spawning initialization.
-------------------------------------------------------------------------

local only_peaceful_mobs
	= core.settings:get_bool ("only_peaceful_mobs", false)

mobs_mc.overworld_biomes = {
	"BambooJungle",
	"Beach",
	"BirchForest",
	"CherryGrove",
	"DarkForest",
	"DeepColdOcean",
	"DeepFrozenOcean",
	"DeepLukewarmOcean",
	"DeepOcean",
	"Desert",
	"DripstoneCaves",
	"ErodedMesa",
	"FlowerForest",
	"Forest",
	"FrozenOcean",
	"FrozenPeaks",
	"FrozenRiver",
	"Grove",
	"IceSpikes",
	"JaggedPeaks",
	"Jungle",
	"LukewarmOcean",
	"LushCaves",
	"MangroveSwamp",
	"Meadow",
	"Mesa",
	"MushroomIslands",
	"Ocean",
	"OldGrowthBirchForest",
	"OldGrowthPineTaiga",
	"OldGrowthSpruceTaiga",
	"Plains",
	"River",
	"Savannah",
	"SavannahPlateau",
	"SnowyBeach",
	"SnowyPlains",
	"SnowySlopes",
	"SnowyTaiga",
	"SparseJungle",
	"StonyPeaks",
	"StonyShore",
	"SunflowerPlains",
	"Swamp",
	"Taiga",
	"WarmOcean",
	"WindsweptForest",
	"WindsweptGravellyHills",
	"WindsweptHills",
	"WindsweptSavannah",
	"WoodedMesa",
}

mobs_mc.farm_animal_biomes = {
	"BambooJungle",
	"BirchForest",
	"CherryGrove",
	"DarkForest",
	"FlowerForest",
	"Forest",
	"Jungle",
	"OldGrowthBirchForest",
	"OldGrowthPineTaiga",
	"OldGrowthSpruceTaiga",
	"Plains",
	"SavannahPlateau",
	"Savannah",
	"SnowyTaiga",
	"SparseJungle",
	"SunflowerPlains",
	"Swamp",
	"Taiga",
	"WindsweptForest",
	"WindsweptGravellyHills",
	"WindsweptHills",
	"WindsweptSavannah",
}

mobs_mc.monster_biomes = {
	"BambooJungle",
	"Beach",
	"BirchForest",
	"CherryGrove",
	"ColdOcean",
	"DarkForest",
	"DeepColdOcean",
	"DeepFrozenOcean",
	"DeepOcean",
	"Desert",
	"DripstoneCaves",
	"ErodedMesa",
	"FlowerForest",
	"Forest",
	"FrozenOcean",
	"FrozenPeaks",
	"FrozenRiver",
	"Grove",
	"IceSpikes",
	"JaggedPeaks",
	"Jungle",
	"LukewarmOcean",
	"LushCaves",
	"MangroveSwamp",
	"Meadow",
	"Mesa",
	"Ocean",
	"OldGrowthBirchForest",
	"OldGrowthPineTaiga",
	"OldGrowthSpruceTaiga",
	"Plains",
	"River",
	"SavannahPlateau",
	"Savannah",
	"SnowyBeach",
	"SnowyPlains",
	"SnowySlopes",
	"StonyPeaks",
	"StonyShore",
	"SunflowerPlains",
	"Swamp",
	"Taiga",
	"WarmOcean",
	"WindsweptGravellyHills",
	"WindsweptHills",
	"WindsweptSavannah",
	"WoodedMesa",
}

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
