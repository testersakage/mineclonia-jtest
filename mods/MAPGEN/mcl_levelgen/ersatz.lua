------------------------------------------------------------------------
-- Luanti map generator adapter (a.k.a. "ersatz levels").
--
-- This module implements interfaces which adapt the structure
-- generators in mcl_levelgen to Luanti's objectively inferior
-- built-in map generators.
--
-- It follows from the inferiority of the built-in map generators that
-- there are certain caveats to be born in mind when enabling these
-- facilities or implementing structures.  To wit:
--
--   - It is not possible to read the entire vertical section of the
--     map within piece placement functions.
--
--   - Terrain heights must be derived from reimplementations of the
--     built-in map generators in Lua and may therefore be incorrect
--     or downright unavailable if the map generator in use is not yet
--     implemented.
--
--   - Biome data is not reliably available and in any event would not
--     adapt to terrain.
--
--   - No control is afforded over structures' interactions with
--     engine decorations.
--
-- Caveat emptor!
------------------------------------------------------------------------

local ipairs = ipairs
local pairs = pairs

------------------------------------------------------------------------
-- Ersatz environment initialization.
------------------------------------------------------------------------

local ersatz_biome_translations = {}

-- Assign biome IDs, though their values are insigificant.
mcl_levelgen.assign_biome_ids ({})

-- Translate biomes that are frequently considered significant by
-- structure generators.

function mcl_levelgen.ersatz_translate_biome (id)
	return ersatz_biome_translations[id]
end

local overworld_subtypes = {
	"_shore",
	"_beach",
	"_ocean",
	"_deep_ocean",
	"_sandlevel",
	"_snowtop",
	"_beach_water",
	"_underground",
	"_deep_underground",
}

local biome_specific_overrides = {}

local function maybe_map_biome (biome, target)
	local id = core.get_biome_id (biome)
	if id then
		ersatz_biome_translations[id] = target
	end
end

local function init_ersatz_biome_translations ()
	local ersatz_biome_map = {
		-- Nether.
		["BasaltDelta"] = "BasaltDeltas",
		["CrimsonForest"] = "CrimsonForest",
		["Nether"] = "NetherWastes",
		["SoulsandValley"] = "SoulSandValley",
		["WarpedForest"] = "WarpedForest",

		-- Overworld.
		["BambooJungle"] = "BambooJungle",
		["BirchForest"] = "BirchForest",
		["BirchForestM"] = "OldGrowthBirchForest",
		["ColdTaiga"] = "SnowyTaiga",
		["DeepDark"] = "DeepDark",
		["Desert"] = "Desert",
		["DripstoneCave"] = "DripstoneCaves",
		["ExtremeHills"] = "WindsweptHills",
		["ExtremeHills+"] = "WindsweptHills",
		["ExtremeHillsM"] = "WindsweptGravellyHills",
		["FlowerForest"] = "FlowerForest",
		["Forest"] = "Forest",
		["IcePlains"] = "SnowyPlains",
		["IcePlainsSpikes"] = "IceSpikes",
		["Jungle"] = "Jungle",
		["JungleEdge"] = "SparseJungle",
		["JungleEdgeM"] = "SparseJungle",
		["JungleM"] = "Jungle",
		["MangroveSwamp"] = "MangroveSwamp",
		["MegaSpruceTaiga"] = "OldGrowthSpruceTaiga",
		["MegaTaiga"] = "OldGrowthPineTaiga",
		["Mesa"] = "Mesa",
		["MesaBryce"] = "ErodedMesa",
		["MesaPlateauF"] = "WoodedMesa",
		["MesaPlateauFM"] = "WoodedMesa",
		["MushroomIsland"] = "MushroomIslands",
		["Plains"] = "Plains",
		["RoofedForest"] = "DarkForest",
		["Savanna"] = "Savannah",
		["SavannaM"] = "Savannah",
		["StoneBeach"] = "StonyShore",
		["SunflowerPlains"] = "SunflowerPlains",
		["Swampland"] = "Swamp",
		["Taiga"] = "Taiga",

		--- The End.
		["End"] = "TheEnd",
		["EndBarrens"] = "EndBarrens",
		["EndBorder"] = "TheEnd",
		["EndHighlands"] = "EndHighlands",
		["EndIsland"] = "TheEnd",
		["EndMidlands"] = "EndMidlands",
		["EndSmallIslands"] = "EndSmallIslands",
	}

	for biome, target in pairs (ersatz_biome_map) do
		maybe_map_biome (biome, target)
		for _, subtype in ipairs (overworld_subtypes) do
			maybe_map_biome (biome .. subtype, target)
		end
	end

	local cold_biome_overrides = {
		["Ocean"] = "ColdOcean",
		["DeepOcean"] = "DeepColdOcean",
	}
	local snowy_biome_overrides = {
		["Ocean"] = "FrozenOcean",
		["DeepOcean"] = "DeepFrozenOcean",
	}
	local hot_biome_overrides = {
		["Ocean"] = "WarmOcean",
		["DeepOcean"] = "LukewarmOcean",
	}
	local default_biome_overrides = {
		["Ocean"] = "Ocean",
		["DeepOcean"] = "DeepOcean",
	}

	for biome, def in pairs (core.registered_biomes) do
		local id = core.get_biome_id (biome)
		assert (id)
		if def._mcl_biome_type == "cold" then
			biome_specific_overrides[id] = cold_biome_overrides
		elseif def._mcl_biome_type == "hot" then
			biome_specific_overrides[id] = hot_biome_overrides
		elseif def._mcl_biome_type == "snowy" then
			biome_specific_overrides[id] = snowy_biome_overrides
		else
			biome_specific_overrides[id] = default_biome_overrides
		end
	end
end

-- Disable decorations; they must be placed after structures in
-- mg_ersatz.lua.
if core.set_mapgen_setting then
	local str = core.get_mapgen_setting ("mg_flags")
	local flags = string.split (str, ",", false)
	for i, flag in ipairs (flags) do
		if flag:find ("decorations") then
			flags[i] = "nodecorations"
		end
	end
	core.set_mapgen_setting ("mg_flags", table.concat (flags, ","), true)
end

core.register_on_mods_loaded (init_ersatz_biome_translations)

------------------------------------------------------------------------
-- Ersatz dimensions.
------------------------------------------------------------------------

-- Register ersatz dimensions.
dofile (mcl_levelgen.prefix .. "/dimensions.lua")

local v = vector.zero ()
local mg_overworld_min = mcl_vars.mg_overworld_min
local toblock = mcl_levelgen.toblock
local mapgen_model

local ersatz_preset_template_overworld = table.merge (mcl_levelgen.level_preset_template, {
	min_y = -64,
	height = 384,
	sea_level = 64,
	ersatz_default_height = 65,
	index_biomes_block = function (self, x, y, z)
		v.x = x
		v.z = -z - 1
		v.y = y + 64 + mg_overworld_min
		if mapgen_model then
			local override = mapgen_model.get_biome_override (x, -z - 1)
			if override then
				local data = core.get_biome_data (v)
				return biome_specific_overrides[data.biome][override]
					or override
			end
		end
		local data = core.get_biome_data (v)
		if data then
			return ersatz_biome_translations[data.biome] or "Plains"
		else
			return "Plains"
		end
	end,
	index_biomes_begin = function (self, wx, wz, xorigin, zorigin)
	end,
	index_biomes_cached = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + 64 + mg_overworld_min
		if mapgen_model then
			local override = mapgen_model.get_biome_override (x, -z - 1)
			if override then
				local data = core.get_biome_data (v)
				return biome_specific_overrides[data.biome][override]
					or override
			end
		end
		local data = core.get_biome_data (v)
		if data then
			return ersatz_biome_translations[data.biome] or "Plains"
		else
			return "Plains"
		end
	end,
	index_biomes = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + 64 + mg_overworld_min
		if mapgen_model then
			local override = mapgen_model.get_biome_override (x, -z - 1)
			if override then
				local data = core.get_biome_data (v)
				return biome_specific_overrides[data.biome][override]
					or override
			end
		end
		local data = core.get_biome_data (v)
		if data then
			return ersatz_biome_translations[data.biome] or "Plains"
		else
			return "Plains"
		end
	end,
	generated_biomes = function (self)
		return self.all_biomes
	end,
	all_biomes = {
		"BambooJungle",
		"BirchForest",
		"DarkForest",
		"DeepDark",
		"DeepOcean",
		"Desert",
		"DripstoneCaves",
		"ErodedMesa",
		"FlowerForest",
		"Forest",
		"IceSpikes",
		"Jungle",
		"MangroveSwamp",
		"Mesa",
		"MushroomIslands",
		"Ocean",
		"OldGrowthBirchForest",
		"OldGrowthPineTaiga",
		"OldGrowthSpruceTaiga",
		"Plains",
		"Savannah",
		"SnowyPlains",
		"SnowyTaiga",
		"SparseJungle",
		"StonyShore",
		"SunflowerPlains",
		"Swamp",
		"Taiga",
		"WindsweptGravellyHills",
		"WindsweptHills",
		"WoodedMesa",
	},
})

local mg_nether_min = mcl_vars.mg_nether_min

local ersatz_preset_template_nether = table.merge (mcl_levelgen.level_preset_template, {
	min_y = 0,
	height = 128,
	sea_level = 32,
	ersatz_default_height = 129,
	default_block = "mcl_nether:netherrack",
	default_fluid = "mcl_nether:nether_lava_source",
	index_biomes_block = function (self, x, y, z)
		v.x = x
		v.z = -z - 1
		v.y = y + mg_nether_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "NetherWastes"
	end,
	index_biomes_begin = function (self, wx, wz, xorigin, zorigin)
	end,
	index_biomes_cached = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + mg_nether_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "NetherWastes"
	end,
	index_biomes = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + mg_nether_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "NetherWastes"
	end,
	generated_biomes = function (self)
		return self.all_biomes
	end,
	all_biomes = {
		"BasaltDeltas",
		"CrimsonForest",
		"NetherWastes",
		"SoulSandValley",
		"WarpedForest",
	},
})

local mg_end_min = mcl_vars.mg_end_min

local ersatz_preset_template_end = table.merge (mcl_levelgen.level_preset_template, {
	min_y = 0,
	height = 128,
	sea_level = 0,
	default_block = "mcl_end:end_stone",
	default_fluid = "air",
	ersatz_default_height = 75,
	index_biomes_block = function (self, x, y, z)
		v.x = x
		v.z = -z - 1
		v.y = y + mg_end_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "TheEnd"
	end,
	index_biomes_begin = function (self, wx, wz, xorigin, zorigin)
	end,
	index_biomes_cached = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + mg_end_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "TheEnd"
	end,
	index_biomes = function (self, x, y, z)
		v.x = toblock (x)
		v.z = toblock (-z - 1)
		v.y = toblock (y) + mg_end_min
		return ersatz_biome_translations[core.get_biome_data (v).biome]
			or "TheEnd"
	end,
	generated_biomes = function (self)
		return self.all_biomes
	end,
	all_biomes = {
		"EndBarrens",
		"EndHighlands",
		"EndMidlands",
		"EndSmallIslands",
		"TheEnd",
	},
})

local function make_ersatz_preset (template, seed)
	local preset = mcl_levelgen.copy_preset (template)
	mcl_levelgen.initialize_random (preset, seed)
	return preset
end

mcl_levelgen.register_dimension ("mcl_levelgen:overworld", {
	y_global = mcl_vars.mg_overworld_min,
	data_namespace = 0,
	create_preset = function (self, seed)
		return make_ersatz_preset (ersatz_preset_template_overworld, seed)
	end,
	no_lighting = false,
})

mcl_levelgen.register_dimension ("mcl_levelgen:nether", {
	y_global = mcl_vars.mg_nether_min,
	data_namespace = 1,
	create_preset = function (self, seed)
		return make_ersatz_preset (ersatz_preset_template_nether, seed)
	end,
	no_lighting = false,
})

mcl_levelgen.register_dimension ("mcl_levelgen:end", {
	y_global = mcl_vars.mg_end_min,
	data_namespace = 2,
	create_preset = function (self, seed)
		return make_ersatz_preset (ersatz_preset_template_end, seed)
	end,
	no_lighting = false,
})

mcl_levelgen.initialize_dimensions (mcl_levelgen.seed)

------------------------------------------------------------------------
-- Ersatz post-processing.
------------------------------------------------------------------------

if core and core.get_mod_storage then -- Main environment.

local y_offset = nil

core.set_gen_notify ({ custom = true, }, nil, {
	"mcl_levelgen:structure_pieces",
	"mcl_levelgen:gen_notifies",
})

local storage = core.get_mod_storage ()

local registered_notification_handlers = {}
local warned = {}
local save_structure_pieces

mcl_levelgen.registered_notification_handlers
	= registered_notification_handlers

function mcl_levelgen.register_notification_handler (name, handler)
	assert (type (name) == "string")
	registered_notification_handlers[name] = handler
end

local function run_notification_handlers (gen_notifies)
	for _, notify in ipairs (gen_notifies) do
		local name = notify.name
		local handler = registered_notification_handlers[name]
		if not handler and not warned[name] then
			warned[name] = true
			core.log ("warning", "Invoking unknown feature generation handler: " .. name)
		elseif handler then
			handler (notify.name, notify.data)
		end
	end
end

local function post_process_mapchunk_in_dim (minp, maxp, dim)
	local custom = core.get_mapgen_object ("gennotify").custom
	y_offset = dim.y_offset
	run_notification_handlers (custom["mcl_levelgen:gen_notifies"])
	y_offset = nil
	local pieces = custom["mcl_levelgen:structure_pieces"]
	if pieces then
		save_structure_pieces (pieces)
	end
end

local dims_intersecting = mcl_levelgen.dims_intersecting

local function post_process_mapchunk (minp, maxp)
	local generated = false
	for y1, y2, ystart, yend, dim in dims_intersecting (minp.y, maxp.y) do
		if generated then
			break
		end

		minp.y = y1
		maxp.y = y2
		post_process_mapchunk_in_dim (minp, maxp, dim)
		generated = true
	end
end

core.register_on_generated (post_process_mapchunk)

function mcl_levelgen.level_to_minetest_position (x, y, z)
	if y_offset then
		return x, y - y_offset, -z - 1
	else
		-- Don't convert Y positions if no dimension currently
		-- exists; this is exercised by structure blocks.
		return x, y, -z - 1
	end
end

local structure_extents = AreaStore ()

do
	local str = storage:get_string ("structure_extents")
	if str and str ~= "" then
		local data = core.decompress (str, "zstd")
		structure_extents:from_string (data)
	end
end

local v1, v2 = vector.zero (), vector.zero ()

local function unpack6 (aabb)
	return aabb[1], aabb[2], aabb[3], aabb[4], aabb[5], aabb[6]
end

function save_structure_pieces (pieces)
	structure_extents:reserve (#pieces)
	for _, piece in ipairs (pieces) do
		local x1, y1, z1, x2, y2, z2 = unpack6 (piece)
		local sid = piece[7]
		v1.x, v1.y, v1.z = x1, y1, z1
		v2.x, v2.y, v2.z = x2, y2, z2
		local id = structure_extents:insert_area (v1, v2, sid)
		if not id then
			local blurb = table.concat ({
				"[mcl_levelgen]: Failed to record structure piece: ",
				sid,
				" spanning ",
				string.format ("(%d,%d,%d) - (%d,%d,%d)",
					       x1, y1, z1, x2, y2, z2),
			})
			core.log ("error", blurb)
		end
	end
end

local function save_structure_extents ()
	local str = structure_extents:to_string ()
	local data = core.compress (str, "zstd")
	storage:set_string ("structure_extents", data)
	core.log ("info", ("[mcl_levelgen]: Structure extents occupy "
			   .. #str .. " bytes (" .. #data .. " bytes compressed)"))
end

function mcl_levelgen.get_structures_at (pos, include_corners)
	return structure_extents:get_areas_for_pos (pos, include_corners, true)
end

core.register_on_shutdown (save_structure_extents)

end

------------------------------------------------------------------------
-- Ersatz terrain generator object.
------------------------------------------------------------------------

local mt_chunksize = core.ipc_get ("mcl_levelgen:mt_chunksize")

local mathmin = math.min
local floor = math.floor
local ceil = math.ceil

local chunksize = mt_chunksize.x * 16
local ychunksize = mt_chunksize.y * 16
local y_offset

local ull = mcl_levelgen.ull

local ersatz_terrain = {
	chunksize = chunksize,
	chunksize_y = ychunksize,
	preset = nil,
	biome_seed = ull (0, 0),
	is_ersatz = true,
}
mcl_levelgen.ersatz_terrain = ersatz_terrain

local cid_water_source

core.register_on_mods_loaded (function ()
	cid_water_source = core.get_content_id ("mcl_core:water_source")
end)

function ersatz_terrain:get_one_height (x, z, is_solid)
	if mapgen_model then
		local water_solid_p
			= is_solid and is_solid (cid_water_source, 0)
		return mapgen_model.get_column_height (x, -z - 1,
						       water_solid_p)
			+ y_offset
	end
	return self.preset.ersatz_default_height
end

function ersatz_terrain:area_heightmap (x1, z1, x2, z2, heightmap, is_solid)
	local w = x2 - x1 + 1
	local l = z2 - z1 + 1
	local total = w * l

	if mapgen_model then
		local water_solid_p
			= is_solid and is_solid (cid_water_source, 0)
		local get_column_height = mapgen_model.get_column_height
		for i = 1, total do
			local dx = floor ((i - 1) / l)
			local dz = (i - 1) % l
			heightmap[i] = get_column_height (dx + x1, -(dz + z1) - 1,
							  water_solid_p)
				+ y_offset
		end
	else
		local default = self.preset.ersatz_default_height
		for i = 1, total do
			heightmap[i] = default
		end
	end
	return total
end

local tmp_heightmap = {}

function ersatz_terrain:area_min_height (x1, z1, x2, z2, is_solid)
	local heightmap = tmp_heightmap
	local total = self:area_heightmap (x1, z1, x2, z2, heightmap,
					   is_solid)
	local value = heightmap[1]
	for i = 2, total do
		value = mathmin (value, heightmap[i])
	end
	return value
end

local function rtz (n)
	if n < 0 then
		return ceil (n)
	end
	return floor (n)
end

function ersatz_terrain:area_average_height (x1, z1, x2, z2, is_solid)
	local heightmap = tmp_heightmap
	local total = self:area_heightmap (x1, z1, x2, z2, heightmap,
					   is_solid)
	local value = heightmap[1]
	for i = 2, total do
		value = value + heightmap[i]
	end
	return rtz (value / total)
end

local cid_air = core.CONTENT_AIR
local encode_node = mcl_levelgen.encode_node

function ersatz_terrain:get_one_column (x, z, column_data)
	local preset = self.preset
	local level_height = preset.height
	local y_min = preset.min_y
	local height = self:get_one_height (x, z)
	local default_block = encode_node (self.cid_default_block, 0)
	local air = encode_node (cid_air, 0)
	for i = 1, level_height do
		if i + y_min >= height then
			column_data[i] = air
		else
			column_data[i] = default_block
		end
	end
	column_data[level_height + 1] = nil
	return column_data
end

local structure_levels = {}

local function create_structure_level (dim)
	if not structure_levels[dim] then
		structure_levels[dim]
			= mcl_levelgen.make_structure_level (dim.preset)
	end
	return structure_levels[dim]
end

function mcl_levelgen.get_ersatz_terrain (dim)
	local preset = dim.preset
	local y_global = dim.y_global
	y_offset = preset.min_y - y_global
	if 0 >= y_global and 0 <= y_global + preset.height - 1 then
		mapgen_model = mcl_mapgen_models.get_mapgen_model ()
	else
		mapgen_model = nil
	end
	ersatz_terrain.preset = preset
	ersatz_terrain.cid_default_block
		= core.get_content_id (preset.default_block)
	ersatz_terrain.chunksize_y = ychunksize
	ersatz_terrain.structures = create_structure_level (dim)
	return ersatz_terrain
end

------------------------------------------------------------------------
-- Jigsaw Block registration.
------------------------------------------------------------------------

if core and core.register_node then
	dofile (mcl_levelgen.prefix .. "/jigsaw.lua")
end

------------------------------------------------------------------------
-- Ersatz mapgen registration.
------------------------------------------------------------------------

if core and core.register_mapgen_script then
	core.register_mapgen_script (mcl_levelgen.prefix .. "/init.lua")
	dofile (mcl_levelgen.prefix .. "/ersatz_structures.lua")
	mcl_levelgen.register_levelgen_script ((mcl_levelgen.prefix
						.. "/ersatz_structures.lua"), true)
end
if core and not core.get_mod_storage then
	dofile (mcl_levelgen.prefix .. "/mg_ersatz.lua")
end
