local S = core.get_translator(core.get_current_modname())

local sel_heights = {-0.125, 0.15, 0.45}

for i = 0, 3 do
	local premature, mature = i == 0, i == 3
	local longdesc, add_entry_alias
	local desc = S("Premature Nether Wart (Stage @1)", i + 1)
	local subname = not mature and "_" .. i or ""
	local groups = {
		attached_node = 1, destroy_by_lava_flow = 1, dig_by_piston = 1, dig_by_water = 1,
		dig_immediate = 3, not_in_creative_inventory = 1, plant = 1, unsticky = 1
	}
	local sel_height = sel_heights[premature and 1 or i < 3 and 2 or i]
	local texture = "mcl_nether_nether_wart_stage_" .. (i < 2 and i or i - 1) .. ".png"

	if premature then
		longdesc = S("A premature nether wart has just recently been planted on soul sand. Nether wart slowly grows on soul sand in 4 stages (the second and third stages look identical). Although nether wart is home to the Nether, it grows in any dimension.")
	elseif mature then
		desc = S("Mature Nether Wart")
		longdesc = S("The mature nether wart is a plant from the Nether and reached its full size and won't grow any further. It is ready to be harvested for its items.")
	else
		add_entry_alias = true
	end

	core.register_node("mcl_nether:nether_wart" .. subname, table.merge(mcl_farming.tpl_plant, {
		_doc_items_create_entry = premature or mature,
		_doc_items_entry_name = premature and S("Premature Nether Wart") or nil,
		_doc_items_longdesc = longdesc or nil,
		_mcl_baseitem = "mcl_nether:nether_wart_item",
		_mcl_fortune_drop = mature and {
			discrete_uniform_distribution = true,
			items = {"mcl_nether:nether_wart_item"},
			max_count = 4,
			min_count = 2
		} or nil,
		description = desc,
		drop = mature and {
			items = {
				{items = {"mcl_nether:nether_wart_item 1"}, rarity = 3},
				{items = {"mcl_nether:nether_wart_item 2"}, rarity = 1},
				{items = {"mcl_nether:nether_wart_item 2"}, rarity = 3}
			},
			max_items = 2
		} or "mcl_nether:nether_wart_item",
		groups = groups,
		inventory_image = texture,
		selection_box = {
			fixed = {-0.3125, -0.5, -0.3125, 0.3125, sel_height, 0.3125},
			type = "fixed"
		},
		tiles = {texture},
		wield_image = texture
	}))

	if add_entry_alias then
		doc.add_entry_alias("nodes", "mcl_nether:nether_wart_0", "nodes", "mcl_nether:nether_wart_" .. i)
	end
end

core.register_craftitem("mcl_nether:nether_wart_item", {
	_doc_items_longdesc = S("Nether warts are plants home to the Nether. They can be planted on soul sand and grow in 4 stages."),
	_doc_items_usagehelp = S("Place this item on soul sand to plant it and watch it grow."),
	_mcl_crafting_output = {square3 = {output = {"mcl_nether:nether_wart_block"}}},
	_tt_help = S("Grows on soul sand"),
	description = S("Nether Wart"),
	groups = {brewitem = 1, compostability = 30, craftitem = 1},
	inventory_image = "mcl_nether_nether_wart.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then return itemstack end

		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		local placepos = pointed_thing.above
		local soilpos = table.copy(placepos)
		soilpos.y = soilpos.y - 1
		-- Check for correct soil type
		local chk = core.get_item_group(core.get_node(soilpos).name, "soil_nether_wart")
		if chk and chk ~= 0 then
			-- Check if node above soil node allows placement
			if core.registered_items[core.get_node(placepos).name].buildable_to then
				-- Place nether wart
				core.sound_play({name="default_place_node", gain=1.0}, {pos=placepos}, true)
				core.set_node(placepos, {name="mcl_nether:nether_wart_0", param2 = 3})

				if not core.is_creative_enabled(placer:get_player_name()) then
					itemstack:take_item()
				end
				return itemstack
			end
		end
	end,
	wield_image = "mcl_nether_nether_wart.png"
})

mcl_farming:add_plant("nether_wart", "mcl_nether:nether_wart", {"mcl_nether:nether_wart_0", "mcl_nether:nether_wart_1", "mcl_nether:nether_wart_2"}, 35, 11)
