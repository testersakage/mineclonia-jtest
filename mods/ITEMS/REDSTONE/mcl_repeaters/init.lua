local S = minetest.get_translator(minetest.get_current_modname())

local boxes = {
	{
		{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }, -- the main slab
		{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16}, -- still torch
		{ -1/16, -6/16, 0/16, 1/16, -1/16, 2/16}, -- moved torch
	},
	{
		{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }, -- the main slab
		{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16}, -- still torch
		{ -1/16, -6/16, -2/16, 1/16, -1/16, 0/16}, -- moved torch
	},
	{
		{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }, -- the main slab
		{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16}, -- still torch
		{ -1/16, -6/16, -4/16, 1/16, -1/16, -2/16}, -- moved torch
	},
	{
		{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }, -- the main slab
		{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16}, -- still torch
		{ -1/16, -6/16, -6/16, 1/16, -1/16, -4/16}, -- moved torch
	},
}

for delay = 1, 4 do
	local commdef = {
		drawtype = "nodebox",
		usagehelp = (
			S("To power a redstone repeater, send a signal in “arrow” direction (the input). The signal goes out on the opposite side (the output) with a delay. To change the delay, use the redstone repeater. The delay is between 0.1 and 0.4 seconds long and can be changed in steps of 0.1 seconds. It is indicated by the position of the moving redstone torch.").."\n"..
			S("To lock a repeater, send a signal from an adjacent repeater into one of its sides. While locked, the moving redstone torch disappears, the output doesn't change and the input signal is ignored.")
		),
		longdesc = S("Redstone repeaters are versatile redstone components with multiple purposes: 1. They only allow signals to travel in one direction. 2. They delay the signal. 3. Optionally, they can lock their output in one state."),
		use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
		walkable = true,
		selection_box = {
			type = "fixed",
			fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
		},
		collision_box = {
			type = "fixed",
			fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
		},
		node_box = {
			type = "fixed",
			fixed = boxes[delay]
		},
		groups = {dig_immediate = 3, dig_by_water=1, destroy_by_lava_flow=1, dig_by_piston=1, attached_node=1, redstone_repeater=delay},
		paramtype = "light",
		paramtype2 = "4dir",
		sunlight_propagates = false,
		is_ground_content = false,
		drop = "mcl_repeaters:repeater_off_1",
		on_rightclick = function(pos, node, clicker)
			local protname = clicker:get_player_name()
			if minetest.is_protected(pos, protname) then
				minetest.record_protection_violation(pos, protname)
				return
			end
			local ndef = minetest.registered_nodes[node.name]
			local next_setting = delay % 4 + 1
			local powered = ndef._redstone and ndef._redstone.get_power and "on" or "off"

			minetest.set_node(pos, {
				name="mcl_repeaters:repeater_"..powered.."_"..tostring(next_setting),
				param2=node.param2
			})
		end,
		_redstone = {
			connects_to = function(node, dir)
				local fourdir = minetest.dir_to_fourdir(dir)
				return node.param2 == fourdir or (node.param2 + 2) % 4 == fourdir
			end,
		},
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_rotate = screwdriver.disallow,
	}

	minetest.register_node("mcl_repeaters:repeater_off_"..tostring(delay), table.merge(commdef, {
		description = delay == 1 and S("Redstone Repeater") or S("Redstone Repeater (Delay @1)", delay),
		inventory_image = delay == 1 and "mesecons_delayer_item.png" or nil,
		wield_image = delay == 1 and "mesecons_delayer_item.png" or nil,
		_tt_help = delay == 1 and (
			S("Transmits redstone power only in one direction").."\n"..
			S("Delays signal").."\n"..
			S("Output locks when getting active redstone repeater signal from the side")
		) or nil,
		_doc_items_create_entry = delay == 1,
		tiles = {
			"mesecons_delayer_off.png",
			"mcl_stairs_stone_slab_top.png",
			"mesecons_delayer_sides_off.png",
			"mesecons_delayer_sides_off.png",
			"mesecons_delayer_ends_off.png",
			"mesecons_delayer_ends_off.png",
		},
		groups = table.merge(commdef.groups, {not_in_creative_inventory = delay ~= 1 and 1 or 0}),
		_redstone = table.merge(commdef._redstone, {
			update = function(pos, node)
				if mcl_redstone.get_power(pos, -minetest.fourdir_to_dir(node.param2)) ~= 0 then
					return {
						delay = delay,
						priority = 1,
						name = "mcl_repeaters:repeater_on_"..tostring(delay),
						param2 = node.param2,
					}
				end
			end,
		})
	}))
	minetest.register_node("mcl_repeaters:repeater_on_"..tostring(delay), table.merge(commdef, {
		description = S("Redstone Repeater (Delay @1, Powered)", delay),
		_doc_items_create_entry = false,
		tiles = {
			"mesecons_delayer_on.png",
			"mcl_stairs_stone_slab_top.png",
			"mesecons_delayer_sides_on.png",
			"mesecons_delayer_sides_on.png",
			"mesecons_delayer_ends_on.png",
			"mesecons_delayer_ends_on.png",
		},
		groups = table.merge(commdef.groups, {not_in_creative_inventory=1}),
		_redstone = table.merge(commdef._redstone, {
			get_power = function(node, dir)
				local fourdir = minetest.dir_to_fourdir(dir)
				if not fourdir or dir.y ~= 0 then
					return 0
				end
				return node.param2 == fourdir and 15 or 0
			end,
			update = function(pos, node)
				if mcl_redstone.get_power(pos, -minetest.fourdir_to_dir(node.param2)) == 0 then
					return {
						delay = delay,
						name = "mcl_repeaters:repeater_off_"..tostring(delay),
						param2 = node.param2,
					}
				end
			end,
		}),
	}))
end
