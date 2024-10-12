local mobs_griefing = minetest.settings:get_bool("mobs_griefing", false)
mcl_mobs.register_mob("mobs_mc:allay", {
	type = "animal",
	spawn_class = "passive",
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	reach = 3,
	armor = 10,
	collisionbox = { -0.2, -0.1, -0.2, 0.2, 0.7, 0.2 },
	visual = "mesh",
	mesh = "mobs_mc_allay.b3d",
	visual_size = { x = 1, y = 1 },
	textures = {
		{"mobs_mc_allay.png"},
		{"mobs_mc_allay2.png"},
		{"mobs_mc_allay3.png"},
		{"mobs_mc_allay4.png"},
		{"mobs_mc_allay5.png"},
		{"mobs_mc_allay6.png"},
		{"mobs_mc_allay7.png"},
		},
	glow = 4,
	fly = true,
	fly_in = { "air" },
	fly_velocity = 4,
	sounds = {
	   -- random = "",
	},
	view_range = 32,
	stepheight = 1.1,
	fall_damage = false,
	animation = {
				-- Dacing = 110,185
				-- Holding Item = 200,220
		stand_start = 0, stand_end = 40, stand_speed = 10,
		walk_start = 50, walk_end = 89, speed_normal = 10,
		run_start = 50, run_end = 89, run_speed = 15,
		--punch_start = 0, punch_end = 0, punch_speed =0,
		--shoot_start = 0, shoot_end = 0, die_speed = 0,
		--die_start = 0, die_end = 0, die_speed = 0,--die_loop = 0,
	},
	_set_item = function (self, stack, clicker)
		if clicker:is_player() then
			self._player = clicker:get_player_name()
			self._given_item = stack:to_string()
			self.pick_up = {stack:get_name() }
		end
	end,
	_drop_items = function(self, only_picked_up)
		if not self._given_item then return end
		minetest.add_item(self.object:get_pos(), self._picked_up_item)
		self._picked_up_item = nil
		if not only_picked_up then
			minetest.add_item(self.object:get_pos(), self.item)
			self._given_item = nil
			self.pick_up = nil
		end
	end,
	on_pick_up = function(self, l)
		if not mobs_griefing then return end
		self._picked_up_item = l.itemstring
		l.object:remove()
	end,
	on_rightclick = function(self, clicker)
		if not mobs_griefing then return end
		local wi = clicker:get_wielded_item()
		self:_drop_items()
		if not wi:is_empty() then
			self:_set_item(wi, clicker)
		end
	end,
	do_custom = function(self)
		if not self:check_timer("allay_item_scan", 3) then return end
		if not self._picked_up_item and self._given_item then
			local pos = self.object:get_pos()
			for o in minetest.objects_inside_radius(pos, self.view_range) do
				local l =o:get_luaentity()
				local opos = o:get_pos()
				if l and l.name == "__builtin:item" and l.itemstring == ItemStack(self._given_item):get_name() and minetest.line_of_sight(pos, opos)then
					self:go_to_pos(opos)
				end
			end
		elseif self._picked_up_item then
			local pl = minetest.get_player_by_name(self._player)
			if pl then
				local pos = self.object:get_pos()
				local plpos = pl:get_pos()
				local dst = vector.distance(pos, plpos)
				if dst <= 3 then
					self:_drop_items(true)
				elseif dst > self.view_range and minetest.line_of_sight(pos, plpos) then
					self:go_to_pos(plpos)
				end
			end
		end
	end
})

mcl_mobs.register_egg("mobs_mc:allay", "Allay", "#38e0e5", "#f7f8f8", 0)
