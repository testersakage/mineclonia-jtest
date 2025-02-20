local S = core.get_translator(core.get_current_modname())
-- Nether warts
mcl_farming.register_simple_crop("nether_wart", {
	initial_stage_zero = true,
	mature_desc = S("Mature Nether Wart"),
	mature_drop = {
		items = {
			{items = {"mcl_nether:nether_wart_item 2"}},
			{items = {"mcl_nether:nether_wart_item 3"}, rarity = 3},
			{items = {"mcl_nether:nether_wart_item 4"}, rarity = 3}
		},
		max_items = 1
	},
	mature_longdesc = S("The mature nether wart is a plant from the Nether and reached its full size and won't grow any further. It is ready to be harvested for its items."),
	premature_desc = S("Premature Nether Wart"),
	premature_longdesc = S("A premature nether wart has just recently been planted on soul sand. Nether wart slowly grows on soul sand in 4 stages (the second and third stages look identical). Although nether wart is home to the Nether, it grows in any dimension."),
	seed = "mcl_nether:nether_wart_item",
	sel_heights = {["1"] = -0.125, ["2, 3"] = 0.125, ["4"] = 0.4375},
	single_sel_width = 0.5,
	stages = 4,
	textures = {
		["1"] = "mcl_nether_nether_wart_stage_0.png",
		["2, 3"] = "mcl_nether_nether_wart_stage_1.png",
		["4"] = "mcl_nether_nether_wart_stage_2.png"
	}
})
-- Craftitems
core.register_craftitem("mcl_nether:nether_wart_item", {
	_doc_items_longdesc = S("Nether warts are plants home to the Nether. They can be planted on soul sand and grow in 4 stages."),
	_doc_items_usagehelp = S("Place this item on soul sand to plant it and watch it grow."),
	_mcl_crafting_output = {square3 = {output = {"mcl_nether:nether_wart_block"}}},
	_tt_help = S("Grows on soul sand"),
	description = S("Nether Wart"),
	groups = {brewitem = 1, compostability = 30, craftitem = 1},
	inventory_image = "mcl_nether_nether_wart.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return end

		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)

		if rc then return rc end

		local above = pointed_thing.above
		local anode = core.get_node(above)
		local unode = core.get_node(pointed_thing.under)

		if core.get_item_group(unode.name, "soil_nether_wart") then
			local adefs = core.registered_nodes[anode.name]

			if adefs and adefs.buildable_to then
				core.place_node(above, {name = "mcl_nether:nether_wart_0"})
				core.sound_play("default_place_node", {max_hear_distance = 16, pos = above}, true)

				if not core.is_creative_enabled(placer:get_player_name()) then
					itemstack:take_item()
				end
			end
		end

		return itemstack
	end,
	wield_image = "mcl_nether_nether_wart.png"
})

local names = {"mcl_nether:nether_wart_0", "mcl_nether:nether_wart_1", "mcl_nether:nether_wart_2"}

minetest.register_abm({
	label = "Nether wart growth",
	nodenames = {"mcl_nether:nether_wart_0", "mcl_nether:nether_wart_1", "mcl_nether:nether_wart_2"},
	neighbors = {"group:soil_nether_wart"},
	interval = 35,
	chance = 11,
	action = function(pos, node)
		pos.y = pos.y-1
		if minetest.get_item_group(minetest.get_node(pos).name, "soil_nether_wart") == 0 then
			return
		end
		pos.y = pos.y+1
		local step = nil
		for i,name in ipairs(names) do
			if name == node.name then
				step = i
				break
			end
		end
		if step == nil then
			return
		end
		local new_node = {name=names[step+1]}
		if new_node.name == nil then
			new_node.name = "mcl_nether:nether_wart"
		end
		new_node.param = node.param
		new_node.param2 = node.param2
		minetest.set_node(pos, new_node)
	end
})

