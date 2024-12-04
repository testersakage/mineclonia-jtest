local S = minetest.get_translator(minetest.get_current_modname())

mcl_compass = {}

local compass_types = {
	compass = {
		name = "compass",
		img_fmt = "mcl_compass_compass_%02d.png",
		name_fmt = "mcl_compass:%d",
		desc = S("Compass"),
		tt = S("Points to the world origin"),
		longdesc = S("Compasses are tools which point to the world origin (X=0, Z=0) or the spawn point in the Overworld."),
		usagehelp = S("A Compass always points to the world spawn point when the player is in the overworld.  In other dimensions, it spins randomly."),
	},
	lodestone = {
		name = "compass_lodestone",
		img_fmt = "mcl_compass_compass_%02d.png^[colorize:purple:50",
		name_fmt = "mcl_compass:%d_lodestone",
		desc = S("Lodestone Compass"),
		tt = S("Points to a lodestone"),
		longdesc = S("Lodestone compasses resemble regular compasses, but they point to a specific lodestone."),
		usagehelp = S("A Lodestone compass can be made from an ordinary compass by using it on a lodestone.  After becoming a lodestone compass, it always points to its linked lodestone, provided that they are in the same dimension.  If not in the same dimension, the lodestone compass spins randomly, similarly to a regular compass when outside the overworld.  A lodestone compass can be relinked with another lodestone."),
	},
	recovery = {
		name = "compass_recovery",
		img_fmt = "mcl_compass_recovery_compass_%02d.png",
		name_fmt = "mcl_compass:%d_recovery",
		desc = S("Recovery Compass"),
		tt = S("Points to your last death location"),
		longdesc = S("Recovery Compasses are compasses that point to your last death location"),
		usagehelp = S("Recovery Compasses always point to the location of your last death, in case you haven't died yet, it will just randomly spin around"),
	}
}
-- Number of dynamic compass images (and items registered.)
local compass_frames = 32

-- The image/item that is craftable and shown in inventories.
local stereotype_frame = 18

-- random compass spinning tick in seconds.
-- Increase if there are performance problems.
local spin_timer_tick = 0.5

-- Initialize random compass frame for spinning compass.  It is updated in
-- the compass globalstep function.
local random_frame = math.random(0, compass_frames-1)

local function get_far_node(pos, itemstack) --code from minetest dev wiki: https://dev.minetest.net/minetest.get_node, some edits have been made to add a cooldown for force loads
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		local tstamp = tonumber(itemstack:get_meta():get_string("last_forceload"))
		if tstamp == nil then --this is only relevant for new lodestone compasses, the ones that have never performes a forceload yet
			itemstack:get_meta():set_string("last_forceload", tostring(os.time(os.date("!*t")))) ---@diagnostic disable-line: param-type-mismatch
			tstamp = tonumber(os.time(os.date("!*t"))) ---@diagnostic disable-line: param-type-mismatch
		end
		if tonumber(os.time(os.date("!*t"))) - tstamp > 180 then ---@diagnostic disable-line: param-type-mismatch
			itemstack:get_meta():set_string("last_forceload", tostring(os.time(os.date("!*t")))) ---@diagnostic disable-line: param-type-mismatch
			minetest.get_voxel_manip():read_from_map(pos, pos)
			node = minetest.get_node(pos)
		else
			node = {name="mcl_compass:lodestone"} --cooldown not over yet, pretend like there is something...
		end
	end
	return node
end

--- Get compass needle angle.
-- Returns the angle that the compass needle should point at expressed in
-- 360 degrees divided by the number of possible compass image frames..
--
-- pos: position of the compass;
-- target: position that the needle points towards;
-- dir: rotational direction of the compass.
--
local function get_compass_angle(pos, target, dir)
	local angle_north = math.deg(math.atan2(target.x - pos.x, target.z - pos.z))
	if angle_north < 0 then angle_north = angle_north + 360 end
	local angle_dir = -math.deg(dir)
	local angle_relative = (angle_north - angle_dir + 180) % 360
	return math.floor((angle_relative/11.25) + 0.5) % compass_frames
end

--- Get compass image frame.
-- Returns the compass image frame with the needle direction matching the
-- compass' current position.
--
-- pos: position of the compass;
-- dir: rotational direction of the compass.
-- itemstack: the compass including its optional lodestone metadata.
--
local function get_compass_frame(pos, dir, itemstack)
	if not string.find(itemstack:get_name(), "_lodestone") then -- normal compass
		-- Compasses only work in the overworld
		if mcl_worlds.compass_works(pos) then
			local spawn_pos = minetest.setting_get_pos("static_spawnpoint")
				or vector.new(0, 0, 0)
			return get_compass_angle(pos, spawn_pos, dir)
		else
			return random_frame
		end
	else -- lodestone compass
		local lpos_str = itemstack:get_meta():get_string("pointsto")
		local lpos = minetest.string_to_pos(lpos_str)
		if not lpos then
			minetest.log("warning", "mcl_compass: invalid lodestone position!")
			return random_frame
		end
		local _, l_dim = mcl_worlds.y_to_layer(lpos.y)
		local _, p_dim = mcl_worlds.y_to_layer(pos.y)
		-- compass and lodestone must be in the same dimension
		if l_dim == p_dim then
			--check if lodestone still exists
			if get_far_node(lpos, itemstack).name == "mcl_compass:lodestone" then
				return get_compass_angle(pos, lpos, dir)
			else -- lodestone got destroyed
				return random_frame
			end
		else
			return random_frame
		end
	end
end

-- Export stereotype item for other mods to use

--- Get partial compass itemname.
-- Returns partial itemname of a compass with needle direction matching compass position.
-- Legacy compatibility function for mods using older api.
--
function mcl_compass.get_compass_image(pos, dir)
	minetest.log("warning", "mcl_compass: deprecated function " ..
		"get_compass_image() called, use get_compass_itemname().")
	local itemstack = ItemStack(mcl_compass.stereotype)
	return get_compass_frame(pos, dir, itemstack)
end

--compat: compasses used to consist of many different items
function mcl_compass.get_compass_itemname() return "mcl_compass:compass" end
mcl_compass.stereotype = "mcl_compass:compass"

-- Timer for randomly spinning compass.
-- Gets updated and checked in the globalstep function.
local spin_timer = 0

-- Compass globalstep function.
-- * updates random spin counter and random frame of spinning compasses;
-- * updates all compasses in player's inventories to match the correct
--   needle orientations for their current positions.
--
minetest.register_globalstep(function(dtime)
	spin_timer = spin_timer + dtime
	if spin_timer >= spin_timer_tick then
		random_frame = (random_frame + math.random(-1, 1)) % compass_frames
		spin_timer = 0
	end

	local compass_nr, compass_frame
	local pos, dir, inv
	for player in mcl_util.connected_players() do
		pos = player:get_pos()
		dir = player:get_look_horizontal()
		inv = player:get_inventory()
		for j, stack in pairs(inv:get_list("main")) do
			local m = stack:get_meta()
			compass_nr = minetest.get_item_group(stack:get_name(), "compass")
			if compass_nr ~= 0 and not string.find(stack:get_name(), "_recovery") then
				-- check if current compass image still matches true orientation
				compass_frame = get_compass_frame(pos, dir, stack)
				if compass_nr - 1 ~= compass_frame then
					if string.find(stack:get_name(), "_lodestone") then
						local img = string.format(compass_types.lodestone.img_fmt, compass_frame)
						m:set_string("inventory_image", img)
						m:set_string("wield_image", img)
						awards.unlock(player:get_player_name(), "mcl:countryLode")
					else
						local img = string.format(compass_types.compass.img_fmt, compass_frame)
						m:set_string("inventory_image", img)
						m:set_string("wield_image", img)
					end
					inv:set_stack("main", j, stack)
				end
			elseif compass_nr ~= 0 then
				local meta = player:get_meta()
				local posstring =  meta:get_string("mcl_compass:recovery_pos")
				local targetpos = minetest.string_to_pos(posstring)
				local _, target_dim = mcl_worlds.y_to_layer(targetpos.y)
				local _, p_dim = mcl_worlds.y_to_layer(pos.y)
				if p_dim ~= target_dim then
					local img = string.format(compass_types.recovery.img_fmt, random_frame)
					m:set_string("inventory_image", img)
					m:set_string("wield_image", img)
				else
					local img = string.format(compass_types.recovery.img_fmt, get_compass_angle(pos, targetpos, dir))
					m:set_string("inventory_image", img)
					m:set_string("wield_image", img)
				end
				inv:set_stack("main",j,stack)
			end
		end
	end
end)

--
-- Node and craftitem definitions
--

for _, item in pairs(compass_types) do
	core.register_craftitem("mcl_compass:"..item.name, {
		description = item.desc,
		_doc_items_longdesc = item.longdesc,
		_doc_items_usagehelp = item.usagehelp,
		_tt_help = item.tt,
		inventory_image = string.format(item.img_fmt, stereotype_frame),
		wield_image = string.format(item.img_fmt, stereotype_frame),
		groups = {compass = 1 + 1, tool = 1, disable_repair = 1},
		_on_set_item_entity = function(itemstack, entity)
			--entity.is_compass = true
			return itemstack
		end
	})
	for i = 0, compass_frames - 1 do
		core.register_alias(string.format(item.name_fmt, i), "mcl_compass"..item.name)
	end
end

minetest.register_craft({
	output = "mcl_compass:" .. stereotype_frame,
	recipe = {
		{"", "mcl_core:iron_ingot", ""},
		{"mcl_core:iron_ingot", "mcl_redstone:redstone", "mcl_core:iron_ingot"},
		{"", "mcl_core:iron_ingot", ""}
	}
})

minetest.register_craft({ --TODO: update once echo shards are a thing
	output = "mcl_compass:" .. random_frame .. "_recovery",
	recipe = {
		{"","mcl_nether:netherite_ingot",""},
		{"mcl_core:diamondblock","mcl_compass:" .. stereotype_frame ,"mcl_core:diamondblock"},
		{"mcl_core:diamondblock","mcl_core:diamondblock","mcl_core:diamondblock"}

	}
})

minetest.register_node("mcl_compass:lodestone",{
	description=S("Lodestone"),
	on_rightclick = function(pos, _, player, itemstack)
		local name = itemstack.get_name(itemstack)
		if string.find(name,"mcl_compass:") then
			if name ~= "mcl_compass:lodestone" then
				itemstack:get_meta():set_string("pointsto", minetest.pos_to_string(pos))
				local dir = player:get_look_horizontal()
				local frame = get_compass_frame(pos, dir, itemstack)
				itemstack:set_name("mcl_compass:" .. frame .. "_lodestone")
			end
		end

		return itemstack
	end,
	tiles = {
		"lodestone_top.png",
		"lodestone_bottom.png",
		"lodestone_side1.png",
		"lodestone_side2.png",
		"lodestone_side3.png",
		"lodestone_side4.png"
	},
	groups = {pickaxey=1, material_stone=1, deco_block=1, unmovable_by_piston = 1},
	_mcl_hardness = 1.5,
	_mcl_blast_resistance = 6,
	sounds = mcl_sounds.node_sound_stone_defaults()
})

minetest.register_craft({
	output = "mcl_compass:lodestone",
	recipe = {
		{"mcl_core:stonebrickcarved","mcl_core:stonebrickcarved","mcl_core:stonebrickcarved"},
		{"mcl_core:stonebrickcarved", "mcl_nether:netherite_ingot", "mcl_core:stonebrickcarved"},
		{"mcl_core:stonebrickcarved", "mcl_core:stonebrickcarved", "mcl_core:stonebrickcarved"}
	}
})

--set recovery meta
minetest.register_on_dieplayer(function(player)
	local meta = player:get_meta();
	meta:set_string("mcl_compass:recovery_pos",minetest.pos_to_string(player:get_pos()))
end)
