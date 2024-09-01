local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node("mcl_powder_snow:powder_snow", {
	description = S("Powder Snow"),
	_doc_items_longdesc = S("This is a block of snow thats extra fluffy, this means players can sink in it"),
	_doc_items_hidden = false,
	tiles = {"powder_snow.png"},
	groups = {shovely=2, deco_block=1, snow_cover=1, pathfind = 1},
	sounds = mcl_sounds.node_sound_snow_defaults(),
	-- drawtype = "glasslike",
	-- sunlight_propagates = true,
	post_effect_color = "#CFD7DBFF",
	walkable = false,
	-- damage_per_second = 2,
	move_resistance = 3,
	is_ground_content = false, -- set to false to potentially create huge drops into caves >:)
	on_construct = mcl_core.on_snow_construct,
	after_destruct = mcl_core.after_snow_destruct,
	on_rightclick = function(pos, _, clicker, itemstack, pointed_thing)
		if itemstack:get_name() ==  "mcl_buckets:bucket_empty" then
			minetest.set_node(pos, {name = "air"})
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				if itemstack:get_count() == 1 then
					itemstack = ItemStack("mcl_powder_snow:bucket_powder_snow")
				else
					local inv = clicker:get_inventory()
					if inv:room_for_item("main", "mcl_powder_snow:bucket_powder_snow") then
						inv:add_item("main", "mcl_powder_snow:bucket_powder_snow")
					else
						minetest.add_item(clicker:get_pos(), "mcl_powder_snow:bucket_powder_snow")
					end
					itemstack:take_item()
				end
			end
		elseif itemstack:get_definition().type == "node" then
			minetest.item_place_node(itemstack, clicker, pointed_thing)
		end

		return itemstack
	end,
	_mcl_blast_resistance = 0.1,
	_mcl_hardness = 0.1,
	_mcl_silk_touch_drop = false,
})

mcl_buckets.register_liquid({
	source_take = {"mcl_powder_snow:powder_snow"},
	source_place = "mcl_powder_snow:powder_snow",
	bucketname = "mcl_powder_snow:bucket_powder_snow",
	inventory_image = "bucket_powder_snow.png",
	name = S("Powder snow"),
	longdesc = S("This bucket is filled powder snow"),
	usagehelp = S("Place it to empty the bucket and place powder snow. Obtain by right clicking on a block of powder snow with an empty bucket."),
	tt_help = S("Places a powder snow block"),
})

local freezing_stages = 
{
	"freezing_1.png",
	"freezing_2.png",
	"freezing_3.png",
}

local function show_freezing_hud(player, level)

	-- alignment and offset dosent work for some reason
	-- player:hud_add(
	-- {
	-- 	type = "image",
	-- 	position = {x = 0.5, y = 0.5},
	-- 	scale = {x = 2, y = 2},
	-- 	text = freezing_stages[level],
	-- 	z_index = 4,
	-- })
end

-- key value pair
-- key: name of player
-- value: number of seconds the player spent in powder snow
local freezing_players = {}

mcl_player.register_globalstep_slow(function(player, dtime)
	local name = player:get_player_name()
	if minetest.get_node(player:get_pos()).name == "mcl_powder_snow:powder_snow" then
		freezing_players[name] = (freezing_players[name] or 0) + 0.5

		if freezing_players[name] > 5 then
			show_freezing_hud(player, 3)
		elseif freezing_players[name] > 3 then
			show_freezing_hud(player, 2)
		elseif freezing_players[name] > 1 then
			show_freezing_hud(player, 1)
		end
		
		if freezing_players[name] > 5 then
			mcl_damage.damage_player(player, 0.5, {type = "in_wall"})
		end
	elseif freezing_players[player:get_player_name()] then
		freezing_players[name] = freezing_players[name] - 0.5

		if freezing_players[name] <= 0 then
			freezing_players[name] = nil
		end
	end
end)
