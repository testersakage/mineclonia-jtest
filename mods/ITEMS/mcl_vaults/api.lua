local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local SHOWITEM_INTERVAL = 2
local VISITED_KEY = modname .. ":visited_players"
local RINGBUFFER_SIZE = 128

local function can_open(pos, player)
	local rb = mcl_util.ringbuffer.get_from_node_meta(pos, VISITED_KEY, RINGBUFFER_SIZE)
	return not rb:indexof(player:get_player_name())
end

local function try_open(pos, player)
	local rb = mcl_util.ringbuffer.get_from_node_meta(pos, VISITED_KEY, RINGBUFFER_SIZE)
	return rb:insert_if_not_exists(player:get_player_name(), true)
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
	groups = {pickaxey=1, material_stone=1, deco_block=1, vault = 1, not_in_creative_inventory = 1},
	is_ground_content = false,
	drop = "",
	_mcl_hardness = 50,
	_mcl_blast_resitance = 50,
}

minetest.register_entity("mcl_vaults:item_entity", {
	initial_properties = {
		physical = false,
		visual = "wielditem",
		visual_size = {x=0.28, y=0.28},
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
	_check_players_near = function(self)
		for _, v in pairs(minetest.get_objects_inside_radius(self._pos, 5)) do
			if v:is_player() and can_open(self._pos, v) then return true end
		end
	end,
	on_step = function(self, dtime)
		self._timer = (self._timer or SHOWITEM_INTERVAL) - dtime
		if self._timer < 0 then
			if minetest.get_item_group(minetest.get_node(self.object:get_pos()).name, "vault") <= 1 then
				self.object:remove()
				return
			end
			self._timer = SHOWITEM_INTERVAL
			self:_next_item()
			if not self:_check_players_near() then
				local node = minetest.get_node(self._pos)
				node.name = "mcl_vaults:"..self._vault_name
				minetest.swap_node(self._pos, node)
				self.object:remove()
			end
		end
	end,
	on_activate = function(self, staticdata, dtime_s)
		local s = minetest.deserialize(staticdata)
		if s and s.loot then
			self._pos = s.pos
			self._vault_name = s.name
			self._loot = s.loot
			self:_next_item()
			self.object:set_armor_groups({ immortal = 1 })
		else
			self.object:remove()
			return
		end
	end,
})

local function create_display_item(pos, def)
	return minetest.add_entity(pos, "mcl_vaults:item_entity", minetest.serialize({loot = def.loot, name = def.name, pos = pos}))
end

function mcl_vaults.activate(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	if def and def._mcl_vault_name and minetest.get_item_group(node.name, "vault") == 1 then
		node.name = "mcl_vaults:"..def._mcl_vault_name.."_on"
		minetest.swap_node(pos, node)
		create_display_item(pos, mcl_vaults.registered_vaults[def._mcl_vault_name])
	end
end

function mcl_vaults.register_vault(name, def)
	assert(type(name) == "string", "[mcl_vaults] trying to register vault without a valid (string) name")
	assert(def.loot, "[mcl_vaults] vault "..tostring(name).." does not define a loot table.")
	def.name = name
	mcl_vaults.registered_vaults[name] = def

	minetest.register_node("mcl_vaults:"..name, table.merge(tpl, {
		_mcl_vault_name = name,
		groups = table.merge(tpl.groups, { not_in_creative_inventory = 0 }),
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack:get_name() == def.key and can_open(pos, clicker) then
				mcl_vaults.activate(pos)
			end
		end
	}, def.node_off))
	minetest.register_node("mcl_vaults:"..name.."_ejecting", table.merge(tpl, {
		_mcl_vault_name = name,
		groups = table.merge(tpl.groups, { vault = 3 }),
	}, def.node_ejecting))

	minetest.register_node("mcl_vaults:"..name.."_on", table.merge(tpl, {
		_mcl_vault_name = name,
		groups = table.merge(tpl.groups, { vault = 2 }),
		on_construct = function(pos)
			create_display_item(pos, def)
		end,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack:get_name() == def.key and try_open(pos, clicker) then
				eject_items(pos, name, mcl_loot.get_multi_loot(def.loot, PcgRandom(os.time())))
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
