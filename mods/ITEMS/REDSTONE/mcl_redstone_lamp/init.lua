local S = core.get_translator(core.get_current_modname())

local light = core.LIGHT_MAX

local commdef = {
	groups = {handy=1},
	is_ground_content = false,
	description = S("Redstone Lamp"),
	sounds = mcl_sounds.node_sound_glass_defaults(),
	_mcl_hardness = 0.3,
	_mcl_redstone = {
		connects_to = function(node, dir)
			return true
		end,
		update = function(pos, node)
			if mcl_redstone.get_power(pos) ~= 0 then
				mcl_redstone.swap_node(pos, {name = "mcl_redstone_lamp:lamp_on", param2 = 0})
				-- NOTE: mcl_redstone.swap_node does not (yet) notify observers
				mcl_redstone._notify_observer_neighbours(pos)
			else
				-- Need to use after to be able to check if still unpowered when the event is due
				mcl_redstone.after(2, function()
					if mcl_redstone.get_power(pos) == 0 then
						if core.get_node(pos).name == "mcl_redstone_lamp:lamp_on" then
							mcl_redstone.swap_node(pos, {name = "mcl_redstone_lamp:lamp_off", param2 = 0})
							mcl_redstone._notify_observer_neighbours(pos)
						end
					end
				end)
			end
		end,
	},
}

core.register_node("mcl_redstone_lamp:lamp_off", table.merge(commdef, {
	tiles = {"jeija_lightstone_gray_off.png"},
	_tt_help = S("Glows when powered by redstone power"),
	_doc_items_longdesc = S("Redstone lamps are simple redstone components which glow brightly (light level @1) when they receive redstone power.", light),
}))

core.register_node("mcl_redstone_lamp:lamp_on", table.merge(commdef, {
	tiles = {"jeija_lightstone_gray_on.png"},
	groups = table.merge(commdef.groups, {not_in_creative_inventory=1}),
	drop = "node mcl_redstone_lamp:lamp_off",
	light_source = light,
}))

core.register_craft({
	output = "mcl_redstone_lamp:lamp_off",
	recipe = {
		{"","mcl_redstone:redstone",""},
		{"mcl_redstone:redstone","mcl_nether:glowstone","mcl_redstone:redstone"},
		{"","mcl_redstone:redstone",""},
	}
})

-- Add entry alias for the Help
if core.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mcl_redstone_lamp:lamp_off", "nodes", "mcl_redstone_lamp:lamp_on")
end

