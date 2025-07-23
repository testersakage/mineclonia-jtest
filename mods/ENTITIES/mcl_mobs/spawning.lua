--lua locals
local mob_class = mcl_mobs.mob_class
local is_valid = mcl_util.is_valid_objectref

local only_peaceful_mobs = core.settings:get_bool("only_peaceful_mobs", false)
local modern_lighting = core.settings:get_bool("mcl_mobs_modern_lighting", true)

local nether_threshold = 11
local end_threshold = 15
local overworld_threshold = 0
local overworld_sky_threshold = 7
local overworld_passive_threshold = 7

local PASSIVE_INTERVAL = 20
local HOSTILE_INTERVAL = 10
local dbg_spawn_attempts = 0
local dbg_spawn_succ = 0
local dbg_spawn_counts = {}
-- range for mob count
local aoc_range = 136
local remove_far = true

local instant_despawn_range = 128
local random_despawn_range = 32

local mob_cap = {
	monster = tonumber(core.settings:get("mcl_mob_cap_monster")) or 70,
	animal = tonumber(core.settings:get("mcl_mob_cap_animal")) or 10,
	ambient = tonumber(core.settings:get("mcl_mob_cap_ambient")) or 15,
	water = tonumber(core.settings:get("mcl_mob_cap_water")) or 5,
	water_ambient = tonumber(core.settings:get("mcl_mob_cap_water_ambient")) or 20,
	player = tonumber(core.settings:get("mcl_mob_cap_player")) or 75,
	total = tonumber(core.settings:get("mcl_mob_cap_total")) or 500,
}

--do mobs spawn?
local mobs_spawn = core.settings:get_bool("mobs_spawn", true) ~= false
local mobs_spawn_old = core.settings:get_bool("mobs_spawn_old", false) ~= false
local spawn_protected = core.settings:get_bool("mobs_spawn_protected") ~= false
local logging = core.settings:get_bool("mcl_logging_mobs_spawn", false)
local mgname = core.get_mapgen_setting("mgname")

-- count how many mobs are in an area
local function count_mobs(pos,r,mob_type)
	local num = 0
	for _,l in pairs(core.luaentities) do
		if l and l.is_mob and (mob_type == nil or l.type == mob_type) then
			local p = l.object:get_pos()
			if p and vector.distance(p,pos) < r then
				num = num + 1
			end
		end
	end
	return num
end

local function count_mobs_total(mob_type)
	local num = 0
	for _,l in pairs(core.luaentities) do
		if l.is_mob then
			if mob_type == nil or l.type == mob_type then
				num = num + 1
			end
		end
	end
	return num
end

local function count_mobs_all()
	local mobs_found = {}
	local num = 0
	for _,entity in pairs(core.luaentities) do
		if entity.is_mob then
			local mob_name = entity.name
			if entity._reloaded then
				mob_name = mob_name .. " (reloaded)"
			end
			if mobs_found[mob_name] then
				mobs_found[mob_name] = mobs_found[mob_name] + 1
			else
				mobs_found[mob_name] = 1
			end
			num = num + 1
		end
	end
	return mobs_found, num
end

local function count_mobs_total_cap(mob_type)
	local num = 0
	for _,l in pairs(core.luaentities) do
		if l.is_mob then
			if ( mob_type == nil or l.type == mob_type ) and l.can_despawn and not l.nametag then
				num = num + 1
			end
		end
	end
	return num
end

--this is where all of the spawning information is kept
local spawn_dictionary = {}

local spawn_defaults = {
	dimension = "overworld",
	type_of_spawning = "ground",
	min_light = 7,
	max_light = core.LIGHT_MAX + 1,
	chance = 1000,
	aoc = aoc_range,
	min_height = -mcl_vars.mapgen_limit,
	max_height = mcl_vars.mapgen_limit,
}

local spawn_defaults_meta = { __INDEX = spawn_defaults }

function mcl_mobs.spawn_setup(def)
	if not mobs_spawn then return end

	assert(def, "Empty spawn setup definition from mod: "..tostring(core.get_current_modname()))
	assert(def.name, "Missing mob name from from mod: "..tostring(core.get_current_modname()))

	local mob_def = core.registered_entities[def.name]
	assert(mob_def, "spawn definition with invalid entity: "..tostring(def.name))
	if (mcl_vars.difficulty <= 0 or only_peaceful_mobs) and not mob_def.persist_in_peaceful then return end
	assert(def.chance > 0, "Chance shouldn't be less than 1 (mob name: " .. def.name ..")")

	setmetatable(def, spawn_defaults_meta)
	def.min_light        = def.min_light or mob_def.min_light or (mob_def.spawn_class == "hostile" and 0)
	def.max_light        = def.max_light or mob_def.max_light or (mob_def.spawn_class == "hostile" and 7)
	def.min_height       = def.min_height or mcl_vars["mg_"..def.dimension.."_min"]
	def.max_height       = def.max_height or mcl_vars["mg_"..def.dimension.."_max"]

	table.insert(spawn_dictionary, def)
end

function mcl_mobs.get_mob_light_level(mob,dim)
	for _,v in pairs(spawn_dictionary) do
		if v.name == mob and v.dimension == dim then
			return v.min_light,v.max_light
		end
	end
	local def = core.registered_entities[mob]
	return def.min_light,def.max_light
end

local function biome_check(biome_list, biome_goal)
	if mgname == "singlenode" then return true end
	return table.indexof(biome_list,biome_goal) ~= -1
end

local function is_farm_animal(n)
	return n == "mobs_mc:pig" or n == "mobs_mc:cow" or n == "mobs_mc:sheep" or n == "mobs_mc:chicken" or n == "mobs_mc:horse" or n == "mobs_mc:donkey"
end

local function get_water_spawn(p)
		local nn = core.find_nodes_in_area(vector.offset(p,-2,-1,-2),vector.offset(p,2,-15,2),{"group:water"})
		if nn and #nn > 0 then
			return nn[math.random(#nn)]
		end
end

local function has_room(self,pos)
	local cb = self.initial_properties.collisionbox
	local nodes = {}
	if self.fly_in then
		local t = type(self.fly_in)
		if t == "table" then
			nodes = table.copy(self.fly_in)
		elseif t == "string" then
			table.insert(nodes,self.fly_in)
		end
	end
	if self.swims_in then
		local t = type(self.swims_in)
		if t == "table" then
			nodes = table.copy(self.swims_in)
		elseif t == "string" then
			table.insert(nodes,self.swims_in)
		end
	end
	table.insert(nodes,"air")
	local x = cb[4] - cb[1]
	local y = cb[5] - cb[2]
	local z = cb[6] - cb[3]
	local r = math.ceil(x * y * z)
	local p1 = vector.offset(pos,cb[1],cb[2],cb[3])
	local p2 = vector.offset(pos,cb[4],cb[5],cb[6])
	local n = #core.find_nodes_in_area(p1,p2,nodes) or 0
	if r > n then
		core.log("info","[mcl_mobs] No room for mob "..self.name.." at "..core.pos_to_string(vector.round(pos)))
		return false
	end
	return true
end

local function spawn_check(pos,spawn_def,ignore_caps)
	if not spawn_def or not pos then return end
	dbg_spawn_attempts = dbg_spawn_attempts + 1
	local dimension = mcl_worlds.pos_to_dimension(pos)
	local mob_def = core.registered_entities[spawn_def.name]
	local mob_type = mob_def.type
	local gotten_node = core.get_node_or_nil(pos)
	if not gotten_node then return end
	gotten_node = gotten_node.name
	local is_ground = core.get_item_group(gotten_node,"opaque") ~= 0
	if not is_ground then
		pos.y = pos.y - 1
		gotten_node = core.get_node(pos).name
		is_ground = core.get_item_group(gotten_node,"opaque") ~= 0
	end
	pos.y = pos.y + 1
	local is_water = core.get_item_group(gotten_node, "water") ~= 0
	local is_lava  = core.get_item_group(gotten_node, "lava") ~= 0
	local is_leaf  = core.get_item_group(gotten_node, "leaves") ~= 0
	local is_bedrock  = gotten_node == "mcl_core:bedrock"
	local is_grass = core.get_item_group(gotten_node,"grass_block") ~= 0


	if not pos then return false,"no pos" end
	if not spawn_def then return false,"no spawn_def" end
	if not ( spawn_def.min_height and pos.y >= spawn_def.min_height ) then return false, "too low" end
	if not ( spawn_def.max_height and pos.y <= spawn_def.max_height ) then return false, "too high" end
	if spawn_def.dimension ~= dimension then return false, "wrong dimension" end
	if not (is_ground or spawn_def.type_of_spawning ~= "ground") then return false, "not on ground" end
	if not (spawn_def.type_of_spawning ~= "ground" or not is_leaf) then return false, "leaf" end
	if not has_room(mob_def,pos) then return false, "no room" end
	if not (spawn_def.check_position and spawn_def.check_position(pos) or true) then return false, "check_position failed" end
	if not (not is_farm_animal(spawn_def.name) or is_grass) then return false, "farm animals only on grass" end
	if not (spawn_def.type_of_spawning ~= "water" or is_water) then return false, "water mob only on water" end
	if not (spawn_def.type_of_spawning ~= "lava" or is_lava) then return false, "lava mobs only on lava" end
	if not ( not spawn_protected or not core.is_protected(pos, "") ) then return false, "spawn protected" end
	if is_bedrock then return false, "no spawn on bedrock" end

	-- More expensive checks last
	local biome = core.get_biome_data(pos)
	if not biome then return false, "no biome found" end
	biome = core.get_biome_name(biome.biome) --makes it easier to work with
	if not ( not spawn_def.biomes_except or (spawn_def.biomes_except and not biome_check(spawn_def.biomes_except, biome))) then return false, "biomes_except failed" end
	if not ( not spawn_def.biomes or (spawn_def.biomes and biome_check(spawn_def.biomes, biome))) then return false, "biome check failed" end

	local gotten_light = core.get_node_light(pos)
	local my_node = core.get_node(pos)
	local sky_light = core.get_natural_light(pos)
	local art_light = core.get_artificial_light(my_node.param1)
	if modern_lighting then

		if mob_def.check_light then
			return mob_def.check_light(pos, gotten_light, art_light, sky_light)
		elseif mob_type == "monster" then
			if dimension == "nether" then
				if art_light > nether_threshold then
					return false, "too bright"
				end
			elseif dimension == "end" then
				if art_light > end_threshold then
					return false, "too bright"
				end
			elseif dimension == "overworld" then
				if art_light > overworld_threshold or sky_light > overworld_sky_threshold then
					return false, "too bright"
				end
			end
		else
			-- passive threshold is apparently the same in all dimensions ...
			if gotten_light <= overworld_passive_threshold then
				return false, "too dark"
			end
		end
	else
		if gotten_light < spawn_def.min_light then return false,"too dark" end
		if gotten_light > spawn_def.max_light then return false,"too bright" end
	end

	local mob_count_wide = 0
	local mob_count = 0
	if not ignore_caps then
		mob_count = count_mobs(pos,32,mob_type)
		mob_count_wide = count_mobs(pos,aoc_range,mob_type)
	end

	if ( mob_count_wide >= (mob_cap[mob_type] or 15) ) then return false,"mob cap wide full" end
	if ( mob_count >= 5 ) then return false, "local mob cap full" end

	return true, ""
end

function mcl_mobs.spawn(pos,id, staticdata)
	local def = core.registered_entities[id] or core.registered_entities["mobs_mc:"..id] or core.registered_entities["extra_mobs:"..id]
	if not def or (def.can_spawn and not def.can_spawn(pos)) or not def.is_mob then
		return false
	end
	if not dbg_spawn_counts[def.name] then
		dbg_spawn_counts[def.name] = 1
	else
		dbg_spawn_counts[def.name] = dbg_spawn_counts[def.name] + 1
	end
	return core.add_entity(pos, def.name, staticdata)
end

function mob_class.spawn_group_member_data (idx)
	return nil
end

local function spawn_group(p,mob,spawn_on,group_max,group_min)
	if not group_min then group_min = 1 end
	local mob_def = core.registered_entities[mob.name]
	local nn= core.find_nodes_in_area_under_air(vector.offset(p,-5,-3,-5),vector.offset(p,5,3,5),spawn_on)
	local group_members = {}
	local o
	table.shuffle(nn)
	if not nn or #nn < 1 then
		nn = {}
		table.insert(nn,p)
	end
	for i = 1, math.random(group_min,group_max) do
		local sp = vector.offset(nn[math.random(#nn)],0,1,0)
		if spawn_check(nn[math.random(#nn)],mob) then
			if mob.type_of_spawning == "water" then
				sp = get_water_spawn(sp)
			end
			local data
				= mob_def.spawn_group_member_data (i)
			o = mcl_mobs.spawn (sp, mob.name, data)
			if o then
				dbg_spawn_succ = dbg_spawn_succ + 1
				table.insert (group_members, o)
			end
		end
	end
	local init_func = mob_def.initialize_group
	if init_func and #group_members > 0 then
		init_func (group_members)
	end
	return o
end

function mob_class:despawn_allowed ()
	local nametag = self.nametag and self.nametag ~= ""
	if self.can_despawn == true then
		if not nametag and not self.tamed
			and not self.persistent
		-- _just_portaled mobs should not despawn to allow
		-- mapblocks containing them to be unloaded if no
		-- players are nearby.
			and not self._just_portaled
		-- Mobs that are attached to other objects should
		-- never despawn.
			and not self.object:get_attach () then
			return true
		end
	end
	return false
end

mcl_mobs.spawn_group = spawn_group

local S = core.get_translator("mcl_mobs")

--extra checks for mob spawning
local function can_spawn(spawn_def,spawning_position)
	if spawn_def.type_of_spawning == "water" then
		spawning_position = get_water_spawn(spawning_position)
		if not spawning_position then
			core.log("warning","[mcl_mobs] no water spawn for mob "..spawn_def.name.." found at "..core.pos_to_string(vector.round(spawning_position)))
			return
		end
	end
	if core.registered_entities[spawn_def.name].can_spawn and not core.registered_entities[spawn_def.name].can_spawn(spawning_position) then
		core.log("warning","[mcl_mobs] mob "..spawn_def.name.." refused to spawn at "..core.pos_to_string(vector.round(spawning_position)))
		return false
	end
	return true
end

mcl_mobs.can_spawn = can_spawn
mcl_mobs.spawn_dictionary = spawn_dictionary

local passive_timer = PASSIVE_INTERVAL

--timer function to check if passive mobs should spawn (only every 20 secs unlike other mob spawn classes)
local function check_timer(spawn_def)
	local mob_def = core.registered_entities[spawn_def.name]
	if mob_def and mob_def.spawn_class == "passive" then
		if passive_timer > 0 then
			return false
		else
			passive_timer = PASSIVE_INTERVAL
		end
	end
	return true
end

local MOB_SPAWN_ZONE_INNER = 24
local MOB_SPAWN_ZONE_OUTER = 128


local SPAWN_MAPGEN_LIMIT = math.abs(mcl_vars.mapgen_edge_min)

local function math_round(x) return (x > 0) and math.floor(x + 0.5) or math.ceil(x - 0.5) end

local function get_next_mob_spawn_pos(pos)
	-- Select a distance such that distances closer to the player are selected much more often than
	-- those further away from the player. This does produce a concentration at INNER (24 blocks)
	local distance = math.random()^2 * (MOB_SPAWN_ZONE_OUTER - MOB_SPAWN_ZONE_INNER) + MOB_SPAWN_ZONE_INNER
	local dir = vector.random_direction()
	-- core.log("action", "Using spawn distance of "..tostring(distance).." in direction "..core.pos_to_string(dir))
	local goal_pos = vector.offset(pos, dir.x * distance, dir.y * distance, dir.z * distance)

	if not ( math.abs(goal_pos.x) <= SPAWN_MAPGEN_LIMIT and math.abs(goal_pos.y) <= SPAWN_MAPGEN_LIMIT and math.abs(goal_pos.z) <= SPAWN_MAPGEN_LIMIT ) then
		return nil
	end

	-- Calculate upper/lower y limits
	local R1 = distance + 3
	local d = vector.distance( pos, vector.new( goal_pos.x, pos.y, goal_pos.z ) ) -- distance from player to projected point on horizontal plane
	local y1 = math.sqrt( R1*R1 - d*d ) -- absolue value of distance to outer sphere

	local y_min
	local y_max
	if d >= MOB_SPAWN_ZONE_INNER then
		-- Outer region, y range has both ends on the outer sphere
		y_min = pos.y - y1
		y_max = pos.y + y1
	else
		-- Inner region, y range spans between inner and outer spheres
		local R2 = MOB_SPAWN_ZONE_INNER
		local y2 = math.sqrt( R2*R2 - d*d )
		if goal_pos.y > pos. y then
			-- Upper hemisphere
			y_min = pos.y + y2
			y_max = pos.y + y1
		else
			-- Lower hemisphere
			y_min = pos.y - y1
			y_max = pos.y - y2
		end
	end
	y_min = math_round(y_min)
	y_max = math_round(y_max)

	local spawning_position_list = core.find_nodes_in_area_under_air(
			{x = goal_pos.x, y = y_min, z = goal_pos.z},
			{x = goal_pos.x, y = y_max, z = goal_pos.z},
			{"group:opaque", "group:water", "group:lava"}
	) or {}

	-- Select only the locations at a valid distance
	local valid_positions = {}
	for _,check_pos in ipairs(spawning_position_list) do
		local dist = vector.distance(pos, check_pos)
		if dist >= MOB_SPAWN_ZONE_INNER and dist <= MOB_SPAWN_ZONE_OUTER then
			table.insert(valid_positions, check_pos)
		end
	end

	if #valid_positions == 0 then return end
	return valid_positions[math.random(#valid_positions)]

end


if mobs_spawn and mobs_spawn_old then
	local cumulative_chance
	local mob_library_worker_table
	local function initialize_spawn_data()
		if not mob_library_worker_table then
			mob_library_worker_table = table.copy(spawn_dictionary)
		end
		if not cumulative_chance then
			cumulative_chance = 0
			for _, v in pairs(mob_library_worker_table) do
				cumulative_chance = cumulative_chance + v.chance
			end
		end
	end

	local function spawn_a_mob(pos, _, _)
		--create a disconnected clone of the spawn dictionary
		--prevents memory leak

		local mob_library_worker_table = table.copy(spawn_dictionary)
		local spawning_position = get_next_mob_spawn_pos(pos)

		local spawn_loop_counter = #mob_library_worker_table
		--use random weighted choice with replacement to grab a mob, don't exclude any possibilities
		--shuffle table once every loop to provide equal inclusion probability to all mobs
		--repeat grabbing a mob to maintain existing spawn rates
		while spawn_loop_counter > 0 do
			table.shuffle(mob_library_worker_table)
			local mob_chance_offset = math.random(1, cumulative_chance)
			local mob_index = 1
			local mob_chance = mob_library_worker_table[mob_index].chance
			local step_chance = mob_chance
			while step_chance < mob_chance_offset do
				mob_index = mob_index + 1
				if mob_index <= #mob_library_worker_table then
					mob_chance = mob_library_worker_table[mob_index].chance
					step_chance = step_chance + mob_chance
				else
					break
				end
				mob_chance = mob_library_worker_table[mob_index].chance
				step_chance = step_chance + mob_chance
			end
			local spawn_def = mob_library_worker_table[mob_index]
			--core.log(spawn_def.name.." "..step_chance.. " "..mob_chance)
			if spawn_def and spawn_def.name and core.registered_entities[spawn_def.name] then
				local spawn_in_group = spawn_def.spawn_in_group
					or core.registered_entities[spawn_def.name].spawn_in_group or 4
				local spawn_in_group_min = spawn_def.spawn_in_group_min
					or core.registered_entities[spawn_def.name].spawn_in_group_min or 1
				local mob_type = core.registered_entities[spawn_def.name].type
				if spawn_check(spawning_position,spawn_def) then

					if can_spawn(spawn_def,spawning_position) and check_timer(spawn_def) then
						--everything is correct, spawn mob
						if spawn_in_group and ( mob_type ~= "monster" or math.random(5) == 1 ) then
							if logging then
								core.log("action", "[mcl_mobs] A group of mob " .. spawn_def.name .. " spawns on " ..core.get_node(vector.offset(spawning_position,0,-1,0)).name .." at " .. core.pos_to_string(spawning_position, 1))
							end
							spawn_group(spawning_position,spawn_def,{core.get_node(vector.offset(spawning_position,0,-1,0)).name},spawn_in_group,spawn_in_group_min)

						else
							if logging then
								core.log("action", "[mcl_mobs] Mob " .. spawn_def.name .. " spawns on " ..core.get_node(vector.offset(spawning_position,0,-1,0)).name .." at ".. core.pos_to_string(spawning_position, 1))
							end
							mcl_mobs.spawn(spawning_position, spawn_def.name)
						end
					end
				end
			end
			spawn_loop_counter = spawn_loop_counter - 1
		end
	end


	--MAIN LOOP

	local timer = HOSTILE_INTERVAL
	core.register_globalstep(function(dtime)
		passive_timer = passive_timer - dtime
		timer = timer - dtime
		if timer > 0 then return end
		timer = HOSTILE_INTERVAL

		local players = core.get_connected_players()
		local total_mobs = count_mobs_total_cap()
		if total_mobs > mob_cap.total or total_mobs > #players * mob_cap.player then
			core.log("action","[mcl_mobs] global mob cap reached. no cycle spawning.")
			return
		end --mob cap per player

		initialize_spawn_data()
		for _, player in pairs(players) do
			local pos = player:get_pos()
			local dimension = mcl_worlds.pos_to_dimension(pos)
			-- ignore void and unloaded area
			if dimension ~= "void" and dimension ~= "default" then
				spawn_a_mob(pos, dimension, dtime)
			end
		end
	end)
end

function mob_class:despawn_ok (d_to_closest_player)
	return true
end

local scale_chance = mcl_mobs.scale_chance

function mob_class:check_despawn(pos, dtime)
	if remove_far and self:despawn_allowed() then
		local min_dist = math.huge
		for player in mcl_util.connected_players () do
			min_dist = math.min (min_dist, vector.distance (player:get_pos (), pos))
		end

		if not self:despawn_ok (min_dist) then
			self._inactivity_timer = 0
			return false
		elseif min_dist > instant_despawn_range then
			self:kill_me ("no players within distance " .. instant_despawn_range)
			return true
		elseif min_dist > random_despawn_range then
			if self._inactivity_timer >= 30.0 then
				if math.random (1, scale_chance (800, dtime)) == 1 then
					self:kill_me ("random chance at distance " .. math.round(min_dist))
					return true
				end
			else
				local t = self._inactivity_timer + dtime

				-- This timer should be reset once a
				-- player approaches, or when damage
				-- is sustained from any source.
				self._inactivity_timer = t
			end

			return false
		end
	end
	return false
end

function mob_class:kill_me(msg)
	if logging then
		core.log("action", "[mcl_mobs] Mob " .. self.name .. " despawns at " .. core.pos_to_string(self.object:get_pos(), 1) .. ": " .. msg)
	end
	if self._jockey_rider then
		if is_valid (self._jockey_rider) then
			-- Detach this rider.
			local entity = self._jockey_rider:get_luaentity ()
			entity:unjock ()
			entity.jockey_vehicle = nil
		end
		self._jockey_rider = nil
	end
	self:safe_remove()
end

core.register_chatcommand("spawn_mob",{
	privs = { debug = true },
	description=S("spawn_mob is a chatcommand that allows you to type in the name of a mob without 'typing mobs_mc:' all the time like so; 'spawn_mob spider'. however, there is more you can do with this special command, currently you can edit any number, boolean, and string variable you choose with this format: spawn_mob 'any_mob:var<mobs_variable=variable_value>:'. any_mob being your mob of choice, mobs_variable being the variable, and variable value being the value of the chosen variable. and example of this format: \n spawn_mob skeleton:var<passive=true>:\n this would spawn a skeleton that wouldn't attack you. REMEMBER-THIS> when changing a number value always prefix it with 'NUM', example: \n spawn_mob skeleton:var<jump_height=NUM10>:\n this setting the skelly's jump height to 10. if you want to make multiple changes to a mob, you can, example: \n spawn_mob skeleton:var<passive=true>::var<jump_height=NUM10>::var<fly_in=air>::var<fly=true>:\n etc."),
	func = function(n,param)
		local pos = core.get_player_by_name(n):get_pos()

		local modifiers = {}
		for capture in string.gmatch(param, "%:(.-)%:") do
			table.insert(modifiers, ":"..capture)
		end

		local mod1 = string.find(param, ":")



		local mobname = param
		if mod1 then
			mobname = string.sub(param, 1, mod1-1)
		end

		local mob = mcl_mobs.spawn(pos, mobname, core.serialize({ persist_in_peaceful = true }))

		if mob then
			for c=1, #modifiers do
				local modifs = modifiers[c]

				local mod1 = string.find(modifs, ":")
				local mod_start = string.find(modifs, "<")
				local mod_vals = string.find(modifs, "=")
				local mod_end = string.find(modifs, ">")
				local mob_entity = mob:get_luaentity()
				if string.sub(modifs, mod1+1, mod1+3) == "var" then
					if mod1 and mod_start and mod_vals and mod_end then
						local variable = string.sub(modifs, mod_start+1, mod_vals-1)
						local value = string.sub(modifs, mod_vals+1, mod_end-1)

						local number_tag = string.find(value, "NUM")
						if number_tag then
							value = tonumber(string.sub(value, 4, -1)) ---@diagnostic disable-line: cast-local-type
						end

						if value == "true" then
							value = true ---@diagnostic disable-line: cast-local-type
						elseif value == "false" then
							value = false ---@diagnostic disable-line: cast-local-type
						end

						if not mob_entity[variable] then
							core.log("warning", n.." mob variable "..variable.." previously unset")
						end

						mob_entity[variable] = value

					else
						core.log("warning", n.." couldn't modify "..mobname.." at "..core.pos_to_string(pos).. ", missing paramaters")
					end
				else
					core.log("warning", n.." couldn't modify "..mobname.." at "..core.pos_to_string(pos).. ", missing modification type")
				end
			end

			core.log("action", n.." spawned "..mobname.." at "..core.pos_to_string(pos))
			return true, mobname.." spawned at "..core.pos_to_string(pos)
		else
			return false, "Couldn't spawn "..mobname
		end
	end
})
core.register_chatcommand("spawncheck",{
	privs = { debug = true },
	func = function(n,param)
		local pl = core.get_player_by_name(n)
		local pos = vector.offset(pl:get_pos(),0,-1,0)
		local dim = mcl_worlds.pos_to_dimension(pos)
		local sp
		for _,v in pairs(spawn_dictionary) do
			if v.name == param and v.dimension == dim then sp = v end
		end
		if sp then
			core.log(dump(sp))
			local r,t = spawn_check(pos,sp)
			if r then
				return true, "spawn check for "..sp.name.." at "..core.pos_to_string(pos).." successful"
			else
				return r,tostring(t) or ""
			end
		else
			return false,"no spawndef found for "..param
		end
	end
})

local SPAWN_DISTANCE = tonumber (core.settings:get ("active_block_range")) or 4
local MOB_CAP_DIVISOR = 289
local MOB_CAP_RECIPROCAL = 1 / MOB_CAP_DIVISOR
local OVERWORLD_CEILING_MARGIN = 64
local OVERWORLD_DEFAULT_CEILING = 256

-- Return a range of positions along the vertical axes in which to
-- spawn mobs around a player at POS in the dimension LEVEL.

local function level_y_range (level, pos)
	if level == "overworld" then
		local nodepos = math.floor (pos.y + 0.5)
		-- Spawn mobs between the bottom of the overworld and
		-- OVERWORLD_DEFAULT_CEILING.
		if nodepos < OVERWORLD_DEFAULT_CEILING - OVERWORLD_CEILING_MARGIN then
			return mcl_vars.mg_overworld_min, OVERWORLD_DEFAULT_CEILING
		else
			-- Otherwise spawn between nodepos - 236 and
			-- nodepos + 64.
			return nodepos
				- OVERWORLD_DEFAULT_CEILING
				+ OVERWORLD_CEILING_MARGIN
				+ mcl_vars.mg_overworld_min,
				nodepos + OVERWORLD_CEILING_MARGIN
		end
	elseif level == "nether" then
		return mcl_vars.mg_nether_min,
			mcl_vars.mg_nether_max - 1
	elseif level == "end" then
		return mcl_vars.mg_end_min,
			mcl_vars.mg_end_max_official - 1
	end
end

local function merge_range (rangearray, start, fin)
	local nmax, first_overlap, last_overlap = #rangearray
	local last_before = 0
	assert (nmax % 2 == 0)

	-- Locate the index of the final pairs whose start and end
	-- values precede START and FIN.
	for i = 1, nmax, 2 do
		if rangearray[i] < start then
			last_before = i + 1
		end
		if rangearray[i] <= fin and start <= rangearray[i + 1] then
			if not first_overlap then
				first_overlap = i
			end
			last_overlap = i
		end
	end

	if first_overlap then
		-- Fast case.
		if rangearray[first_overlap] == start
			and rangearray[last_overlap + 1] == fin then
			return
		end

		-- Consider first_overlap's start and last_overlap's fin.
		-- Combine them and all in between into a solitary range
		-- and adjust their bounds to encompass this one.

		if rangearray[first_overlap] > start then
			rangearray[first_overlap] = start
		end

		local value = rangearray[last_overlap + 1]
		-- Index of first element to preserve.
		local src_begin = last_overlap + 2
		-- New index after it is moved.
		local dst_begin = first_overlap + 2

		if src_begin ~= dst_begin then
			local num_copies = nmax - src_begin + 1
			for i = 0, num_copies - 1 do
				rangearray[dst_begin + i]
					= rangearray[src_begin + i]
			end
			-- Clear the remainder of the array
			-- (i.e. shrink it).
			for i = dst_begin + num_copies, nmax do
				rangearray[i] = nil
			end
		end
		rangearray[first_overlap + 1] = math.max (value, fin)
	else
		-- No ranges overlap.  Insert START, FIN into their
		-- proper position.
		local new_max = nmax + 2
		for i = 0, nmax - last_before - 1 do
			rangearray[new_max - i] = rangearray[nmax - i]
		end
		rangearray[last_before + 1] = start
		rangearray[last_before + 2] = fin
	end
	return rangearray
end

local function position_in_chunk (data)
	local total = 0
	local ranges = data.y_ranges
	local psize = #ranges
	for i = 1, psize, 2 do
		total = total + (ranges[i + 1] - ranges[i] + 1)
	end
	local value = math.random (1, total)
	for i = 1, psize, 2 do
		value = value - (ranges[i + 1] - ranges[i] + 1)
		if value <= 0 then
			return ranges[i + 1] + value
		end
	end
	-- Shouldn't ever be reached.
	assert (false)
end

local function collect_unique_chunks (level)
	local chunk_data, chunks, players = {}, {}, {}
	for player in mcl_util.connected_players () do
		-- Players outside any dimension should not be
		-- considered for spawning.
		local pos = player:get_pos ()
		local chunk_x = math.floor (pos.x / 16.0)
		local chunk_z = math.floor (pos.z / 16.0)
		local chunk_dim = mcl_worlds.pos_to_dimension (pos)
		players[player] = pos

		if chunk_dim == level then
			local start, fin = level_y_range (level, pos)

			for x = chunk_x - SPAWN_DISTANCE, chunk_x + SPAWN_DISTANCE do
				for z = chunk_z - SPAWN_DISTANCE, chunk_z + SPAWN_DISTANCE do
					local hash = ((x + 2048) * 4096) + (z + 2048)
					local data = chunk_data[hash]
					if not data then
						table.insert (chunks, hash)
						chunk_data[hash] = {
							y_ranges = {
								start, fin,
							},
						}
					else
						merge_range (data.y_ranges, start, fin)
					end
				end
			end
		end
	end
	return chunks, players, chunk_data
end

local function collect_all_unique_chunks ()
	local chunks = {}
	local n_chunks = 0

	chunks["overworld"] = { collect_unique_chunks ("overworld") }
	n_chunks = n_chunks + #chunks.overworld[1]
	chunks["nether"] = { collect_unique_chunks ("nether") }
	n_chunks = n_chunks + #chunks.nether[1]
	chunks["end"] = { collect_unique_chunks ("end") }
	n_chunks = n_chunks + #chunks["end"][1]
	return chunks, n_chunks
end

-- Chunk count from which to derive a number of mobs which, if
-- exceeded by overfulfillment of the mob caps, will induce reloaded
-- mobs immediately to despawn.
local spawn_border_chunks
local current_mob_caps = {}

core.register_chatcommand("mobstats",{
	privs = { debug = true },
	func = function(n, _)
		if mobs_spawn_old then
			core.chat_send_player(n,dump(dbg_spawn_counts))
			local pos = core.get_player_by_name(n):get_pos()
			core.chat_send_player(n,"mobs within 32 radius of player:"..count_mobs(pos,32))
			core.chat_send_player(n,"total mobs:"..count_mobs_total())
			core.chat_send_player(n,"spawning attempts since server start:"..dbg_spawn_attempts)
			core.chat_send_player(n,"successful spawns since server start:"..dbg_spawn_succ)


			local mob_counts, total_mobs = count_mobs_all()
			if (total_mobs) then
				core.log("action", "Total mobs found: " .. total_mobs)
			end
			if mob_counts then
				for k, v1 in pairs(mob_counts) do
					core.log("action", "k: " .. tostring(k))
					core.log("action", "v1: " .. tostring(v1))
				end
			end
		else
			local mob_caps = {}
			local pos = core.get_player_by_name (n):get_pos ()
			local level = mcl_worlds.pos_to_dimension (pos)

			if level == "void" then
				local blurb = "No spawning data is available in the Void"
				core.chat_send_player (n, blurb)
				return
			end

			local _, n_chunks = collect_all_unique_chunks ()
			for category, data in pairs (mcl_mobs.spawn_categories) do
				local global_max
					= math.floor ((n_chunks * data.chunk_mob_cap)
						* MOB_CAP_RECIPROCAL)
				global_max = math.max (global_max, data.min_chunk_mob_cap)
				mob_caps[category] = global_max
			end

			core.chat_send_player (n, table.concat ({
				"Currently active mobs by category: ",
				dump (mcl_mobs.active_mobs_by_category),
				"\n",
				"Chunk-derived mob caps (per-level): ",
				dump (mob_caps), "\n",
				"Chunk count: ", tostring (n_chunks), "\n",
				"Mob cap overfulfillment theshold: ",
				tostring (spawn_border_chunks), "\n",
				"No. active mobs in total: ",
				tostring (count_mobs_total ()), "\n"
			}))

			local mob_counts, _ = count_mobs_all ()
			for k, v1 in pairs (mob_counts) do
				core.chat_send_player (n, table.concat ({
					"  ", k, ": ", tostring (v1),
				}))
			end
		end
	end
})

------------------------------------------------------------------------
-- Minecraft-like spawning mechanics.
------------------------------------------------------------------------

local MAX_PACK_SIZE = 8

function mob_class:check_despawn_on_activation (self_pos)
	if not self:despawn_allowed ()
	-- New spawns (e.g. from infested blocks or mob spawners)
	-- should always be permitted.
		or not self._reloaded then
		return false
	end

	local category = self._spawn_category
	local caps = mcl_mobs.spawn_categories[category]

	-- Have mob caps been exceeded by a greater number of mobs
	-- than the previously established number of border blocks
	-- permit?

	if caps then
		local level = mcl_worlds.pos_to_dimension (self_pos)
		if level == "void" then
			return false
		end

		-- Mobs loaded before mob caps were first initialized.
		local global = current_mob_caps
		if not global then
			core.log ("warning", self.name .. " was loaded before spawning "
				  .. "was initialized.")
			return false
		end

		local active = mcl_mobs.active_mobs_by_category[category]
		if active and active > global[category] then
			local border = spawn_border_chunks
			local buffer
				= math.floor ((caps.chunk_mob_cap * border)
					* MOB_CAP_RECIPROCAL)
			buffer = buffer + MAX_PACK_SIZE
			if active > buffer then
				if logging then
					core.log ("action", table.concat ({
						"[mcl_mobs] ", self.name,
						" at ", vector.to_string (self_pos),
						" is despawning as it is more than ",
						tostring (buffer), " mobs over the",
						" mob cap for `", category, "' (",
						tostring (global[category]), ")",
					}))
				end
				self.object:remove ()
				return true
			end
		end
	end
	return false
end

function mob_class:announce_for_spawning ()
	local category = self._spawn_category
	local n_active = mcl_mobs.active_mobs_by_category[category]
	if not n_active then
		n_active = 0
	end
	mcl_mobs.active_mobs_by_category[category] = n_active + 1
	self._activated = true
	local self_pos = self.object:get_pos ()
	return self:check_despawn_on_activation (self_pos)
end

function mob_class:remove_for_spawning ()
	self._activated = nil

	-- Record this mob's absence.
	local category = self._spawn_category
	local n_active = mcl_mobs.active_mobs_by_category[category]
	if not n_active or n_active <= 0 then
		return
	end
	mcl_mobs.active_mobs_by_category[category] = n_active - 1
end

function mob_class:update_mob_caps ()
	local persistent = (self.persistent or self.tamed)
	if self._activated and persistent then
		self:remove_for_spawning ()
	elseif not self._activated and not persistent then
		-- Value is whether this process prompted the mob to
		-- be deleted.
		return self:announce_for_spawning ()
	end
	return false
end

local active_mobs_by_category = {}
local registered_spawners = {}

-- This map between spawner lists and their total weight is rather
-- contrived but avoids the creation of combined hash tables/arrays,
-- which are NYIs in Luajit...
local total_weight = {}

mcl_mobs.active_mobs_by_category = active_mobs_by_category
mcl_mobs.registered_spawners = registered_spawners

-- https://nekoyue.github.io/ForgeJavaDocs-NG/javadoc/1.18.2/net/minecraft/world/entity/MobCategory.html

local spawn_categories = {
	["monster"] = {
		chunk_mob_cap = 70,
		min_chunk_mob_cap = 45,
		is_friendly = false,
		is_animal = false,
	},
	["creature"] = {
		chunk_mob_cap = 10,
		min_chunk_mob_cap = 10,
		is_friendly = false,
		is_animal = true,
	},
	["ambient"] = {
		chunk_mob_cap = 15,
		min_chunk_mob_cap = 15,
		is_friendly = true,
		is_animal = false,
	},
	["axolotl"] = {
		chunk_mob_cap = 5,
		min_chunk_mob_cap = 5,
		is_friendly = true,
		is_animal = false,
	},
	["underground_water_creature"] = {
		chunk_mob_cap = 5,
		min_chunk_mob_cap = 5,
		is_friendly = true,
		is_animal = false,
	},
	["water_creature"] = {
		chunk_mob_cap = 5,
		min_chunk_mob_cap = 5,
		is_friendly = true,
		is_animal = false,
	},
	["water_ambient"] = {
		chunk_mob_cap = 5,
		min_chunk_mob_cap = 5,
		is_friendly = true,
		is_animal = false,
	},
}
mcl_mobs.spawn_categories = spawn_categories

local NUM_MONSTER_CATEGORIES = 6
local NUM_CREATURE_CATEGORIES = 1

local function dist_sqr (a, b)
	local dx = b.x - a.x
	local dy = b.y - a.y
	local dz = b.z - a.z
	return dx * dx + dy * dy + dz * dz
end

-- local function horiz_dist_sqr (ax, az, bx, bz)
-- 	local dx = bx - ax
-- 	local dz = bz - az
-- 	return dx * dx + dz * dz
-- end

local function get_nearest_player (pos, list)
	local dist, pos_nearest, player = nil

	for player_1, test_pos in pairs (list) do
		local d = dist_sqr (test_pos, pos)
		if not dist or dist > d then
			dist = d
			pos_nearest = test_pos
			player = player_1
		end
	end

	return player, pos_nearest
end

local function get_weighted_value (mob_types)
	local weight = math.random (total_weight[mob_types])
	for _, spawner in pairs (mob_types) do
		weight = weight - spawner.weight
		if weight <= 0 then
			return spawner
		end
	end
	return nil
end

local function get_eligible_spawn_type (pos, category)
	local value
	local biome = core.get_biome_data (pos)
	if biome then
		local spawners = registered_spawners[biome.biome]
		if spawners then
			-- XXX: reduce chances of spawning ambient water
			-- creatures in rivers if possible.
			local mob_types = spawners[category]
			if mob_types then
				value = get_weighted_value (mob_types)
			end
		end
	end
	return value
end

local function test_spawn_position (mob_def, spawn_pos, node_pos, sdata, node_cache)
	local value = mob_def:test_spawn_position (spawn_pos, node_pos, sdata,
						   node_cache)
	return value
end

local function test_spawn_clearance (mob_def, spawn_pos, sdata)
	local value = mob_def:test_spawn_clearance (spawn_pos, sdata)
	return value
end

local function spawn_a_pack (pos, players, category, scratch0)
	local player, player_pos = get_nearest_player (pos, players)
	assert (player and player_pos)

	local mob_def = get_eligible_spawn_type (pos, category)
	if not mob_def then
		return
	end
	local pack_size = math.random (mob_def.pack_min, mob_def.pack_max)

	local sdata = mob_def:prepare_to_spawn (pack_size, pos)
	local x, y, z = pos.x, pos.y, pos.z
	local spawn_pos = scratch0
	spawn_pos.y = y - 0.5

	local n_spawned, spawned = 0, mob_def.init_group and {}
	for i = 1, pack_size do
		local dx = math.random (0, 5) - math.random (0, 5)
		local dz = math.random (0, 5) - math.random (0, 5)
		spawn_pos.x = x + dx
		spawn_pos.z = z + dz
		pos.x = x + dx
		pos.z = z + dz
		local dist = dist_sqr (player_pos, spawn_pos)

		-- Is it possible to spawn mobs here?
		if dist < mob_def.despawn_distance_sqr
			and dist > 576.0
			and test_spawn_position (mob_def, spawn_pos, pos, sdata, {})
			and test_spawn_clearance (mob_def, spawn_pos, sdata) then
			local object = mob_def:spawn (spawn_pos, n_spawned + 1, sdata)
			if object then
				n_spawned = n_spawned + 1
				if spawned then
					spawned[n_spawned] = object
				end
			end
		end
	end
	if logging and n_spawned > 0 then
		if n_spawned == 1 then
			local blurb = "[mcl_mobs] Spawned "
				.. mob_def.name .. " at "
				.. vector.to_string (spawn_pos)
			core.log ("action", blurb)
		else
			local blurb = "[mcl_mobs] Spawned pack of "
				.. n_spawned .. " ".. mob_def.name
				.. " around " .. vector.to_string (pos)
			core.log ("action", blurb)
		end
	end
	if n_spawned > 0 and mob_def.init_group then
		mob_def:init_group (spawned, sdata)
	end
end

local function unpack3 (x)
	return x[1], x[2], x[3]
end

function mcl_mobs.spawn_cycle (level, chunks, n_chunks, spawn_animals)
	local scratch0 = vector.zero ()

	-- Collect a list of chunks to evaluate for purposes of
	-- spawning.
	local chunks, players, chunk_data = unpack3 (chunks[level])
	local mobs_spawned = {}

	-- Shuffle the list of chunks to be evaluated.
	table.shuffle (chunks)

	local test_pos = vector.zero ()
	local n_chunks_orig = n_chunks

	-- Divide the number of chunks to be evaluated by the number
	-- of eligible categories.
	local num_categories = NUM_CREATURE_CATEGORIES
	if not spawn_animals then
		num_categories = NUM_MONSTER_CATEGORIES
	end

	-- Calculate mob caps and cache them in current_mob_caps.
	local caps = current_mob_caps

	for category, data in pairs (spawn_categories) do
		local mob_cap = data.chunk_mob_cap
		-- Verify that global mob caps have not been exceeded.
		local global_max
			= math.floor ((n_chunks_orig * mob_cap)
				* MOB_CAP_RECIPROCAL)
		-- Although the number of chunks loaded by default is
		-- smaller than in Minecraft, yet this disparity
		-- renders it almost impossible for certain animals to
		-- spawn.  A lower bound is placed on their mob caps
		-- to address this.
		global_max = math.max (global_max, data.min_chunk_mob_cap)
		caps[category] = global_max
	end

	local n_chunks = math.ceil (#chunks / num_categories)
	for i = 1, n_chunks do
		local chunk = chunks[i]
		local x = math.floor (chunk / 4096) - 2048
		local z = chunk % 4096 - 2048
		local center_x = (x * 16) + 7.5
		local center_z = (z * 16) + 7.5
		local eligible = false

		-- Is any player within 128 blocks of this chunk
		-- horizontally?
		for _, pos in pairs (players) do
			local dist = (pos.x - center_x) * (pos.x - center_x)
				+ (pos.z - center_z) * (pos.z - center_z)
			if dist < 16384.0 then
				eligible = true
				break
			end
		end

		if eligible then
			for key, _ in pairs (spawn_categories) do
				mobs_spawned[key] = active_mobs_by_category[key] or 0
			end
			for category, existing in pairs (mobs_spawned) do
				local data = spawn_categories[category]
				if (data.is_animal and spawn_animals)
					or (not data.is_animal and not spawn_animals) then
					local global_max = caps[category]
					-- Verify that global mob caps
					-- have not been exceeded.
					if existing < global_max then
						-- Select a random position.
						test_pos.x = math.random (x * 16, x * 16 + 15)
						test_pos.z = math.random (z * 16, z * 16 + 15)
						test_pos.y = position_in_chunk (chunk_data[chunk])
						spawn_a_pack (test_pos, players, category, scratch0)
					end
				end
			end
		end
	end
end

local default_spawner = {
	weight = 100,
	biomes = {},
	despawn_distance_sqr = 128 * 128,
	spawn_placement = "ground", -- misc, ground, aquatic, lava
	spawn_category = "misc", -- Should be identical to that of the
				 -- mob def.
	fire_immune = false,
	pack_min = 4,
	pack_max = 4,
}

function mcl_mobs.register_spawner (spawner)
	local spawner = table.merge (default_spawner, spawner)
	table.insert (registered_spawners, spawner)
end

mcl_mobs.default_spawner = default_spawner

-- Convert this table into a map between biome IDs and spawners
-- once all biomes are registered.

core.register_on_mods_loaded (function ()
	local output = {}
	local n = #registered_spawners
	for i = 1, n do
		local spawner = registered_spawners[i]
		for _, biome in pairs (spawner.biomes) do
			local id = core.get_biome_id (biome)
			if not id then
				core.log ("warning", table.concat ({
					"Unknown biome in mob spawner for ",
					spawner.name, ": ", biome,
				}))
			else
				if not output[id] then
					output[id] = {}
				end

				if not output[id][spawner.spawn_category] then
					output[id][spawner.spawn_category] = {}
				end

				local list = output[id][spawner.spawn_category]
				total_weight[list] = (total_weight[list] or 0) + spawner.weight
				table.insert (list, spawner)
			end
		end
	end
	registered_spawners = output
	mcl_mobs.registered_spawners = registered_spawners
end)

------------------------------------------------------------------------
-- Default spawning criteria.
------------------------------------------------------------------------

function mob_class:is_up_face_sturdy (pos)
	local node = core.get_node (pos)
	return mcl_mobs.is_up_face_sturdy (pos, node)
end

local cube = mcl_util.decompose_AABBs ({{
	-0.5, -0.5, -0.5,
	0.5, 0.5, 0.5,
}})
local up_face_sturdy = {}

core.register_on_mods_loaded (function ()
	for node, def in pairs (core.registered_nodes) do
		local node_type = def.paramtype2
		if not def.walkable
			or node_type == "flowingliquid" then
			up_face_sturdy[node] = false
		elseif node_type == "4dir"
			or node_type == "degrotate"
			or node_type == "color4dir"
			or node_type == "color"
			or node_type == "colordegrotate"
			or node_type == "none" then
			local boxes = def.node_box

			if not boxes or boxes.type == "regular" then
				up_face_sturdy[node] = true
			elseif boxes.type == "fixed" then
				-- Since these node types can only
				-- rotate around the Y axis, it is
				-- only necessary to verify that their
				-- up faces are full cubes.

				local fixed = boxes.fixed
				if fixed and type (fixed[1]) == "number" then
					fixed = {fixed}
				end
				local shape = mcl_util.decompose_AABBs (fixed)
				local face = shape:select_face ("y", 0.5)
				up_face_sturdy[node] = face:equal_p (cube)
			end
		else
			-- Only full cubes can be sturdy once rotation
			-- around other axes is involved.
			local boxes = def.node_box

			if not boxes or boxes.type == "regular" then
				up_face_sturdy[node] = true
			elseif boxes.type == "fixed" then
				-- Since these node types can only
				-- rotate around the Y axis, it is
				-- only necessary to verify that their
				-- up faces are full cubes.

				local fixed = boxes.fixed
				if fixed and type (fixed[1]) == "number" then
					fixed = {fixed}
				end
				local shape = mcl_util.decompose_AABBs (fixed)
				if shape:equal_p (cube) then
					up_face_sturdy[node] = true
				end
			end
		end
	end
end)

function mcl_mobs.is_up_face_sturdy (node, node_data)
	local sturdy = up_face_sturdy[node_data.name]
	if sturdy ~= nil then
		return sturdy
	end
	local boxes = core.get_node_boxes ("collision_box", node)
	local shape = mcl_util.decompose_AABBs (boxes)
	local up_face = shape and shape:select_face ("y", 0.5)
	return up_face and up_face:equal_p (cube)
end

function default_spawner:is_valid_spawn_ceiling (name)
	local def = core.registered_nodes[name]
	if name == "ignore"
		or not def
		or (def.walkable or def.liquidtype ~= "none")
		or (def.groups.no_spawning_inside
			and def.groups.no_spawning_inside ~= 0)
		or (def.damage_per_second > 0)
		or (not self.fire_immune
			and def.groups.fire
			and def.groups.fire ~= 0)
		or (not self.fire_immune
			and def.groups.lava
			and def.groups.lava ~= 0) then
		return false
	end
	return true
end

function default_spawner:get_node (node_cache, y_offset, base)
	local cache = node_cache[y_offset]
	if not cache then
		base.y = base.y + y_offset
		cache = core.get_node (base)
		node_cache[y_offset] = cache
		base.y = base.y - y_offset
	end
	return cache
end

-- Implementors may modified and/or reuse node_pos as a scratch value,
-- provided that they restore its original values before calling the
-- default test_spawn_position implementation.

function default_spawner:test_spawn_position (spawn_pos, node_pos, sdata, node_cache)
	local spawn_placement = self.spawn_placement
	if spawn_placement == "misc" then
		-- Just test that the position is loaded.
		return core.compare_block_status (node_pos, "active")
	elseif spawn_placement == "ground" then
		local node_below = self:get_node (node_cache, -1, node_pos)
		if core.get_item_group (node_below.name, "opaque") == 0
			or node_below.name == "mcl_core:bedrock" then
			return false
		end
		-- The up face of the supporting node must be sturdy.
		if node_below.name == "mcl_nether:soul_sand"
			or mcl_mobs.is_up_face_sturdy (node_pos, node_below) then
			-- The block here and the block above must not
			-- be opaque nor deal damage.
			local node_here = self:get_node (node_cache, 0, node_pos)
			local node_above = self:get_node (node_cache, 1, node_pos)

			return self:is_valid_spawn_ceiling (node_here.name)
				and self:is_valid_spawn_ceiling (node_above.name)
		end
		return false
	elseif spawn_placement == "aquatic" then
		local node = self:get_node (node_cache, 0, node_pos)
		if core.get_item_group (node.name, "water") > 0 then
			local above = self:get_node (node_cache, 1, node_pos)
			return core.get_item_group (above.name, "opaque") == 0
		end
		return false
	elseif spawn_placement == "lava" then
		local node = self:get_node (node_cache, 0, node_pos)
		if core.get_item_group (node.name, "lava") > 0 then
			return true
		end
	end
	return false
end

local function box_intersection (box, other_box)
	for index = 1, 3 do
		if box[index] > other_box[index + 3]
			or other_box[index] > box[index + 3] then
			return false
		end
	end
	return true
end

function default_spawner:test_collision (node, cbox)
	local node_data = core.get_node (node)
	if node_data.name == "ignore" then
		return true
	end
	local def = core.registered_nodes[node_data.name]

	if def and not def.walkable
		and ((self.spawn_placement == "aquatic"
			or self.spawn_placement == "lava")
			or def.liquidtype == "none") then
		return false
	end

	local boxes
		= core.get_node_boxes ("collision_box", node, node_data)
	for _, box in pairs (boxes) do
		box[1] = box[1] + node.x
		box[2] = box[2] + node.y
		box[3] = box[3] + node.z
		box[4] = box[4] + node.x
		box[5] = box[5] + node.y
		box[6] = box[6] + node.z

		if box_intersection (box, cbox) then
			return true
		end
	end
	return false
end

function default_spawner:test_spawn_clearance (spawn_pos, sdata)
	local mob_def = core.registered_entities[self.name]
	if not mob_def then
		return false
	end
	local cbox = mob_def.initial_properties.collisionbox
	if not cbox then
		return false
	end

	local cbox_1 = {
		cbox[1] + spawn_pos.x + 0.01,
		cbox[2] + spawn_pos.y + 0.01,
		cbox[3] + spawn_pos.z + 0.01,
		cbox[4] + spawn_pos.x - 0.01,
		cbox[5] + spawn_pos.y - 0.01,
		cbox[6] + spawn_pos.z - 0.01,
	}
	local xmin = math.floor (cbox_1[1] + 0.5)
	local ymin = math.floor (cbox_1[2] + 0.5)
	local zmin = math.floor (cbox_1[3] + 0.5)
	local xmax = math.floor (cbox_1[4] + 0.5)
	local ymax = math.floor (cbox_1[5] + 0.5)
	local zmax = math.floor (cbox_1[6] + 0.5)
	local v = vector.zero ()

	for z = zmin, zmax do
		v.z = z
		for x = xmin, xmax do
			v.x = x
			for y = ymin, ymax do
				v.y = y
				if self:test_collision (v, cbox_1) then
					return false
				end
			end
		end
	end
	return true
end

function default_spawner:spawn (spawn_pos, idx, sdata, pack_size)
	local staticdata = sdata and core.serialize (sdata)
	return core.add_entity (spawn_pos, self.name, staticdata)
end

function default_spawner:prepare_to_spawn (pack_size, center)
	return nil
end

if not mobs_spawn_old and mobs_spawn then

local spawn_timer = 0
local passive_spawn_timer = 0

core.register_globalstep (function (dtime)
	spawn_timer = spawn_timer - dtime
	passive_spawn_timer = passive_spawn_timer - dtime
	local chunks, n_chunks = collect_all_unique_chunks ()

	-- Calculate the number of chunks bordering this list of
	-- chunks as if it were a single rectangle.
	spawn_border_chunks
		= (math.floor (math.sqrt (n_chunks)) + 1) * 4

	if spawn_timer <= 0 then
		mcl_mobs.spawn_cycle ("overworld", chunks, n_chunks, false)
		mcl_mobs.spawn_cycle ("nether", chunks, n_chunks, false)
		mcl_mobs.spawn_cycle ("end", chunks, n_chunks, false)
		spawn_timer = 0.05
	end
	if passive_spawn_timer <= 0 then
		mcl_mobs.spawn_cycle ("overworld", chunks, n_chunks, true)
		mcl_mobs.spawn_cycle ("nether", chunks, n_chunks, true)
		mcl_mobs.spawn_cycle ("end", chunks, n_chunks, true)
		passive_spawn_timer = 10.0
	end
end)

end

------------------------------------------------------------------------
-- Spawn testing utilities.
------------------------------------------------------------------------

local function evaluate_node_properties (itemstack, user, pointed_thing)
	if not (user and user:is_player ()) then
		return
	end
	local playername = user:get_player_name ()
	if pointed_thing.type == "node" then
		local node = core.get_node (pointed_thing.under)
		core.chat_send_player (playername, table.concat ({
			"Node: ", node.name, "\n",
			"Up face sturdy: ",
			tostring (mcl_mobs.is_up_face_sturdy (pointed_thing.under, node)),
		}))

		local spawn_pos = vector.offset (pointed_thing.under, 0, 0.5, 0)
		local zombie_spawner = table.merge (default_spawner, {
			name = "mobs_mc:zombie",
		})
		core.chat_send_player (playername, table.concat ({
			"Zombie clearance tests pass? ",
			tostring (zombie_spawner:test_spawn_clearance (spawn_pos, {})),
			"\n",
		}))
	end
end

core.register_tool ("mcl_mobs:spawn_stick", {
	description = "Evaluate node properties",
	inventory_image = "default_stick.png^[colorize:purple:50",
	groups = { testtool = 1, disable_repair = 1,
		   not_in_creative_inventory = 1, },
	on_use = evaluate_node_properties,
})

core.register_chatcommand ("spawn_cycle", {
	privs = { server = true, },
	params = "[ end | overworld | nether ]",
	func = function (n, param)
		mcl_mobs.spawn_cycle (param)
		mcl_mobs.spawn_cycle (param, true)
	end,
})
