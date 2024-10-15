local mob_class = mcl_mobs.mob_class

local function player_near(pos)
	for o in minetest.objects_inside_radius(pos, 2) do
		if o:is_player() then return true end
	end
end

local function get_armor_texture(obj, armor_name)
	local stack = ItemStack(armor_name)
	local def = stack:get_definition()
	if armor_name == "" then
		return ""
	end
	if armor_name=="blank.png" then
		return "blank.png"
	end
	local t = def._mcl_armor_texture or ""
	if type(def._mcl_armor_texture) == "function" then
		t = def._mcl_armor_texture(obj, stack)
	end
	return t.."^"
end

function mob_class:set_armor_texture()
	if self.armor_list then
		local chestplate=minetest.registered_items[ItemStack(self.armor_list.torso):get_name()]  or {name=""}
		local boots=minetest.registered_items[ItemStack(self.armor_list.feet):get_name()] or {name=""}
		local leggings=minetest.registered_items[ItemStack(self.armor_list.legs):get_name()] or {name=""}
		local helmet=minetest.registered_items[ItemStack(self.armor_list.head):get_name()] or {name=""}

		if helmet.name=="" and chestplate.name=="" and leggings.name=="" and boots.name=="" then
			helmet={name="blank.png"}
		end

		local texture = get_armor_texture(self.object, chestplate.name)
		..get_armor_texture(self.object, helmet.name)
		..get_armor_texture(self.object, boots.name)
		..get_armor_texture(self.object, leggings.name)
		if string.sub(texture, -1,-1) == "^" then
			texture=string.sub(texture,1,-2)
		end
		if self.base_texture[self.wears_armor and 1] then
			self.base_texture[self.wears_armor and 1]=texture
		end
		self:set_textures (self.base_texture)

		local armor_
		if type(self.armor) == "table" then
			armor_ = table.copy(self.armor)
			armor_.immortal = 1
		else
			armor_ = {immortal=1, fleshy = self.armor}
		end

		for _,item in pairs(self.armor_list) do
			if not item then return end
			if type(minetest.get_item_group(item, "mcl_armor_points")) == "number" then
				armor_.fleshy=armor_.fleshy-(minetest.get_item_group(item, "mcl_armor_points")*3.5)
			end
		end
		self.object:set_armor_groups(armor_)
	end
end

function mob_class:is_drop(itemstack)
	if self.drops then
		for _, v in pairs(self.drops) do
			if v and v.name and v.name == itemstack:get_name() then return true end
		end
	end
end

function mob_class:effective_drop_probability (armor_slot)
	if not self._armor_drop_probabilities then
		return 0
	end
	return self._armor_drop_probabilities[armor_slot] or 0
end

function mob_class:set_armor_drop_probability (armor_slot, probability)
	if not self._armor_drop_probabilities then
		self._armor_drop_probabilities = {
			[armor_slot] = probability
		}
		return
	end
	self._armor_drop_probabilities[armor_slot] = probability
end

function mob_class:armor_better_than (stack, current)
	local def = current:get_definition ()
	if not def then
		return true
	end

	if current:is_empty () then
		return true
	end

	local itemname = stack:get_name ()
	local curname = current:get_name ()

	if mcl_enchanting.has_enchantment (current, "curse_of_binding") then
		return false
	end

	if minetest.get_item_group (curname, "mcl_armor_points")
		< minetest.get_item_group (itemname, "mcl_armor_points") then
		return true
	elseif minetest.get_item_group (curname, "mcl_armor_toughness")
		< minetest.get_item_group (itemname, "mcl_armor_toughness") then
		return true
	else
		-- TODO: the MC Wiki states that Minecraft also
		-- replaces items without "NBT values" with those
		-- which have them.
		local dur_old = mcl_util.calculate_durability (current)
		local dur_new = mcl_util.calculate_durability (stack)
		if dur_old < dur_new then
			return true
		end
		-- Prefer enchanted to non-enchanted items.
		if minetest.get_item_group (curname, "enchanted") == 0
			and minetest.get_item_group (itemname, "enchanted") ~= 0 then
			return true
		end
	end
end

function mob_class:wielditem_better_than (stack, current)
	-- Always prefer swords to non-sword items.
	local cap_new, cap_old

	if current:is_empty () then
		return true
	end

	local itemname = stack:get_name ()
	local curname = current:get_name ()

	if minetest.get_item_group (itemname, "sword") > 0 then
		if minetest.get_item_group (curname, "sword") == 0 then
			return true
		end
	end

	if minetest.get_item_group (itemname, "tool") ~= 0
		or minetest.get_item_group (itemname, "weapon") ~= 0 then
		cap_new = stack:get_tool_capabilities ()
		cap_old = current:get_tool_capabilities ()
		if minetest.get_item_group (curname, "tool") == 0
			and minetest.get_item_group (curname, "weapon") == 0 then
			return true
		end
		if (cap_new.damage_groups.fleshy or 0)
			> (cap_old.damage_groups.fleshy or 0) then
			return true
		end
		local dur_old = mcl_util.calculate_durability (stack)
		local dur_new = mcl_util.calculate_durability (current)
		if dur_old < dur_new then
			return true
		end
		-- Prefer enchanted to non-enchanted items.
		if minetest.get_item_group (curname, "enchanted") == 0
			and minetest.get_item_group (itemname, "enchanted") ~= 0 then
			return true
		end
	end
	return false
end

function mob_class:try_equip_item (stack, def, itemname)
	if self.wears_armor
		and self.wears_armor ~= "no_pickup"
		and minetest.get_item_group (itemname, "armor") > 0
		and def._mcl_armor_element then
		-- Potentially drop any existing piece of armor in
		-- this slot.
		local slot = def._mcl_armor_element
		local current = self.armor_list[slot]
		local self_pos = self.object:get_pos ()
		if current and current ~= "" then
			if not self:armor_better_than (stack, ItemStack (current)) then
				return false
			end
			local random = math.random () - 0.1
			if math.max (0, random)
				< self:effective_drop_probability (slot) then
				minetest.add_item (self_pos, ItemStack (current))
			end
		end
		self.armor_list[slot] = stack:to_string ()
		local probability = self.armor_drop_probability[slot]
		self:set_armor_drop_probability (slot, probability)
		self:set_armor_texture ()
		self.persistent = true
		return true
	elseif self.can_wield_items
		and self.can_wield_items ~= "no_pickup" then
		local item = self:get_wielditem ()
		if self:wielditem_better_than (stack, item) then
			self:drop_wielditem ()
			self:set_wielditem (stack)
			return true
		end
	end
	return false
end

function mob_class:drop_armor (bonus)
	if not self._armor_drop_probabilities then
		return
	end
	local self_pos = self.object:get_pos ()
	for name, item in pairs (self.armor_list) do
		local probability = self:effective_drop_probability (name)
		if probability > 0 and item and item ~= ""
			and math.random () <= probability + bonus then
			mcl_util.drop_item_stack (self_pos, ItemStack (item))
		end
	end
end

function mob_class:check_item_pickup ()
	if self.pick_up and #self.pick_up > 0
		or (self.wears_armor and self.wears_armor ~= "no_pickup") then
		local p = self.object:get_pos()
		if not p then return end
		local player_near = player_near (p)
		for o in minetest.objects_inside_radius(p, 2) do
			local l=o:get_luaentity()
			if l and l.name == "__builtin:item"
				and l.age >= 1.0
				and not player_near
				and not self:is_drop(ItemStack(l.itemstring)) then
				local stack = ItemStack(l.itemstring)
				local def = stack:get_definition()
				local itemname = stack:get_name()

				if self:try_equip_item (stack, def, itemname) then
					o:remove ()
				elseif self.pick_up then
					for _, v in pairs(self.pick_up) do
						if self.on_pick_up and itemname == v then
							local r = self.on_pick_up(self,l)
							if r and r.is_empty and not r:is_empty() then
								l.itemstring = r:to_string()
							elseif r and r.is_empty and r:is_empty() then
								o:remove()
							end
						end
					end
				end
			end
		end
	end
end
