local S = core.get_translator(core.get_current_modname())
local max_honey_level = 5

-- Function to allow harvesting honey and honeycomb from the beehive and bee nest.
local honey_harvest = function(pos, node, player, itemstack)
	local player_name = player:get_player_name()
	local shears = core.get_item_group(itemstack:get_name(), "shears") > 0
	local bottle = itemstack:get_name() == "mcl_potions:glass_bottle"
	local original_block = "mcl_beehives:bee_nest"
	local is_creative = core.is_creative_enabled(player_name)
	local campfire_area = vector.offset(pos, 0, -5, 0)
	local campfire = core.find_nodes_in_area(pos, campfire_area, "group:lit_campfire")

	if node.name == "mcl_beehives:beehive_5" then
		original_block = "mcl_beehives:beehive"
	end

	if bottle or shears then
		if core.is_protected(pos, player_name) then
			core.record_protection_violation(pos, player_name)
			return itemstack
		end

		if bottle then
			local honey = "mcl_honey:honey_bottle"
			local inv = player:get_inventory()

			if inv:room_for_item("main", honey) then
				inv:add_item("main", honey)

				if not is_creative then itemstack:take_item() end

				if campfire[1] then
					awards.unlock(player:get_player_name(), "mcl:bee_our_guest")
				end
			end
		else --Must be shears
			core.add_item(pos, "mcl_honey:honeycomb 3")
			itemstack:add_wear_by_uses(238)
		end
		--TODO: damage type = "mob" since this is supposed to be done by bee mobs which aren't a thing yet
		--Once bees exist this branch should spawn them and/or make them aggro
		if not campfire[1] then
			mcl_util.deal_damage(player, 10, {type = "mob"})
		end

		node.name = original_block
		core.swap_node(pos, node)
	end

	return itemstack
end

-- Dig Function for Beehives
local dig_hive = function(pos, node, _, digger)
	local wield_item = digger:get_wielded_item()
	local beehive = string.find(node.name, "mcl_beehives:beehive")
	local beenest = string.find(node.name, "mcl_beehives:bee_nest")
	local silk_touch = mcl_enchanting.has_enchantment(wield_item, "silk_touch")
	local is_creative = minetest.is_creative_enabled(digger:get_player_name())
	local inv = digger:get_inventory()

	if beehive then
		if not is_creative then
			minetest.add_item(pos, "mcl_beehives:beehive")
			if not silk_touch then mcl_util.deal_damage(digger, 10, {type = "mob"}) end
		elseif is_creative and inv:room_for_item("main", "mcl_beehives:beehive") and not inv:contains_item("main", "mcl_beehives:beehive") then
			inv:add_item("main", "mcl_beehives:beehive")
		end
	elseif beenest then
		if not is_creative then
			if silk_touch and wield_item:get_name() ~= "mcl_enchanting:book_enchanted" then
				minetest.add_item(pos, "mcl_beehives:bee_nest")
				awards.unlock(digger:get_player_name(), "mcl:total_beelocation")
			else
				mcl_util.deal_damage(digger, 10, {type = "mob"})
			end
		elseif is_creative and inv:room_for_item("main", "mcl_beehives:bee_nest") and not inv:contains_item("main", "mcl_beehives:bee_nest") then
			inv:add_item("main", "mcl_beehives:bee_nest")
		end
	end
end

local function full_tiles(base_tiles)
	base_tiles[6] = base_tiles[6]:gsub(".png", "_honey.png")
end

local function register_hives(id, defs, merges)
	for i = 0, max_honey_level do
		local empty, full = i == 0, i == max_honey_level
		local subname = id .. (empty and "" or "_" .. i)

		core.register_node("mcl_beehives:" .. subname, table.merge(merges, {
			_mcl_baseitem = not empty and "mcl_beehives:" .. id,
			_mcl_burntime = empty and defs.burntime or nil,
			after_dig_node = dig_hive,
			description = defs.description,
			drop = "",
			groups = table.merge(defs.groups or {}, {
				axey = 1, deco_block = empty and 1 or nil, honey_level = i,
				not_in_creative_inventory = not empty and 1 or nil, unmovable_by_piston = 1
			}),
			on_rightclick = full and honey_harvest or nil,
			paramtype2 = "4dir",
			sounds = mcl_sounds.node_sound_wood_defaults(),
			stack_max = empty and 64 or 1,
			tiles = not full and defs.base_tiles or full_tiles(defs.base_tiles)
		}))
	end
end

register_hives("beehive", {
	base_tiles = {
		"mcl_beehives_beehive_end.png", "mcl_beehives_beehive_end.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_side.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_front.png",
	},
	burntime = 15,
	description = S("Beehive"),
	groups = {
		beehive = 1, fire_encouragement = 5, fire_flammability = 20, flammable = 1, material_wood = 1
	}
}, {
	_mcl_blast_resistance = 0.6,
	_mcl_hardness = 0.6
})

register_hives("bee_nest", {
	base_tiles = {
		"mcl_beehives_bee_nest_top.png", "mcl_beehives_bee_nest_bottom.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_side.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_front.png",
	},
	burntime = 15,
	description = S("Bee Nest"),
	groups = {
		bee_nest = 1, fire_encouragement = 30, fire_flammability = 20, flammable = 1
	}
}, {
	_mcl_blast_resistance = 0.3,
	_mcl_hardness = 0.3
})

-- Crafting
minetest.register_craft({
	output = "mcl_beehives:beehive",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"mcl_honey:honeycomb", "mcl_honey:honeycomb", "mcl_honey:honeycomb"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

-- Temporary ABM to update honey levels
minetest.register_abm({
	action = function(pos, node)
		local node_name = node.name
		local honey_level = core.get_item_group(node_name, "honey_level")

		if honey_level == max_honey_level then return end

		local flowers = core.find_node_near(pos, 5, "group:flower")
		local tod = core.get_timeofday() * 24000
		local original_block = "mcl_beehives:bee_nest"

		if core.get_item_group(node_name, "beehive") == 1 then
			original_block = "mcl_beehives:beehive"
		end

		if tod > 6000 and tod < 18000 and flowers and mcl_weather.get_weather() ~= "rain" then
			honey_level = math.min(honey_level + 1, max_honey_level)
			node.name = original_block .. "_" .. honey_level
			core.swap_node(pos, node)
		end
	end,
	chance = 100,
	interval = 75,
	label = "Update Beehive or Beenest Honey Levels",
	nodenames = {"group:honey_level"}
})
