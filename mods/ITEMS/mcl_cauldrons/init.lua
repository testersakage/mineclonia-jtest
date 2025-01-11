mcl_cauldrons = {}
mcl_cauldrons.liquids = {
	lava = {
		bucket = "mcl_buckets:bucket_lava",
		node = "mcl_core:lava_source"
	},
	water = {
		bucket = "mcl_buckets:bucket_water",
		node = "mcl_core:water_source"
	}
}

local S = core.get_translator(core.get_current_modname())

local function sound_place(itemname, pos)
	local n_defs = core.registered_nodes[itemname]

	if n_defs and n_defs.sounds and n_defs.sounds.place then
		core.sound_play(n_defs.sounds.place, {
			gain = 1.0,
			pitch = 1 + math.random(-10, 10) * 0.005,
			pos = pos,
		}, true)
	end
end

local function sound_take(itemname, pos)
	local n_defs = core.registered_nodes[itemname]

	if n_defs and n_defs.sounds and n_defs.sounds.dug then
		core.sound_play(n_defs.sounds.dug, {
			gain = 1.0,
			pitch = 1 + math.random(-10, 10) * 0.005,
			pos = pos
		}, true)
	end
end

function mcl_cauldrons.get_cauldron_name(level, liquid)
	level = math.min(3, level)
	level = math.max(0, level)

	if level == 0 then return "mcl_cauldrons:cauldron" end

	return "mcl_cauldrons:cauldron_" .. level .. "_" .. liquid
end

function mcl_cauldrons.add_level(pos, amount, liquid)
	local node = core.get_node(pos)

	if minetest.get_item_group(node.name, "cauldron") == 0 then return end

	amount = amount or 1

	local level = core.get_item_group(node.name, "cauldron_filled")
	local n_defs = core.registered_nodes[node.name]
	local liquid = n_defs and n_defs._mcl_cauldrons_liquid or liquid

	if amount ~= 0 and liquid then
		if amount > 0 then
			sound_place(mcl_cauldrons.liquids[liquid].node, pos)
		else
			sound_take(mcl_cauldrons.liquids[liquid].node, pos)
		end

		node.name = mcl_cauldrons.get_cauldron_name(level + amount, liquid)

		mcl_redstone.swap_node(pos, node)

		return true
	end
end

local function get_node_box(level)
	local floor_y = (level * 3 - 2) / 16

	return {
		fixed = {
			{-0.5, -0.1875, -0.5, -0.375, 0.5, 0.5}, -- Left wall
			{0.375, -0.1875, -0.5, 0.5, 0.5, 0.5}, -- Right wall
			{-0.375, -0.1875, 0.375, 0.375, 0.5, 0.5}, -- Back wall
			{-0.375, -0.1875, -0.5, 0.375, 0.5, -0.375}, -- Front wall
			{-0.5, -0.3125, -0.5, 0.5, floor_y, 0.5}, -- Floor
			{-0.5, -0.5, -0.5, -0.375, -0.3125, -0.25}, -- Left front foot, part 1
			{-0.375, -0.5, -0.5, -0.25, -0.3125, -0.375}, -- Left front foot, part 2
			{-0.5, -0.5, 0.25, -0.375, -0.3125, 0.5}, -- Left back foot, part 1
			{-0.375, -0.5, 0.375, -0.25, -0.3125, 0.5}, -- Left back foot, part 2
			{0.375, -0.5, 0.25, 0.5, -0.3125, 0.5}, -- Right back foot, part 1
			{0.25, -0.5, 0.375, 0.375, -0.3125, 0.5}, -- Right back foot, part 2
			{0.375, -0.5, -0.5, 0.5, -0.3125, -0.25}, -- Right front foot, part 1
			{0.25, -0.5, -0.5, 0.375, -0.3125, -0.375}, -- Right front foot, part 2
		},
		type = "fixed"
	}
end

local function return_bucket(itemstack, placer, pointed_thing)
	if not placer or not placer:is_player() then return end

	if not core.is_creative_enabled(placer:get_player_name()) then
		if itemstack:get_count() == 1 then
			itemstack:set_name("mcl_buckets:bucket_empty")

			return itemstack
		end

		itemstack:take_item()

		local inv = placer:get_inventory()
		local rest = inv:add_item("main","mcl_buckets:bucket_empty")

		if not rest:is_empty() then
			mcl_util.drop_item_stack(pointed_thing.above, rest)
		end
	end
end

local function bucket_place(itemstack, placer, pointed_thing)
	local name = core.get_node(pointed_thing.under).name

	if core.get_item_group(name, "cauldron_filled") >= 3 then return itemstack end

	local n_defs = core.registered_nodes[name]
	local c_liquid = n_defs and n_defs._mcl_cauldrons_liquid
	local b_liquid = itemstack:get_definition()._mcl_buckets_liquid

	if n_defs._mcl_cauldrons_fill_empty then
		local sucess = core.place_node(pointed_thing.above, {
			name = mcl_cauldrons.liquids[b_liquid].node
		})

		if sucess and not core.is_creative_enabled(placer:get_player_name()) then
			return return_bucket(itemstack, placer, pointed_thing)
		end
	end

	if c_liquid == b_liquid or core.get_item_group(name, "cauldron") == 1 then
		mcl_cauldrons.add_level(pointed_thing.under, 3, b_liquid)

		return_bucket(itemstack, placer, pointed_thing)
	end

	return itemstack
end

local function bucket_place_empty(itemstack, placer, pointed_thing)
	local name = core.get_node(pointed_thing.under).name

	if core.get_item_group(name, "cauldron_filled") < 3 then return itemstack end

	mcl_cauldrons.add_level(pointed_thing.under, -3)

	if not core.is_creative_enabled(placer:get_player_name()) then
		local c_liquid = core.registered_nodes[name]._mcl_cauldrons_liquid
		local bucket = c_liquid and mcl_cauldrons.liquids[c_liquid].bucket

		if bucket then
			if itemstack:get_count() == 1 then
				itemstack:set_name(bucket)

				return itemstack
			end

			itemstack:take_item()

			local inv = placer:get_inventory()
			local rest = inv:add_item("main", bucket)

			if not rest:is_empty() then
				mcl_util.drop_item_stack(pointed_thing.above, rest)
			end
		end
	end

	return itemstack
end

core.register_node("mcl_cauldrons:cauldron", {
	_doc_items_longdesc = S("Cauldrons are used to store water and slowly fill up under rain."),
	_doc_items_usagehelp = S("Place a water bucket into the cauldron to fill it with water. Place an empty bucket on a full cauldron to retrieve the water. Place a water bottle into the cauldron to fill the cauldron to one third with water. Place a glass bottle in a cauldron with water to retrieve one third of the water."),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_on_bucket_place = bucket_place,
	_tt_help = S("Stores water"),
	description = S("Cauldron"),
	drawtype = "nodebox",
	groups = {_mcl_partial = 2, cauldron = 1, comparator_signal = 0, deco_block = 1, pickaxey = 1},
	inventory_image = "mcl_cauldrons_cauldron.png",
	is_ground_content = false,
	node_box = get_node_box(0),
	paramtype = "light",
	selection_box = {type = "regular"},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	tiles = {
		"mcl_cauldrons_cauldron_inner.png^mcl_cauldrons_cauldron_top.png",
		"mcl_cauldrons_cauldron_inner.png^mcl_cauldrons_cauldron_bottom.png",
		"mcl_cauldrons_cauldron_side.png"
	},
	wield_image = "mcl_cauldrons_cauldron.png",
	use_texture_alpha = "opaque"
})

--- Register filled cauldrons based on it's bucket counterpart
--- @param id string
--- @param defs table
--- @param overrides table|nil
function mcl_cauldrons.register_filled_cauldron(id, defs, overrides)
	if not mcl_cauldrons.liquids[id] then
		mcl_cauldrons.liquids[id] = {}
		mcl_cauldrons.liquids[id].bucket = defs.bucket
		mcl_cauldrons.liquids[id].node = defs.node
	end

	for i = 1, 3 do
		local name = "mcl_cauldrons:cauldron_" .. i .. "_" .. id

		core.register_node(":" .. name, table.merge({
			_doc_items_create_entry = false,
			_mcl_baseitem = "mcl_cauldrons:cauldron",
			_mcl_blast_resistance = 2,
			_mcl_cauldrons_liquid = id,
			_mcl_hardness = 2,
			_on_bucket_place = bucket_place,
			_on_bucket_place_empty = bucket_place_empty,
			collision_box = get_node_box(0),
			description = S("Cauldron - " .. defs.description_name .. " (@1/3)", i),
			drawtype = "nodebox",
			drop = "mcl_cauldrons:cauldron",
			groups = table.merge({
				_mcl_partial = 2, cauldron = (1 + i), cauldron_filled = i,
				comparator_signal = i, not_in_creative_inventory = 1, pickaxey = 1
			}, defs.groups or {}),
			is_ground_content = false,
			node_box = get_node_box(i),
			paramtype = "light",
			selection_box = {type = "regular"},
			sounds = mcl_sounds.node_sound_metal_defaults(),
			tiles = {
				defs.liquid_texture.."^mcl_cauldrons_cauldron_top.png",
				"mcl_cauldrons_cauldron_inner.png^mcl_cauldrons_cauldron_bottom.png",
				"mcl_cauldrons_cauldron_side.png"
			},
			use_texture_alpha = "opaque"
		}, overrides or {}))
	end
end

core.register_craft({
	output = "mcl_cauldrons:cauldron",
	recipe = {
		{"mcl_core:iron_ingot", "", "mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot", "", "mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"}
	}
})

local function cauldron_extinguish(obj,pos)
	local node = core.get_node(pos)

	if mcl_burning.is_burning(obj) then
		mcl_burning.extinguish(obj)

		local new_group = core.get_item_group(node.name, "cauldron_filled") - 1
		local liquid = core.registered_nodes[node.name]._mcl_cauldrons_liquid
		local subname = new_group == 0 and "" or new_group .. "_" .. liquid
		local new_name = "mcl_cauldrons:cauldron_" .. subname

		core.swap_node(pos, {name = new_name})
	end
end

local etime = 0

core.register_globalstep(function(dtime)
	etime = dtime + etime

	if etime < 0.5 then return end

	etime = 0

	for pl in mcl_util.connected_players() do
		local n = core.find_node_near(pl:get_pos(), 0.4, {"group:cauldron_filled"}, true)

		if n and not core.get_node(n).name:find("lava") then
			cauldron_extinguish(pl, n)
		elseif n and core.get_node(n).name:find("lava") then
			mcl_burning.set_on_fire(pl, 5)
		end
	end

	for _, ent in pairs(core.luaentities) do
		local pos = ent.object:get_pos()

		if pos and ent.is_mob then
			local n = core.find_node_near(pos, 0.4, {"group:cauldron_filled"}, true)

			if n and not core.get_node(n).name:find("lava") then
				cauldron_extinguish(ent.object, n)
			elseif n and core.get_node(n).name:find("lava") then
				mcl_burning.set_on_fire(ent.object, 5)
			end
		end
	end
end)

mcl_cauldrons.register_filled_cauldron("lava", {
	description_name = S("Lava"),
	liquid_texture = "default_lava_source_animated.png^[verticalframe:16:0"
}, {light_source = core.LIGHT_MAX})

mcl_cauldrons.register_filled_cauldron("water", {
	description_name = S("Water"),
	groups = {cauldron_water = 1},
	liquid_texture = "default_water_source_animated.png^[verticalframe:16:0"
})

-- Legacy lbms
core.register_lbm({
	action = function(pos, node)
		local level = node.name:sub(24)

		core.swap_node(pos, {name = "mcl_cauldrons:cauldron_" .. level .. "_water"})
	end,
	label = "Replace old water cauldrons",
	name = "mcl_cauldrons:replace_water",
	nodenames = {
		"mcl_cauldrons:cauldron_1", "mcl_cauldrons:cauldron_2", "mcl_cauldrons:cauldron_3"
	},
	run_at_every_load = false
})

core.register_lbm({
	action = function(pos, node)
		local level = node.name:sub(24, -2)

		core.swap_node(pos, {name = "mcl_cauldrons:cauldron_" .. level .. "_river_water"})
	end,
	label = "Replace old river water cauldrons",
	name = "mcl_cauldrons:replace_river_water",
	nodenames = {
		"mcl_cauldrons:cauldron_1r", "mcl_cauldrons:cauldron_2r", "mcl_cauldrons:cauldron_3r"
	},
	run_at_every_load = false
})
