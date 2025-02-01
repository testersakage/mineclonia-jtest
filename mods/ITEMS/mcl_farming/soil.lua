local S = core.get_translator(core.get_current_modname())

local tpl_soil = {
	_mcl_blast_resistance = 0.6,
	_mcl_hardness = 0.6,
	drawtype = "nodebox",
	drop = "mcl_core:dirt",
	groups = {
		_mcl_partial = 2, dirtifier = 1, dirtifies_below_solid = 1, handy = 1, shovely = 1, soil = 2,
		soil_fungus = 1, soil_sapling = 1
	},
	node_box = {
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.4375, 0.5},
		type = "fixed"
	},
	on_construct = function(pos)
		local node = core.get_node(pos)
		local meta = core.get_meta(pos)
		meta.set_int("wet", node.name:find("_wet") and 7 or 0)
	end,
	paramtype = "light",
	sounds = mcl_sounds.node_sound_dirt_defaults()
}

core.register_node("mcl_farming:soil", table.merge(tpl_soil, {
	_doc_items_longdesc = S("Farmland is used for farming, a necessary surface to plant crops. It is created when a hoe is used on dirt or a similar block. Plants are able to grow on farmland, but slowly. Farmland will become hydrated farmland (on which plants grow faster) when it rains or a water source is nearby. This block will turn back to dirt when a solid block appears above it or a piston arm extends above it."),
	_tt_help = S("Surface for crops").."\n"..S("Can become wet"),
	description = S("Farmland"),
	groups = table.merge(tpl_soil.groups, {deco_block = 1}),
	tiles = {"mcl_farming_farmland_dry.png", "default_dirt.png"}
}))

core.register_node("mcl_farming:soil_wet", {
	_doc_items_longdesc = S("Hydrated farmland is used in farming, this is where you can plant and grow some plants. It is created when farmland is under rain or near water. Without water, this block will dry out eventually. This block will turn back to dirt when a solid block appears above it or a piston arm extends above it."),
	description = S("Hydrated Farmland"),
	groups = table.merge(tpl_soil.groups, {not_in_creative_inventory = 1, soil = 3}),
	tiles = {"mcl_farming_farmland_wet.png", "default_dirt.png"}
})

core.register_abm({
	action = function(pos, node)
		local offset = vector.offset
		local meta = core.get_meta(pos)
		local wet = meta:get_int("wet")

		if not wet then
			if node.name == "mcl_farming:soil" then
				wet = 0
			else
				wet = 7
			end
		end
		-- Turn back into dirt when covered by solid node
		local above_node = core.get_node_or_nil(offset(pos, 0, 1, 0))

		if above_node then
			if core.get_item_group(above_node.name, "solid") ~= 0 then
				node.name = "mcl_core:dirt"
				core.set_node(pos, node)
				return
			end
		end
		-- Check an area of 9×2×9 around the node for nodename (9×9 on same level and 9×9 below)
		local function check_surroundings(pos, nodename)
			local nodes = core.find_nodes_in_area(offset(pos, -4, 0, -4), offset(pos, 4, 1, 4), {nodename})
			return #nodes > 0
		end

		if check_surroundings(pos, "group:water") then
			if node.name ~= "mcl_farming:soil_wet" then
				node.name = "mcl_farming:soil_wet"
				core.set_node(pos, node)
			end
		else -- No water nearby.
			-- The decay branch (make farmland dry or turn back to dirt)
			-- Don't decay while it's raining
			if mcl_weather.rain.raining then
				if mcl_weather.is_outdoor(pos) then
					return
				end
			end
			-- No decay near unloaded areas since these might include water.
			if not check_surroundings(pos, "ignore") then
				if wet <= 0 then
					local nn = core.get_node_or_nil(offset(pos, 0, 1, 0))

					if not nn or not nn.name then return end

					local nn_def = core.registered_nodes[nn.name] or nil

					if nn_def and core.get_item_group(nn.name, "plant") == 0 then
						node.name = "mcl_core:dirt"
						core.set_node(pos, node)

						return
					end
				else
					if wet == 7 then
						node.name = "mcl_farming:soil"
						core.swap_node(pos, node)
					end
					-- Slowly count down wetness
					meta:set_int("wet", wet - 1)
				end
			end
		end
	end,
	chance = 4,
	interval = 15,
	label = "Farmland hydration",
	nodenames = {"mcl_farming:soil", "mcl_farming:soil_wet"}
})

