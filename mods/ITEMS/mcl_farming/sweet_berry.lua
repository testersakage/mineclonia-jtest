local S = core.get_translator(core.get_current_modname())
-- Sweet berry bushes
mcl_farming.register_simple_crop("sweet_berry_bush", {
	drops = {
		["1, 2"] = "",
		["3"] = {
			items = {
				{items = {"mcl_farming:sweet_berry"}},
				{items = {"mcl_farming:sweet_berry 2"}, rarity = 2}
			},
			max_items = 1
		},
		["4"] = {
			items = {
				{items = {"mcl_farming:sweet_berry 2"}},
				{items = {"mcl_farming:sweet_berry 3"}, rarity = 2}
			},
			max_items = 1
		}
	},
	groups_per_stage = {["1"] = nil, ["2, 3, 4"] = {sweet_berry_thorny = 1}},
	initial_stage_zero = true,
	last_stage_index = 3,
	mature_desc = S("Mature Sweet Berry Bush"),
	mature_longdesc = S("Mature sweet berry bush can be harvest and can drop 2-3 sweet berries."),
	premature_desc = S("Premature Sweet Berry Bush"),
	premature_longdesc = S("Premature sweet berry bush cannot be harvest until it's third stage which can provide 1-2 sweet berries."),
	seed = "mcl_farming:sweet_berry",
	sel_heights = {-0.3125, -0.0625, 0.1875, 0.4375},
	single_sel_width = 0.375,
	stages = 4,
	textures = {
		"mcl_farming_sweet_berry_bush_0.png", "mcl_farming_sweet_berry_bush_1.png",
		"mcl_farming_sweet_berry_bush_2.png", "mcl_farming_sweet_berry_bush_3.png"
	}
}, {
	move_resistance = 7,
	on_rightclick = function(pos, node, clicker, itemstack)
		if clicker and clicker:is_player() then
			local player_name = clicker:get_player_name()

			if core.is_protected(pos, player_name) then
				core.record_protection_violation(pos, player_name)

				return itemstack
			end

			if itemstack:get_name() == "mcl_bone_meal:bone_meal" then
				mcl_farming.on_bone_meal(nil, nil, nil, pos, node, "plant_sweet_berry_bush", 1)
				mcl_bone_meal.add_bone_meal_particle(pos)

				if not core.is_creative_enabled(player_name) then itemstack:take_item() end
			end

			local stage = tonumber(node.name:sub(30))

			if stage > 1 then
				local berries_to_drop = {stage - 1, stage}

				for _ = 1, berries_to_drop[math.random(2)] do
					core.add_item(pos, "mcl_farming:sweet_berry")
				end

				core.swap_node(pos, {name = "mcl_farming:sweet_berry_bush_1"})
			end
		end

		return itemstack
	end,
	place_param2 = 8
})

-- Craftitems
core.register_craftitem("mcl_farming:sweet_berry", {
	_mcl_saturation = 0.4,
	description = S("Sweet Berry"),
	groups = {compostability = 30, eatable = 1, food = 2},
	inventory_image = "mcl_farming_sweet_berry.png",
	on_place = function(itemstack, placer, pointed_thing)
		if placer and placer:is_player() and pointed_thing.type == "node" then
			local apos = pointed_thing.above
			local upos = pointed_thing.under
			local player_name = placer:get_player_name()
			local plant_on = {
				"mcl_core:dirt_with_grass",
				"mcl_core:dirt",
				"mcl_core:podzol",
				"mcl_core:coarse_dirt",
				"mcl_farming:soil",
				"mcl_farming:soil_wet",
				"mcl_lush_caves:moss"
			}

			if core.is_protected(apos, player_name) then
				core.record_protection_violation(apos, player_name)

				return itemstack
			end

			local is_on_top, air = apos.y > upos.y, core.get_node(apos).name:find("air")

			if table.indexof(plant_on, core.get_node(upos).name) ~= -1 and is_on_top and air then
				core.place_node(apos, {name = "mcl_farming:sweet_berry_bush_0"})

				if not core.is_creative_enabled(player_name) then itemstack:take_item() end
			else
				return core.do_item_eat(1, nil, itemstack, placer, pointed_thing)
			end
		end

		return itemstack
	end,
	on_secondary_use = core.item_eat(1),
	wield_image = "mcl_farming_sweet_berry.png"
})
-- Sweet berry bush damage
local function berry_damage_check(obj)
	local p = obj:get_pos()

	if not p then return end

	if not core.find_node_near(p, 0.4, {"group:sweet_berry_thorny"}, true) then return end

	local v = obj:get_velocity()

	if math.abs(v.x) < 0.1 and math.abs(v.y) < 0.1 and math.abs(v.z) < 0.1 then return end

	mcl_util.deal_damage(obj, 0.5, {type = "sweet_berry"})
end

local etime = 0

core.register_globalstep(function(dtime)
	etime = dtime + etime

	if etime < 0.5 then return end

	etime = 0

	for pl in mcl_util.connected_players() do berry_damage_check(pl) end

	for _, ent in pairs(core.luaentities) do
		if ent.is_mob then berry_damage_check(ent.object) end
	end
end)
-- Aliases
for i = 0, 3 do
	local node_name = "mcl_farming:sweet_berry_bush_" .. i

	core.register_alias("mcl_sweet_berry:sweet_berry_bush_" .. i, node_name)
end

core.register_alias("mcl_sweet_berry:sweet_berry", "mcl_farming:sweet_berry")

-- TODO: Find proper interval and chance values for sweet berry bushes. Current interval and chance values are copied from mcl_farming:beetroot which has similar growth stages.
mcl_farming:add_plant("plant_sweet_berry_bush", "mcl_farming:sweet_berry_bush_3", {"mcl_farming:sweet_berry_bush_0", "mcl_farming:sweet_berry_bush_1", "mcl_farming:sweet_berry_bush_2"}, 68, 3)
