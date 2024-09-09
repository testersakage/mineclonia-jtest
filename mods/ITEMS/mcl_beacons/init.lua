local S = minetest.get_translator(minetest.get_current_modname())
local C = minetest.colorize
local F = minetest.formspec_escape

mcl_beacons = {}
local function get_beacon_beam(glass_nodename)
	if glass_nodename == "air" then return 0 end
	local def = minetest.registered_nodes[glass_nodename]
	if def and def._color then
		return mcl_dyes.colors[def._color].palette_index
	end
end

local function set_node_if_clear(pos,node)
	local tn = minetest.get_node(pos)
	local def = minetest.registered_nodes[tn.name]
	if tn.name == "air" or (def and def.buildable_to) then
		minetest.set_node(pos,node)
	end
end

local function remove_beacon_beam(pos)
	for y=pos.y, pos.y+301 do
		local node = minetest.get_node({x=pos.x,y=y,z=pos.z})
		if node.name ~= "air" and node.name ~= "mcl_core:bedrock" and node.name ~= "mcl_core:void" then
			if node.name == "ignore" then
				minetest.get_voxel_manip():read_from_map({x=pos.x,y=y,z=pos.z}, {x=pos.x,y=y,z=pos.z})
				node = minetest.get_node({x=pos.x,y=y,z=pos.z})
			end

			if node.name == "mcl_beacons:beacon_beam" then
				minetest.remove_node({x=pos.x,y=y,z=pos.z})
			end
		end
	end
end

local function beacon_blockcheck(pos)
	for y_offset = 1,4 do
		local block_y = pos.y - y_offset
		for block_x = (pos.x-y_offset),(pos.x+y_offset) do
			for block_z = (pos.z-y_offset),(pos.z+y_offset) do
				local valid_block = false --boolean which stores if block is valid or not
				if minetest.get_item_group(minetest.get_node(vector.new(block_x, block_y, block_z)).name, "beacon_block") > 0 then
					valid_block =true
				end
				if not valid_block then
					return y_offset -1 --the last layer is complete, this one is missing or incomplete
				end
			end
		end
		if y_offset == 4 then --all checks are done, beacon is maxed
			return y_offset
		end
	end
end

local function clear_obstructed_beam(pos)
	for y=pos.y+1, pos.y+100 do
		local nodename = minetest.get_node({x=pos.x,y=y, z = pos.z}).name
		if nodename ~= "mcl_core:bedrock" and nodename ~= "air" and nodename ~= "mcl_core:void" and nodename ~= "ignore" then --ignore means not loaded, let's just assume that's air
			if nodename ~="mcl_beacons:beacon_beam" then
				if minetest.get_item_group(nodename,"glass") == 0 and minetest.get_item_group(nodename,"material_glass") == 0  then
					remove_beacon_beam(pos)
					return true
				end
			end
		end
	end

	return false
end

local function effect_player(effect, pos, power_level, effect_level,player)
	local distance =  vector.distance(player:get_pos(), pos)
	if distance > (power_level+1)*10 then return end
	mcl_potions.give_effect_by_level (effect, player, effect_level, 16)
end

local function apply_effects_to_all_players(pos)
	local meta = minetest.get_meta(pos)
	local effect_string = meta:get_string("effect")
	local effect_level = meta:get_int("effect_level")
	local secondary = meta:get_string ("secondary_effect")

	local power_level = beacon_blockcheck(pos)

	if effect_level == 2 and power_level < 4 then --no need to run loops when beacon is in an invalid setup :P
		return
	end

	local beacon_distance = (power_level + 1) * 10

	for player in mcl_util.connected_players(pos, beacon_distance) do
		if vector.distance(pos, player:get_pos()) <= beacon_distance then
			if not clear_obstructed_beam (pos) then
				if effect_string and effect_string ~= "" then
					effect_player (effect_string, pos, power_level, effect_level, player)
				end
				if secondary and secondary ~= "" and power_level == 4 then
					effect_player (secondary, pos, power_level, 1, player)
				end
			end
		end
	end
end

local function allow_metadata_inventory_take(pos, _, _, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	return allow_metadata_inventory_take(pos, listname, index, stack, player)
end

local function allow_metadata_inventory_move()
	return 0
end

local function upgrade_effect_level_button (oldmeta)
	local effect = oldmeta:get_string ("effect")
	if effect and effect ~= "" then
		local pdef = mcl_potions.registered_effects[effect] or { }
		local tooltip = (pdef.description or "???") .. " II"
		return ("image_button[8.5,3.5;1,1;"
			.. (pdef.icon or "unknown.png")
			.. ";upgrade_ii;]"
			.. "tooltip[8.5,3.5;1,1;" .. tooltip .. "]")
	else
		return ""
	end
end

local function generate_beacon_formspec (meta)
	return "formspec_version[4]"..
	"size[11.75,14.425]"..
	"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, S("Beacon"))) .. "]"..
	"label[0.5,1;"..minetest.formspec_escape(S("Primary Power:")).."]"..
	"label[5.5,1;"..minetest.formspec_escape(S("Secondary Power:")).."]"..
	"image[1,1.5;1,1;custom_beacon_symbol_4.png]"..
	"image[1,3;1,1;custom_beacon_symbol_3.png]"..
	"image[1,4.5;1,1;custom_beacon_symbol_2.png]"..
	"image[6,3.5;1,1;custom_beacon_symbol_1.png]"..
	"image_button[2.5,1.5;1,1;mcl_potions_effect_swift.png;swiftness;]"..
	"image_button[3.5,1.5;1,1;mcl_potions_effect_haste.png;haste;]"..
	"image_button[2.5,3;1,1;mcl_potions_effect_resistance.png;resistance;]"..
	"image_button[3.5,3;1,1;mcl_potions_effect_leaping.png;leaping;]"..
	"image_button[3.0,4.5;1,1;mcl_potions_effect_strong.png;strength;]"..
	"image_button[7.5,3.5;1,1;mcl_potions_effect_regenerating.png;regeneration;]"..
	"tooltip[swiftness;"..S("Swiftness").."]"..
	"tooltip[haste;"..S("Haste").."]"..
	"tooltip[resistance;"..S("Resistance").."]"..
	"tooltip[leaping;"..S("Leaping").."]"..
	"tooltip[strength;"..S("Strength").."]"..
	"tooltip[regeneration;"..S("Regeneration").."]"..
	upgrade_effect_level_button (meta)..
	"item_image[1,7;1,1;mcl_core:diamond]"..
	"item_image[2.2,7;1,1;mcl_core:emerald]"..
	"item_image[3.4,7;1,1;mcl_core:iron_ingot]"..
	"item_image[4.6,7;1,1;mcl_core:gold_ingot]"..
	"item_image[5.8,7;1,1;mcl_nether:netherite_ingot]"..
	mcl_formspec.get_itemslot_bg_v4(7.2,7,1,1)..
	"list[context;input;7.2,7;1,1;]"..

	"label[0.375,8.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]"..
	mcl_formspec.get_itemslot_bg_v4(0.375, 9.1, 9, 3)..
	"list[current_player;main;0.375,9.1;9,3;9]"..

	mcl_formspec.get_itemslot_bg_v4(0.375, 13.05, 9, 1)..
	"list[current_player;main;0.375,13.05;9,1;]"..

	"listring[context;input]"..
	"listring[current_player;main]"
end

local function add_group(item, group)
	local def = minetest.regisered_items[item]
	if def then
		minetest.override_item(item, {
			groups = table.merge(def.groups or {}, { [group] = 1 })
		})
	end
end

function mcl_beacons.register_beaconblock (itemstring)
	minetest.log("warning", "[mcl_beacons] mcl_beacons.register_beaconblock is deprecated. Use the \"beacon_block\" item group instead!")
	add_group(itemstring, "beacon_block")
end

function mcl_beacons.register_beaconfuel(itemstring)
	minetest.log("warning", "[mcl_beacons] mcl_beacons.register_beaconfuel is deprecated. Use the \"beacon_fuel\" item group instead!")
	add_group(itemstring, "beacon_fuel")
end

local function apply_beacon_formspec (pos, _, fields, sender)
	local sender_name = sender:get_player_name ()
	-- Return if the node is no longer a beacon.
	if not pos or minetest.get_node (pos).name ~= "mcl_beacons:beacon" then
		return
	end

	if minetest.is_protected (pos, sender_name) then
		minetest.record_protection_violation (pos, sender_name)
		return
	end

	if (fields.swiftness or fields.regeneration or fields.leaping
	or fields.strength or fields.upgrade_ii or fields.resistance
	or fields.haste) then
		local power_level = beacon_blockcheck (pos)

		if minetest.is_protected (pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		elseif power_level == 0 then
			return
		end

		local meta = minetest.get_meta (pos)
		local inv = meta:get_inventory ()
		local input = inv:get_stack ("input", 1)

		if input:is_empty() then
			return
		end

		local valid_item = false

		if minetest.get_item_group(input:get_name(), "beacon_fuel") > 0 then
			valid_item = true
		end

		if not valid_item then
			return
		end

		local successful = false

		if fields.swiftness then
			meta:set_string ("effect", "swiftness")
			if minetest.get_meta (pos):get_int ("effect_level") < 1 then
				meta:set_int ("effect_level", 1)
			end
			successful = true
		elseif fields.haste then
			meta:set_string ("effect", "haste")
			if minetest.get_meta (pos):get_int ("effect_level") < 1 then
				meta:set_int ("effect_level", 1)
			end
			successful = true
		elseif fields.leaping and power_level >= 2 then
			meta:set_string ("effect", "leaping")
			if minetest.get_meta (pos):get_int ("effect_level") < 1 then
				meta:set_int ("effect_level", 1)
			end
			successful = true
		elseif fields.resistance and power_level >= 2 then
			meta:set_string ("effect", "resistance")
			if minetest.get_meta (pos):get_int ("effect_level") < 1 then
				meta:set_int ("effect_level", 1)
			end
			successful = true
		elseif fields.strength and power_level >= 3 then
			meta:set_string ("effect","strength")
			if minetest.get_meta (pos):get_int ("effect_level") < 1 then
				meta:set_int ("effect_level", 1)
			end
			successful = true
		elseif fields.regeneration and power_level == 4 then
			-- If a secondary effect is enabled, the effect level must
			-- be reset to 1.
			meta:set_int ("effect_level", 1)
			meta:set_string ("secondary_effect", "regeneration")
			successful = true
		elseif fields.upgrade_ii and power_level == 4 then
			-- Upgrade the primary effect to II but cancel the
			-- secondary one.  Also verify that there is an effect to
			-- upgrade.
			if minetest.get_meta (pos):get_string ("effect")
			and minetest.get_meta (pos):get_int ("effect_level") < 2 then
			minetest.get_meta (pos):set_int ("effect_level", 2)
			minetest.get_meta (pos):set_string ("secondary_effect", "")
				successful = true
			end
		end
		if successful then
			if power_level == 4 then
				awards.unlock(sender_name, "mcl:maxed_beacon")
			end
			awards.unlock(sender_name, "mcl:beacon")
			input:take_item ()
			inv:set_stack("input",1,input)

			local beam_palette_index = 0
			remove_beacon_beam(pos)
			for y = pos.y +1, pos.y + 201 do
				local node = minetest.get_node({x=pos.x,y=y,z=pos.z})
				if node.name == "ignore" then
					minetest.get_voxel_manip():read_from_map({x=pos.x,y=y,z=pos.z}, {x=pos.x,y=y,z=pos.z})
					node = minetest.get_node({x=pos.x,y=y,z=pos.z})
				end

				if minetest.get_item_group(node.name, "glass") ~= 0 or minetest.get_item_group(node.name,"material_glass") ~= 0 then
					beam_palette_index = get_beacon_beam(node.name)
				end

				if node.name == "air" then
					minetest.set_node({x=pos.x,y=y,z=pos.z},{name="mcl_beacons:beacon_beam",param2=beam_palette_index})
				end
			end
			apply_effects_to_all_players(pos) --call it once outside the globalstep so the player gets the effect right after selecting it
			-- Redisplay the formspec.
			meta:set_string("formspec", generate_beacon_formspec(meta))
		end
	end
end

minetest.register_node("mcl_beacons:beacon", {
	description = S("Beacon"),
	drawtype = "mesh",
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	mesh = "mcl_beacon.b3d",
	tiles = {"beacon_UV.png"},
	is_ground_content = false,
	use_texture_alpha = "clip",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
		meta:set_string("formspec", generate_beacon_formspec(meta))
	end,
	after_dig_node = mcl_util.drop_items_from_meta_container({"input"}),
	on_destruct = remove_beacon_beam,
	on_receive_fields = apply_beacon_formspec,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	light_source = 14,
	groups = {handy=1, deco_block=1},
	drop = "mcl_beacons:beacon",
	sounds = mcl_sounds.node_sound_glass_defaults(),
	_mcl_hardness = 3,
})

minetest.register_node("mcl_beacons:beacon_beam", {
	tiles = {"blank.png^[noalpha^[colorize:#b8bab9"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1250, -0.5000, -0.1250, 0.1250, 0.5000, 0.1250}
		}
	},
	pointable= false,
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	groups = {not_in_creative_inventory=1},
	_mcl_blast_resistance = 1200,
	paramtype2 = "color",
	palette = "mcl_dyes_palette.png",
	buildable_to = true,
})

minetest.register_craft({
	output = "mcl_beacons:beacon",
	recipe = {
		{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
		{"mcl_core:glass", "mcl_mobitems:nether_star", "mcl_core:glass"},
		{"mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian"}
	}
})

minetest.register_abm{
	label="update beacon beam",
	nodenames = {"mcl_beacons:beacon_beam"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local node_below = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		local node_above = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
		local node_current = minetest.get_node(pos)

		local beacon = minetest.find_nodes_in_area({x=pos.x,y=pos.y-100,z=pos.z},{x=pos.x,y=pos.y+100,z=pos.z},{"mcl_beacons:beacon"})
		if #beacon > 0 then
			local air_above = minetest.find_nodes_in_area({x=beacon[1].x, y=beacon[1].y, z=beacon[1].z}, {x=beacon[1].x, y=beacon[1].y+100, z=beacon[1].z}, {"air"})
			if #air_above > 0 then
				minetest.set_node({x=air_above[1].x, y=air_above[1].y, z=air_above[1].z}, {name="mcl_beacons:beacon_beam",param2=0})
			end
		end

		if node_below.name ~= "mcl_beacons:beacon" and minetest.get_item_group(node_below.name,"material_glass") == 0 and node_below.name ~= "mcl_beacons:beacon_beam" then
			if minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "mcl_beacons:beacon" then
				set_node_if_clear({x=pos.x,y=pos.y-1,z=pos.z},{name="mcl_beacons:beacon_beam",param2=0})
			end
		elseif node_above.name == "air" or (node_above.name == "mcl_beacons:beacon_beam" and node_above.param2 ~= node_current.param2) then
			set_node_if_clear({x=pos.x,y=pos.y+1,z=pos.z},{name="mcl_beacons:beacon_beam",param2=node_current.param2})
		elseif minetest.get_item_group(node_below.name, "glass") ~= 0 or minetest.get_item_group(node_below.name,"material_glass") ~= 0 then
			set_node_if_clear({x=pos.x,y=pos.y,z=pos.z},{name="mcl_beacons:beacon_beam",param2=get_beacon_beam(node_below.name)})
		elseif minetest.get_item_group(node_above.name, "glass") ~= 0 or minetest.get_item_group(node_above.name,"material_glass") ~= 0 then
			set_node_if_clear({x=pos.x,y=pos.y+1,z=pos.z},{name="mcl_beacons:beacon_beam",param2=get_beacon_beam(node_above.name)})
		end
	end,
}

minetest.register_abm{
	label="apply beacon effects to players",
	nodenames = {"mcl_beacons:beacon"},
	interval = 3,
	chance = 1,
	action = function(pos)
		apply_effects_to_all_players(pos)
	end,
}

minetest.register_lbm({
	label = "Upgrade pre 106.1 beacons data",
	name = "mcl_beacons:upgrade_beacon_data",
	nodenames = {"mcl_beacons:beacon"},
	run_at_every_load = false,
	action = function(pos)
		local m = minetest.get_meta(pos)
		m:set_string("formspec", generate_beacon_formspec(m))

		if m:get_string ("effect") == "regeneration" then
			m:set_string ("effect", "")
			m:set_string ("secondary_effect", "regeneration")
			m:set_string ("effect_level", 1)
		elseif m:get_string ("effect") == "strenght" then
			m:set_string ("effect", "strength")
		end
	end,
})
