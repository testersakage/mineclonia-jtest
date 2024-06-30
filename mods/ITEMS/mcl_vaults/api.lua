local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local SHOWITEM_INTERVAL = 2

local function can_open(pos, player)
	return true
end

local function eject_items(pos, name, list)
	if not list or #list == 0 then
		local node = minetest.get_node(pos)
		node.name = "mcl_vaults:"..name
		minetest.swap_node(pos, node)
		return
	end
	minetest.add_item(vector.offset(pos, 0, 0.5, 0), table.remove(list))
	minetest.after(0.5, eject_items, pos, name, list)
end

minetest.register_craftitem("mcl_vaults:trial_key", {
	inventory_image = "mcl_vaults_trial_key.png",
})

local tpl = {
	drawtype = "allfaces_optional",
	paramtype2 = "facedir",
	paramtype = "light",
	description = S("Vault"),
	_tt_help = S("Ejects loot when opened with the key"),
	_doc_items_longdesc = S("A vault ejects loot when opened with the right key. It can only be opnend once by each player."),
	_doc_items_usagehelp = S("A vault ejects loot when opened with the right key. It can only be opnend once by each player."),
	groups = {pickaxey=1, material_stone=1, deco_block=1},
	is_ground_content = false,
	drop = "",
	_mcl_hardness = 50,
	_mcl_blast_resitance = 50,
}

minetest.register_entity("mcl_vaults:item_entity", {
	initial_properties = {
		physical = false,
		visual = "wielditem",
		visual_size = {x=0.30, y=0.30},
		collisionbox = {0,0,0,0,0,0},
		pointable = true,
		static_save = false,
	},
	_next_item = function(self)
		local i = mcl_loot.get_multi_loot(self._loot, PseudoRandom(os.time()))[1]:get_name()
		self.object:set_properties({
			wield_item = i,
		})
	end,
	on_step = function(self, dtime)
		self._timer = (self._timer or SHOWITEM_INTERVAL) - dtime
		if self._timer < 0 then
			self._timer = SHOWITEM_INTERVAL
			self:_next_item()
		end
	end,
	on_activate = function(self, staticdata, dtime_s)
		local s = minetest.deserialize(staticdata)
		if s and s.loot then
			minetest.log("lol2")
			self._loot = s.loot
			self:_next_item()
			self.object:set_armor_groups({ immortal = 1 })
		else
			self.object:remove()
			return
		end
	end,
})

local function create_display_item(pos, loot)
	return minetest.add_entity(pos, "mcl_vaults:item_entity", minetest.serialize({loot = loot}))
end

function mcl_vaults.register_vault(name, def)
	assert(type(name) == "string", "[mcl_vaults] trying to register vault without a valid (string) name")
	assert(def.loot, "[mcl_vaults] vault "..tostring(name).." does not define a loot table.")

	minetest.register_node("mcl_vaults:"..name, table.merge(tpl, {

	}, def.node_off))
	minetest.register_node("mcl_vaults:"..name.."_ejecting", table.merge(tpl, {
	}, def.node_ejecting))

	minetest.register_node("mcl_vaults:"..name.."_on", table.merge(tpl, {
		on_construct = function(pos)
			create_display_item(pos, def.loot)
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack:get_name() == "mcl_vaults:trial_key" and can_open(pos, clicker) then
				eject_items(pos, name, mcl_loot.get_multi_loot(def.loot, PseudoRandom(os.time())))
				node.name = "mcl_vaults:"..name.."_ejecting"
				minetest.swap_node(pos, node)
				if not minetest.is_creative_enabled(clicker:get_player_name()) then
					itemstack:take_item()
				end
				return itemstack
			end
		end
	}, def.node_on))
end
