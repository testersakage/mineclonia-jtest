local S = core.get_translator(core.get_current_modname())

local planton = {
	"mcl_core:coarse_dirt", "mcl_core:dirt", "mcl_core:dirt_with_grass",
	"mcl_core:podzol",  "mcl_farming:soil", "mcl_farming:soil_wet", "mcl_lush_caves:moss"
}

for i = 0, 3 do
	local node_name = "mcl_farming:sweet_berry_bush_" .. i
	local texture = node_name:gsub(":", "_") .. ".png"
	local groups = {
		attached_node = 1, compostability = 30, destroy_by_lava_flow = 1, dig_by_piston = 1,
		dig_by_water = 1, dig_immediate = 3, fire_encouragement = 60, fire_flammability = 20,
		flammable = 3, not_in_creative_inventory = 1, plant = 1, sweet_berry = 1,
		sweet_berry_thorny = i > 0 and i or nil, unsticky = 1
	}

	core.register_node(node_name, table.merge(mcl_farming.tpl_plant, {
		_on_bone_meal = function(itemstack,placer,pointed_thing,pos,node)
			mcl_farming.on_bone_meal(itemstack,placer,pointed_thing,pos,node,"plant_sweet_berry_bush",1)
		end,
		_pathfinding_class = "DAMAGE_OTHER",
		description = S("Sweet Berry Bush (Stage @1)", i),
		drop = i >= 2 and {
			items = {
				{items = {"mcl_farming:sweet_berry " .. i - 1}},
				{items = {"mcl_farming:sweet_berry " .. i}, rarity = 2}
			},
			max_items = 1
		} or "",
		groups = groups,
		inventory_image = texture,
		move_resistance = 7,
		on_rightclick = i >= 2 and function(pos, _, clicker, itemstack)
			if clicker and clicker:is_player() then
				local pn = clicker:get_player_name()

				if core.is_protected(pos, pn) then
					core.record_protection_violation(pos, pn)

					return itemstack
				end

				if itemstack:get_name() == "mcl_bone_meal:bone_meal" then
					return itemstack
				end
			end

			core.add_item(pos, "mcl_farming:sweet_berry " .. math.random(2))
			core.swap_node(pos, {name = "mcl_farming:sweet_berry_bush_0"})

			return itemstack
		end or nil,
		place_param2 = 8,
		selection_box = {
			type = "fixed",
			fixed = {-0.375, -0.5, -0.375, 0.375, -0.30 + i * 0.25, 0.375},
		},
		tiles = {texture},
		wield_image = texture
	}))

	core.register_alias("mcl_sweet_berry:sweet_berry_bush_" .. i, node_name)
end

core.register_craftitem("mcl_farming:sweet_berry", {
	_mcl_saturation = 0.4,
	description = S("Sweet Berry"),
	groups = {compostability = 30, eatable = 1, food = 2},
	inventory_image = "mcl_farming_sweet_berry.png",
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return end

		local pn = placer:get_player_name()
		local pa = pointed_thing.above
		local pu = pointed_thing.under

		if core.is_protected(pointed_thing.above, pn) then
			core.record_protection_violation(pointed_thing.above, pn)

			return itemstack
		end

		if pointed_thing.type == "node" and table.indexof(planton, core.get_node(pu).name) ~= -1
		and pa.y > pu.y and core.get_node(pa).name == "air" then
			core.set_node(pa, {name = "mcl_farming:sweet_berry_bush_0"})

			if not core.is_creative_enabled(pn) then itemstack:take_item() end

			return itemstack
		end

		return core.do_item_eat(1, nil, itemstack, placer, pointed_thing)
	end,
	on_secondary_use = core.item_eat(1),
})
core.register_alias("mcl_sweet_berry:sweet_berry", "mcl_farming:sweet_berry")

-- TODO: Find proper interval and chance values for sweet berry bushes. Current interval and chance values are copied from mcl_farming:beetroot which has similar growth stages.
mcl_farming:add_plant("plant_sweet_berry_bush", "mcl_farming:sweet_berry_bush_3", {"mcl_farming:sweet_berry_bush_0", "mcl_farming:sweet_berry_bush_1", "mcl_farming:sweet_berry_bush_2"}, 68, 3)

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

	for _,ent in pairs(core.luaentities) do
		if ent.is_mob then berry_damage_check(ent.object) end
	end
end)
