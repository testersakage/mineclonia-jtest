-- TODO: whenever it becomes possible to fully implement kelp without the
-- plantlike_rooted limitation, please update accordingly.
--
-- TODO: whenever it becomes possible to make kelp grow infinitely without
-- resorting to making intermediate kelp stem node, please update accordingly.
--
-- TODO: In MC, you can't actually destroy kelp by bucket'ing water in the middle.
-- However, because of the plantlike_rooted hack, we'll just allow it for now.

local S = minetest.get_translator(minetest.get_current_modname())

-- Kelp API
--------------------------------------------------------------------------------
mcl_ocean = mcl_ocean or {}
local kelp = {}
mcl_ocean.kelp = kelp

-- Once reach the maximum, kelp no longer grows.
kelp.MIN_AGE = 0
kelp.MAX_AGE = 25

kelp.TICK = 0.2 -- Tick interval (in seconds) for updating kelp.

-- The average amount of growth for kelp in a day is 2.16 (https://youtu.be/5Bp4lAjAk3I)
-- Normally, a day lasts 20 minutes, meaning kelp.next_grow() is executed
-- 1200 / TICK times. Per tick probability = (216/100) / (1200/TICK)
-- NOTE: currently, we can't exactly use the same type of randomness MC does, because
-- it has multiple complicated sets of PRNGs.
-- NOTE: Small loss of precision, should be 10 to preserve it.
-- kelp.ROLL_GROWTH_PRECISION = 10
-- kelp.ROLL_GROWTH_NUMERATOR = 216 * kelp.TICK * kelp.ROLL_GROWTH_PRECISION
-- kelp.ROLL_GROWTH_DENOMINATOR = 100 * 1200 * kelp.ROLL_GROWTH_PRECISION
kelp.ROLL_GROWTH_PRECISION = 1
kelp.ROLL_GROWTH_NUMERATOR = 216 * kelp.TICK
kelp.ROLL_GROWTH_DENOMINATOR = 100 * 1200

kelp.leaf_sounds = mcl_sounds.node_sound_leaves_defaults()

function kelp.is_age_growable(age)
	return age >= 0 and age < kelp.MAX_AGE
end


function kelp.is_submerged(node)
	local g = minetest.get_item_group(node.name, "water")
	if g > 0 and g <= 3  then
		return minetest.registered_nodes[node.name].liquidtype
	end
	return false
end


function kelp.is_downward_flowing(pos, node, pos_above, node_above, __is_above__)
	local node = node or minetest.get_node(pos)

	local result = (math.floor(node.param2 / 8) % 2) == 1
	if not (result or __is_above__) then
		local pos_above = pos_above or {x=pos.x,y=pos.y+1,z=pos.z}
		local node_above = node_above or minetest.get_node(pos_above)
		result = kelp.is_submerged(node_above)
			or kelp.is_downward_flowing(nil, node_above, nil, nil, true)
	end
	return result
end


function kelp.is_falling(pos, node, is_falling, pos_bottom, node_bottom, def_bottom)
	-- NOTE: Modified from check_single_for_falling in builtin.
	local nodename = node.name

	if is_falling == false or
		is_falling == nil and minetest.get_item_group(nodename, "falling_node") == 0 then
		return false
	end

	local pos_bottom = pos_bottom or {x = pos.x, y = pos.y - 1, z = pos.z}
	local node_bottom = node_bottom or minetest.get_node_or_nil(pos_bottom)
	local nodename_bottom = node_bottom.name
	local def_bottom = def_bottom or node_bottom and minetest.registered_nodes[nodename_bottom]
	if not def_bottom then
		return false
	end

	local same = nodename == nodename_bottom
	if same and def_bottom.paramtype2 == "leveled" and
			minetest.get_node_level(pos_bottom) <
			minetest.get_node_max_level(pos_bottom) then
		return true
	end

	if not same and
			(not def_bottom.walkable or def_bottom.buildable_to) and
			(minetest.get_item_group(nodename, "float") == 0 or
			def_bottom.liquidtype == "none") then
		return true
	end

	return false
end


function kelp.roll_init_age(min, max)
	return math.random(min or kelp.MIN_AGE, (max or kelp.MAX_AGE)-1)
end

-- Converts param2 to kelp height.
function kelp.get_height(param2)
	return math.floor(param2 / 16) + math.floor(param2 % 16 / 8)
end

function kelp.get_tip(pos, height)
	local height = height or kelp.get_height(minetest.get_node(pos).param2)
	local pos_tip = {x=pos.x, y=pos.y+height+1, z=pos.z}
	return pos_tip, minetest.get_node(pos_tip), height
end

function kelp.find_unsubmerged(pos, node, height)
	local node = node or minetest.get_node(pos)
	local height = height or ((node.param2 >= 0 and node.param2 < 16) and 1) or kelp.get_height(node.param2)

	local walk_pos = {x=pos.x, z=pos.z}
	local y = pos.y
	for i=1,height do
		walk_pos.y = y + i
		local walk_node = minetest.get_node(walk_pos)
		if not kelp.is_submerged(walk_node) then
			return walk_pos, walk_node, height, i
		end
	end
	return nil, nil, height, height
end

function kelp.next_param2(param2)
	return math.min(param2+16 - param2 % 16, 255);
end

local function store_age (pos, age)
	if pos then
		minetest.get_meta(pos):set_int("mcl_ocean:kelp_age", age)
	end
end

local function retrieve_age (pos)
	local meta = minetest.get_meta(pos)
	local age_set = meta:contains("mcl_ocean:kelp_age")
	if not age_set then
		return nil
	end

	local age = meta:get_int("mcl_ocean:kelp_age")
	return age
end

function kelp.init_age(pos)
	local age = retrieve_age(pos)
	if not age then
		age = kelp.roll_init_age()
		store_age(pos, age)
	end
	return age
end

function kelp.next_height(pos, node, pos_tip, node_tip, submerged, downward_flowing)
	local node = node or minetest.get_node(pos)
	local pos_tip = pos_tip
	local node_tip = node_tip or (pos_tip and minetest.get_node(pos_tip))
	if not pos_tip then
		pos_tip,node_tip = kelp.get_tip(pos)
	end
	local downward_flowing = downward_flowing or
		(submerged or kelp.is_submerged(node_tip)
		 and kelp.is_downward_flowing(pos_tip, node_tip))

	node.param2 = kelp.next_param2(node.param2)
	minetest.swap_node(pos, node)

	if downward_flowing then
		local alt_liq = minetest.registered_nodes[node_tip.name].liquid_alternative_source
		if alt_liq and minetest.registered_nodes[alt_liq] then
			minetest.set_node(pos_tip, {name=alt_liq})
		end
	end

	return node, pos_tip, node_tip, submerged, downward_flowing
end


function kelp.next_grow(age, pos, node, pos_tip, node_tip, submerged, downward_flowing)
	local node = node or minetest.get_node(pos)
	local pos_tip = pos_tip
	local node_tip = node_tip or (pos_tip and minetest.get_node(pos_tip))
	if not pos_tip then
		pos_tip,node_tip = kelp.get_tip(pos)
	end

	local downward_flowing = downward_flowing or kelp.is_downward_flowing(pos_tip, node_tip)
	if not (submerged or kelp.is_submerged(node_tip)) then
		return
	end

	kelp.next_height(pos, node, pos_tip, node_tip, submerged, downward_flowing)
	store_age(pos, age)
	return true, node, pos_tip, node_tip, submerged, downward_flowing
end


function kelp.detach_drop(pos, height)
	local height = height or kelp.get_height(minetest.get_node(pos).param2)
	local y = pos.y
	local walk_pos = {x=pos.x, z=pos.z}
	for i=1,height do
		walk_pos.y = y+i
		minetest.add_item(walk_pos, "mcl_ocean:kelp")
	end
	return true
end


-- Detach the kelp at dig_pos, and drop their items.
-- Synonymous to digging the kelp.
-- NOTE: this is intended for whenever kelp truly becomes segmented plants
-- instead of rooted to the floor. Don't try to remove dig_pos.
function kelp.detach_dig(dig_pos, pos, drop, node, height)
	-- Optional params: drop, node, height

	local node = node or minetest.get_node(pos)
	local height = height or kelp.get_height(node.param2)
	local new_height = dig_pos.y - (pos.y+1)

	if new_height <= 0 then
		if drop then
			kelp.detach_drop(dig_pos, height)
		end
		minetest.set_node(pos, {
			name=minetest.registered_nodes[node.name].node_dig_prediction,
			param=node.param,
			param2=0 })

	else
		if drop then
			kelp.detach_drop(dig_pos, height - new_height)
		end
		minetest.swap_node(pos, {name=node.name, param=node.param, param2=16*new_height})
	end
end

function kelp.surface_on_dig(pos, node, _)
	kelp.detach_dig(pos, pos, true, node)
end

function kelp.surface_after_dig_node(pos, node)
	return minetest.set_node(pos, {name=minetest.registered_nodes[node.name].node_dig_prediction})
end

local function detach_unsubmerged(pos)
	local node = minetest.get_node(pos)
	local dig_pos,_, height = kelp.find_unsubmerged(pos, node)
	if dig_pos then
		minetest.sound_play(minetest.registered_nodes[node.name].sounds.dug, { gain = 0.5, pos = dig_pos }, true)
		kelp.detach_dig(dig_pos, pos, true, node, height)
		local new_age = kelp.roll_init_age()
		store_age(pos, new_age)
	end
end

local function grow_kelp (pos)
	local node = minetest.get_node(pos)
	local age = retrieve_age(pos)
	if not age then
		age = kelp.init_age(pos)
	end

	if kelp.is_age_growable(age) then
		kelp.next_grow(age+1, pos, node)
	end
end

function kelp.surface_on_construct(pos)
	kelp.init_age(pos)
end


function kelp.surface_on_destruct(pos)
	local node = minetest.get_node(pos)
	if kelp.is_falling(pos, node) then
		kelp.detach_drop(pos, kelp.get_height(node.param2))
	end
end



function kelp.surface_on_mvps_move(pos, node, oldpos, nodemeta) ---@diagnostic disable-line: unused-local
	kelp.detach_dig(pos, pos, minetest.get_item_group(node.name, "falling_node") ~= 1, node)
end


function kelp.kelp_on_place(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" or not placer then
		return itemstack
	end

	local player_name = placer:get_player_name()
	local pos_under = pointed_thing.under
	local pos_above = pointed_thing.above
	local node_under = minetest.get_node(pos_under)
	local nu_name = node_under.name

	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if rc then return rc end

	-- Protection
	if minetest.is_protected(pos_under, player_name) or
			minetest.is_protected(pos_above, player_name) then
		minetest.log("action", player_name
			.. " tried to place " .. itemstack:get_name()
			.. " at protected position "
			.. minetest.pos_to_string(pos_under))
		minetest.record_protection_violation(pos_under, player_name)
		return itemstack
	end


	local pos_tip, node_tip, def_tip, new_surface, height
	if pos_under.y >= pos_above.y then
		return itemstack
	end

	if minetest.get_item_group(nu_name, "kelp") == 1 then
		height = kelp.get_height(node_under.param2)
		pos_tip,node_tip = kelp.get_tip(pos_under, height)
		def_tip = minetest.registered_nodes[node_tip.name]

	else
		new_surface = false
		for _,surface in pairs(kelp.surfaces) do
			if nu_name == surface.nodename then
				node_under.name = "mcl_ocean:kelp_" ..surface.name
				node_under.param2 = 0
				new_surface = true
				break
			end
		end
		if not new_surface then
			return itemstack
		end

		pos_tip = pos_above
		node_tip = minetest.get_node(pos_above)
		def_tip = minetest.registered_nodes[node_tip.name]
		height = 0
	end

	local submerged = kelp.is_submerged(node_tip)
	if not submerged then
		return itemstack
	end

	local def_node = minetest.registered_items[nu_name]
	if def_node.sounds then
		minetest.sound_play(def_node.sounds.place, { gain = 0.5, pos = pos_under }, true)
	end
	if height < 16 then
		kelp.next_height(pos_under, node_under, pos_tip, node_tip, def_tip, submerged)
	else
		minetest.add_item(pos_tip, "mcl_ocean:kelp")
	end
	if not minetest.is_creative_enabled(player_name) then
		itemstack:take_item()
	end

	kelp.init_age(pos_under)

	return itemstack
end

function kelp.lbm_register(pos)
	kelp.init_age(pos)
end

kelp.surfaces = {
	{ name="dirt",    nodename="mcl_core:dirt",    },
	{ name="sand",    nodename="mcl_core:sand",    },
	{ name="redsand", nodename="mcl_core:redsand", },
	{ name="gravel",  nodename="mcl_core:gravel",  },
}
kelp.registered_surfaces = {}

kelp.surface_deftemplate = {
	drawtype = "plantlike_rooted",
	paramtype = "light",
	paramtype2 = "leveled",
	place_param2 = 16,
	special_tiles = {
		{
		image = "mcl_ocean_kelp_plant.png",
		animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0},
		tileable_vertical = true,
		}
	},
	wield_image = "mcl_ocean_kelp_item.png",
	selection_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
			{ -0.5, 0.5, -0.5, 0.5, 1.5, 0.5 },
		},
	},
	groups = { dig_immediate = 3, deco_block = 1, plant = 1, kelp = 1, },
	on_construct = kelp.surface_on_construct,
	on_destruct = kelp.surface_on_destruct,
	on_dig = kelp.surface_on_dig,
	after_dig_node = kelp.surface_after_dig_node,
	mesecon = { on_mvps_move = kelp.surface_on_mvps_move, },
	drop = "", -- drops are handled in on_dig
	_mcl_hardness = 0,
	_mcl_blast_resistance = 0,
}

kelp.surface_docs = {
	_doc_items_entry_name = S("Kelp"),
	_doc_items_longdesc = S("Kelp grows inside water on top of dirt, sand or gravel."),
	_doc_items_image = "mcl_ocean_kelp_item.png",
}

function kelp.register_kelp_surface(surface, surface_deftemplate, surface_docs)
	local name = surface.name
	local nodename = surface.nodename
	local def = minetest.registered_nodes[nodename]
	local def_tiles = def.tiles

	local surfacename = "mcl_ocean:kelp_"..name
	local surface_deftemplate = surface_deftemplate or kelp.surface_deftemplate -- Optional param

	local doc_create = surface.doc_create or false
	local surface_docs = surface_docs or kelp.surface_docs -- Optional param

	if doc_create then
		surface_deftemplate._doc_items_entry_name = surface_docs._doc_items_entry_name
		surface_deftemplate._doc_items_longdesc = surface_docs._doc_items_longdesc
		surface_deftemplate._doc_items_create_entry = true
		surface_deftemplate._doc_items_image = surface_docs._doc_items_image
		if not surface_docs.entry_id_orig then
			surface_docs.entry_id_orig = nodename
		end
	else
		doc.add_entry_alias("nodes", surface_docs.entry_id_orig, "nodes", surfacename)
	end

	local sounds = table.copy(def.sounds)
	sounds.dig = kelp.leaf_sounds.dig
	sounds.dug = kelp.leaf_sounds.dug
	sounds.place = kelp.leaf_sounds.place

	surface_deftemplate.tiles = surface_deftemplate.tiles or def_tiles
	surface_deftemplate.inventory_image = surface_deftemplate.inventory_image or ("("..def_tiles[1]..")^mcl_ocean_kelp_item.png")
	surface_deftemplate.sounds = surface_deftemplate.sound or sounds
	local falling_node = minetest.get_item_group(nodename, "falling_node")
	surface_deftemplate.node_dig_prediction = surface_deftemplate.node_dig_prediction or nodename
	surface_deftemplate.groups.falling_node = surface_deftemplate.groups.falling_node or falling_node
	surface_deftemplate._mcl_falling_node_alternative = surface_deftemplate._mcl_falling_node_alternative or (falling_node and nodename or nil)

	minetest.register_node(surfacename, surface_deftemplate)
end

kelp.register_kelp_surface(kelp.surfaces[1], table.copy(kelp.surface_deftemplate), kelp.surface_docs)
for i=2, #kelp.surfaces do
	kelp.register_kelp_surface(kelp.surfaces[i], table.copy(kelp.surface_deftemplate), kelp.surface_docs)
end

minetest.register_craftitem("mcl_ocean:kelp", {
	description = S("Kelp"),
	_tt_help = S("Grows in water on dirt, sand, gravel"),
	_doc_items_create_entry = false,
	inventory_image = "mcl_ocean_kelp_item.png",
	wield_image = "mcl_ocean_kelp_item.png",
	on_place = kelp.kelp_on_place,
	groups = {deco_block = 1, compostability = 30, smoker_cookable = 1, campfire_cookable = 1},
	_mcl_cooking_output = "mcl_ocean:dried_kelp"
})

doc.add_entry_alias("nodes", kelp.surface_docs.entry_id_orig, "craftitems", "mcl_ocean:kelp")

minetest.register_craftitem("mcl_ocean:dried_kelp", {
	description = S("Dried Kelp"),
	_doc_items_longdesc = S("Dried kelp is a food item."),
	inventory_image = "mcl_ocean_dried_kelp.png",
	wield_image = "mcl_ocean_dried_kelp.png",
	groups = {food = 2, eatable = 1, compostability = 30},
	on_place = minetest.item_eat(1),
	on_secondary_use = minetest.item_eat(1),
	_mcl_saturation = 0.6,
})


minetest.register_node("mcl_ocean:dried_kelp_block", {
	description = S("Dried Kelp Block"),
	_doc_items_longdesc = S("A decorative block that serves as a great furnace fuel."),
	tiles = { "mcl_ocean_dried_kelp_top.png", "mcl_ocean_dried_kelp_bottom.png", "mcl_ocean_dried_kelp_side.png" },
	is_ground_content = false,
	groups = {
		handy = 1, hoey = 1, building_block = 1, compostability = 50,
		flammable = 2, fire_encouragement = 30, fire_flammability = 60
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	_mcl_hardness = 0.5,
	_mcl_blast_resistance = 2.5,
	_mcl_burntime = 200
})

minetest.register_craft({
	recipe = {
		{ "mcl_ocean:dried_kelp","mcl_ocean:dried_kelp","mcl_ocean:dried_kelp" },
		{ "mcl_ocean:dried_kelp","mcl_ocean:dried_kelp","mcl_ocean:dried_kelp" },
		{ "mcl_ocean:dried_kelp","mcl_ocean:dried_kelp","mcl_ocean:dried_kelp" },
	},
	output = "mcl_ocean:dried_kelp_block",
})
minetest.register_craft({
	recipe = {
		{ "mcl_ocean:dried_kelp_block" },
	},
	output = "mcl_ocean:dried_kelp 9",
})

minetest.register_lbm({
	label = "Kelp initialise",
	name = "mcl_ocean:kelp_init_83",
	nodenames = { "group:kelp" },
	run_at_every_load = false, -- so old kelps are also initialised
	action = kelp.lbm_register,
})

minetest.register_abm({
	label = "Kelp drops",
	nodenames = { "group:kelp" },
	interval = 1.0,
	chance = 1,
	catch_up = false,
	action = detach_unsubmerged, --surface_unsubmerged_abm,
})

minetest.register_abm({
	label = "Kelp growth",
	nodenames = { "group:kelp" },
	interval = 17,
	chance = 28,
	catch_up = false,
	action = grow_kelp,
})
