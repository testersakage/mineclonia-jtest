local ipairs = ipairs

mcl_biome_dispatch = {}

------------------------------------------------------------------------
-- Biome system abstraction layer.
------------------------------------------------------------------------

local levelgen_enabled = mcl_levelgen.levelgen_enabled
local get_biome = mcl_levelgen.get_biome

function mcl_biome_dispatch.get_biome_name (v)
	if levelgen_enabled then
		return get_biome (v, true) or "TheVoid"
	else
		local data = core.get_biome_data (v)
		return core.get_biome_name (data.biome)
	end
end

local is_temp_snowy = mcl_levelgen.is_temp_snowy
local registered_biomes = mcl_levelgen.registered_biomes
local conv_pos_raw = mcl_levelgen.conv_pos_raw
local get_temperature_in_biome = mcl_levelgen.get_temperature_in_biome

function mcl_biome_dispatch.is_position_cold (biome_name, v)
	if levelgen_enabled and biome_name then
		local x, y, z, _ = conv_pos_raw (v)
		return x and is_temp_snowy (biome_name, x, y, z)
	elseif biome_name then
		local data = core.registered_biomes[biome_name]
		if data and data._mcl_biome_type == "snowy" then
			return true
		elseif data and data._mcl_biome_type == "cold" then
			return biome_name == "Taiga" and v.y > 140
				or biome_name == "MegaSpruceTaiga" and v.y > 100
		end
	end
	return false
end

function mcl_biome_dispatch.is_position_arid (biome_name)
	if not biome_name then
		return false
	elseif levelgen_enabled then
		local data = registered_biomes[biome_name]
		return not data.has_precipitation
	else
		local data = core.registered_biomes[biome_name]
		return data._mcl_biome_type == "hot"
	end
end

function mcl_biome_dispatch.get_sky_color (pos)
	if levelgen_enabled then
		local biome = get_biome (pos, false)
		if biome then
			local data = registered_biomes[biome]
			return data.sky_color
		end
	else
		local biome_index = core.get_biome_data (pos).biome
		local biome_name = core.get_biome_name (biome_index)
		local biome = core.registered_biomes[biome_name]
		return biome and biome._mcl_skycolor
	end
	return false
end

function mcl_biome_dispatch.get_fog_color (pos)
	if levelgen_enabled then
		local biome = get_biome (pos, false)
		if biome then
			local data = registered_biomes[biome]
			return data.fog_color
		end
	else
		local biome_index = core.get_biome_data (pos).biome
		local biome_name = core.get_biome_name (biome_index)
		local biome = core.registered_biomes[biome_name]
		return biome and biome._mcl_fogcolor
	end
	return false
end

function mcl_biome_dispatch.get_sky_and_fog_colors (pos)
	if levelgen_enabled then
		local biome = get_biome (pos, false)
		if biome then
			local data = registered_biomes[biome]
			return data.sky_color, data.fog_color
		end
	else
		local biome_index = core.get_biome_data (pos).biome
		local biome_name = core.get_biome_name (biome_index)
		local biome = core.registered_biomes[biome_name]
		if biome then
			return biome._mcl_skycolor, biome._mcl_fogcolor
		end
	end
	return false
end

function mcl_biome_dispatch.get_temperature_in_biome (biome_name, v)
	if levelgen_enabled and biome_name then
		local x, y, z, _ = conv_pos_raw (v)
		return x and get_temperature_in_biome (biome_name, x, y, z)
			or 1.0
	else
		local data = core.registered_biomes[biome_name]
		if data and data._mcl_biome_type == "snowy" then
			return 0.0
		elseif data and data._mcl_biome_type == "cold" then
			return 0.5
		elseif data and data._mcl_biome_type ~= "hot" then
			return 1.0
		elseif data then
			return 1.5
		end
	end
	return 1.0
end

local overworld_subtypes = {
	"_shore",
	"_beach",
	"_ocean",
	"_deep_ocean",
	"_sandlevel",
	"_snowtop",
	"_beach_water",
}

local function related_list_from_base (bases, subtypes)
	local list = {}
	if type (bases) == "string" then
		bases = {bases,}
	end
	for _, base in ipairs (bases) do
		assert (core.registered_biomes[base],
			"Old-style biome " .. base .. " is not registered")
		table.insert (list, base)

		for _, subtype in ipairs (subtypes) do
			local name = base .. subtype
			if core.registered_biomes[name] then
				table.insert (list, name)
			end
		end
	end
	return list
end

local engine_aliases = nil

local function initialize_engine_aliases ()
	if engine_aliases then
		return engine_aliases
	end
	engine_aliases = {
		TheVoid = {},
		Mesa = related_list_from_base ("Mesa", overworld_subtypes),
		BambooJungle = related_list_from_base ("BambooJungle", overworld_subtypes),
		BasaltDeltas = "BasaltDelta",
		Beach = {},
		BirchForest = related_list_from_base ({"BirchForest", "BirchForestM",},
						      overworld_subtypes),
		ColdOcean = {},
		DeepColdOcean = {},
		DeepFrozenOcean = {},
		Desert = related_list_from_base ("Desert", overworld_subtypes),
		DripstoneCaves = "DripstoneCave",
		ErodedMesa = related_list_from_base ("MesaBryce", overworld_subtypes),
		FlowerForest = related_list_from_base ("FlowerForest",
						       overworld_subtypes),
		Forest = related_list_from_base ("Forest", overworld_subtypes),
		FrozenOcean = {},
		FrozenPeaks = {},
		FrozenRiver = {},
		Grove = {},
		IceSpikes = related_list_from_base ("IcePlainsSpikes", overworld_subtypes),
		JaggedPeaks = {},
		Jungle = related_list_from_base ({"Jungle", "JungleM",}, overworld_subtypes),
		LukewarmOcean = {},
		LushCaves = related_list_from_base ("LushCaves", overworld_subtypes),
		MangroveSwamp = related_list_from_base ("MangroveSwamp", overworld_subtypes),
		Meadow = {},
		MushroomIslands = related_list_from_base ({"MushroomIsland", "MushroomIslandShore",},
							  overworld_subtypes),
		NetherWastes = "Nether",
		Ocean = {},
		OldGrowthBirchForest = {},
		OldGrowthPineTaiga = related_list_from_base ("MegaTaiga", overworld_subtypes),
		OldGrowthSpruceTaiga = related_list_from_base ("MegaSpruceTaiga",
							       overworld_subtypes),
		Plains = related_list_from_base ("Plains", overworld_subtypes),
		River = {},
		Savannah = related_list_from_base ({"Savanna", "SavannaM",},
			overworld_subtypes),
		SavannahPlateau = {},
		SmallEndIslands = "EndSmallIslands",
		SnowyBeach = {},
		SnowyPlains = related_list_from_base ("IcePlains", overworld_subtypes),
		SnowySlopes = {},
		SnowyTaiga = related_list_from_base ("ColdTaiga", overworld_subtypes),
		SoulSandValley = "SoulsandValley",
		SparseJungle = related_list_from_base ({"JungleEdge", "JungleEdgeM",},
						       overworld_subtypes),
		StonyPeaks = {},
		StonyShore = related_list_from_base ("StoneBeach", overworld_subtypes),
		SunflowerPlains = related_list_from_base ("SunflowerPlains",
							  overworld_subtypes),
		Swamp = related_list_from_base ("Swampland", overworld_subtypes),
		Taiga = related_list_from_base ("Taiga", overworld_subtypes),
		TheEnd = {
			"End",
			"EndBorder",
			"EndIsland",
		},
		WarmOcean = {},
		WindsweptForest = {},
		WindsweptGravellyHills = related_list_from_base ("ExtremeHillsM",
								 overworld_subtypes),
		WindsweptHills = related_list_from_base ({"ExtremeHills", "ExtremeHills+",},
							 overworld_subtypes),
		WoodedMesa = related_list_from_base ({"MesaPlateauF", "MesaPlateauFM",},
						     {"_grasstop", "_sandlevel", "_ocean",
						      "_deep_ocean",}),
	}
	return engine_aliases
end

-- Return a list of biome names represented by IDS_OR_TAGS, a list of
-- new-style biome names or tags prefixed with `#'.

function mcl_biome_dispatch.build_biome_list (ids_or_tags)
	if type (ids_or_tags) == "string" then
		ids_or_tags = {ids_or_tags,}
	end

	if levelgen_enabled then
		return mcl_levelgen.build_biome_list (ids_or_tags)
	else
		local names = {}
		local engine_aliases = initialize_engine_aliases ()
		for _, id in ipairs (ids_or_tags) do
			if string.find (id, "#") == 1 then
				local group = string.sub (id, 2)
				for name, biome in pairs (core.registered_biomes) do
					if biome._mcl_groups
						and biome._mcl_groups[group]
						and table.indexof (names, name) == -1 then
						table.insert (names, name)
					end
				end
			elseif engine_aliases[id] then
				local aliases = engine_aliases[id]
				if type (aliases) == "string" then
					if table.indexof (names, aliases) == -1 then
						table.insert (names, aliases)
					end
				else
					for _, alias in ipairs (aliases) do
						if table.indexof (names, alias) == -1 then
							table.insert (names, alias)
						end
					end
				end
			else
				if not core.registered_biomes[id] then
					error ("Old-style biome does not exist and is not aliased: " .. id)
				end
				if table.indexof (names, id) == -1 then
					table.insert (names, id)
				end
			end
		end
		return names
	end
end

local test_dispatchers = {
	[0] = function ()
		return function ()
			return false
		end
	end,
	function (a)
		return function (biome)
			return biome == a
		end
	end,
	function (a, b)
		return function (biome)
			return biome == a or biome == b
		end
	end,
	function (a, b, c)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
		end
	end,
	function (a, b, c, d)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
				or biome == d
		end
	end,
	function (a, b, c, d, e)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
				or biome == d
				or biome == e
		end
	end,
	function (a, b, c, d, e, f)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
				or biome == d
				or biome == e
				or biome == f
		end
	end,
	function (a, b, c, d, e, f, g)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
				or biome == d
				or biome == e
				or biome == f
				or biome == g
		end
	end,
	function (a, b, c, d, e, f, g, h)
		return function (biome)
			return biome == a
				or biome == b
				or biome == c
				or biome == d
				or biome == e
				or biome == f
				or biome == g
				or biome == h
		end
	end,
}

local function test_dispatcher_generic (...)
	local args = {...}
	return function (biome)
		for _, biome1 in ipairs (args) do
			if biome == biome1 then
				return true
			end
		end
		return false
	end
end

function mcl_biome_dispatch.make_biome_test (ids_or_tags)
	local list = mcl_biome_dispatch.build_biome_list (ids_or_tags)
	return (test_dispatchers[#list] or test_dispatcher_generic) (unpack (list))
end
