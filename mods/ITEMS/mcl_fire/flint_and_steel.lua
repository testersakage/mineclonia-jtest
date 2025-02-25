local S = core.get_translator(core.get_current_modname())
-- Flint and Steel
core.register_tool("mcl_fire:flint_and_steel", {
	_dispense_into_walkable = true,
	_doc_items_longdesc = S("Flint and steel is a tool to start fires and ignite blocks."),
	_doc_items_usagehelp = S("Rightclick the surface of a block to attempt to light a fire in front of it or ignite the block. A few blocks have an unique reaction when ignited."),
	_mcl_uses = 64,
	-- Will change soon
	_on_dispense = function(stack, _, droppos, dropnode, _)
		-- Ignite air
		if dropnode.name == "air" then
			minetest.set_node(droppos, {name="mcl_fire:fire"})
			if not minetest.is_creative_enabled("") then
				stack:add_wear(65535/65) -- 65 uses
			end
		-- Ignite TNT
		elseif dropnode.name == "mcl_tnt:tnt" then
			tnt.ignite(droppos)
			if not minetest.is_creative_enabled("") then
				stack:add_wear(65535/65) -- 65 uses
			end
		-- Ignite Campfire
		elseif minetest.get_item_group(dropnode.name, "campfire") ~= 0 then
			minetest.set_node(droppos, {name=dropnode.name.."_lit"})
			if not minetest.is_creative_enabled("") then
				stack:add_wear(65535/65) -- 65 uses
			end
		end
		return stack
	end,
	_placement_def = {
		inherit = "node_defaults",
		["mobs_mc:creeper"] = "default",
		["mobs_mc:creeper_charged"] = "default",
	},
	_tt_help = S("Starts fires and ignites blocks"),
	description = S("Flint and Steel"),
	groups = {enchantability = -1, flint_and_steel = 1, offhand_item = 1, tool = 2},
	inventory_image = "mcl_fire_flint_and_steel.png",
	on_place = function(_, placer, pointed_thing)
		local node = core.get_node(pointed_thing.under)
		local defs = core.registered_nodes[node.name]

		if defs and defs._on_ignite then
			local overwrite = defs._on_ignite(placer, pointed_thing)

			if not overwrite then mcl_fire.set_fire(pointed_thing, placer, false) end
		else
			mcl_fire.set_fire(pointed_thing, placer, false)
		end

		core.sound_play("fire_flint_and_steel", {
			gain = 0.5, max_hear_distance = 8, pos = pointed_thing.above
		}, true)
	end,
	sound = {breaks = "default_tool_breaks"},
	stack_max = 1,
	wield_image = "mcl_fire_flint_and_steel.png"
})

core.register_craft({
	output = "mcl_fire:flint_and_steel",
	recipe = {"mcl_core:iron_ingot", "mcl_core:flint"},
	type = "shapeless"
})
