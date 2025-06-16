local modname = core.get_current_modname()
local S = core.get_translator(modname)

local dripleaf_big_allowed_nodes = {
	"mcl_core:dirt",
	"mcl_core:coarse_dirt",
	"mcl_core:dirt_with_grass",
	"mcl_core:podzol",
	"mcl_core:mycelium",
	"mcl_lush_caves:rooted_dirt",
	"mcl_lush_caves:moss",
	"mcl_farming:soil",
	"mcl_farming:soil_wet",
	"mcl_core:clay",
	"mcl_mud:mud",
}

function mcl_lush_caves.bone_meal_dripleaf_big(pos)
	local pos_above = vector.offset(pos,0,1,0)
	local node = core.get_node(pos)
	local facedir = node.param2
	core.remove_node(pos)
	core.set_node(pos_above, {name="mcl_lush_caves:dripleaf_big", param2=facedir})
	local stem = core.add_entity(pos, "mcl_lush_caves:dripleaf_big_stem")
	local stem_entity = stem:get_luaentity()
	if stem_entity then stem_entity:update_rotation(facedir) end
	core.sound_play({name="default_grass_footstep", gain=0.4}, {
		pos = pos,
		gain= 0.4,
		max_hear_distance = 16,
	}, true)
end

local function kill_adjacent(self)
	local pos = self.object:get_pos()
	local node_above = core.get_node(vector.offset(pos,0,1,0))
	if node_above and node_above.name == "mcl_lush_caves:dripleaf_big" then
		core.remove_node(vector.offset(pos,0,1,0))
		core.add_item(vector.offset(pos,0,1,0), {name="mcl_lush_caves:dripleaf_big"})
	end
	for object in core.objects_in_area(vector.offset(pos,0,-1,0), vector.offset(pos,0,1,0)) do
		if object ~= self.object then
			local entity = object:get_luaentity()
			if entity and entity.name == "mcl_lush_caves:dripleaf_big_stem" then
				core.after(0.05, function ()
					entity.object:punch(entity.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = 1},
					}, nil)
				end)
			end
		end
	end
end

--
-- Small Dripleaf
--

core.register_entity("mcl_lush_caves:dripleaf_small_stem", {
	initial_properties = {
		hp_max = 1,
		visual_size = {x=10,y=10},
		visual = "mesh",
		static_save = true,
		paramtype2 = "facedir",
		mesh = "dripleaf_small_stem.obj",
		textures = {"mcl_lush_caves_dripleaf_small.png"},
		backface_culling = false,
	},
	update_rotation = function(self, facedir)
		self.object:set_yaw(core.dir_to_yaw(core.facedir_to_dir(facedir)))
	end,
	on_punch = function(self, puncher)
		local pos = self.object:get_pos()
		local wield_item = puncher:get_wielded_item()
		if wield_item:get_name() == "mcl_tools:shears" then
			core.add_item(vector.offset(pos,0,1,0), {name="mcl_lush_caves:dripleaf_small"})
			self.object:remove()
		end
		core.sound_play(mcl_sounds.node_sound_leaves_defaults().dug)
		local leaf = core.get_node(vector.offset(pos,0,1,0))
		if leaf.name == "mcl_lush_caves:dripleaf_small" then
			core.remove_node(vector.offset(pos,0,1,0))
		end
	end,
})
core.register_node("mcl_lush_caves:dripleaf_small", {
	description = S("Small Dripleaf"),
	_doc_items_create_entry = S("Small Dripleaf"),
	_doc_items_entry_name = S("Small Dripleaf"),
	_doc_items_longdesc = S("Small Dripleaf"),
	groups = {shearsy=1, handy=1, plant=1, dig_by_piston=1, dripleaf=1},
	drawtype = "mesh",
	paramtype2 = "facedir",
	mesh = "dripleaf_small.obj",
	use_texture_alpha = "clip",
	tiles = {"mcl_lush_caves_dripleaf_small.png","mcl_lush_caves_dripleaf_stem.png"},
	selection_box = {
		type = "fixed",
		fixed = {-0.5,-1.5,-0.5, 0.5,0.5,0.5}
	},
	walkable = false,
	drop = "",
	_mcl_shears_drop = true,
	on_place = function (itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local n = core.get_node(pos)
		if n.name ~= "mcl_core:water_source" then
			return itemstack
		end
		local facedir = core.dir_to_facedir(placer:get_look_dir())
		core.sound_play(mcl_sounds.node_sound_leaves_defaults().place)
		core.set_node(vector.offset(pos,0,1,0), {name="mcl_lush_caves:dripleaf_small", param2=facedir})
		local stem = core.add_entity(pos, "mcl_lush_caves:dripleaf_small_stem")
		local stem_entity = stem:get_luaentity()
		if stem_entity then stem_entity:update_rotation(facedir) end
		if not core.is_creative_enabled(placer:get_player_name()) then
			itemstack:take_item()
		end
		return itemstack
	end,
	on_punch = function (pos)
		for obj in core.objects_in_area(vector.offset(pos,0,-1,0),pos) do
			local ent = obj:get_luaentity()
			if ent and ent.name == "mcl_lush_caves:dripleaf_small_stem" then
				ent.object:remove()
			end
		end
	end,
	_on_bone_meal = function (_, _, _, pos)
		for obj in core.objects_in_area(pos,vector.offset(pos,0,-1,0)) do
			local ent = obj:get_luaentity()
			if ent and ent.name == "mcl_lush_caves:dripleaf_small_stem" then
				local facedir = core.get_node(pos).param2
				ent.object:remove()
				local stem = core.add_entity(vector.offset(pos,0,-1,0),
					"mcl_lush_caves:dripleaf_big_stem")
				local stem_entity = stem:get_luaentity()
				if stem_entity then stem_entity:update_rotation(facedir) end
			end
		end
		mcl_lush_caves.bone_meal_dripleaf_big(pos)
	end,
})

--
-- Big dripleaf
--

core.register_entity("mcl_lush_caves:dripleaf_big_stem", {
	initial_properties = {
		hp_max = 1,
		visual_size = {x=10,y=10},
		visual = "mesh",
		static_save = true,
		paramtype2 = "facedir",
		mesh = "dripleaf_big_stem.obj",
		textures = {"mcl_lush_caves_dripleaf_big.png"},
		backface_culling = false,
	},
	update_rotation = function(self, facedir)
		self.object:set_yaw(core.dir_to_yaw(core.facedir_to_dir(facedir)))
	end,
	on_rightclick = function (self, clicker)
		local pos = self.object:get_pos()
		local wield_item = clicker:get_wielded_item()
		if wield_item:get_name() == "mcl_bone_meal:bone_meal" then
			local limit_height = 500
			local attempts = 0
			while core.get_node(pos).name ~= "mcl_lush_caves:dripleaf_big" do
				pos = vector.offset(pos, 0,1,0)
				attempts = attempts + 1
				if attempts >= limit_height then
					return
				end
			end
			mcl_lush_caves.bone_meal_dripleaf_big(pos)
			mcl_bone_meal.add_bone_meal_particle(self.object:get_pos())
		end
	end,
	on_punch = function(self)
		local pos = self.object:get_pos()
		core.add_item(vector.offset(pos,0,1,0), {name="mcl_lush_caves:dripleaf_big"})
		core.sound_play(mcl_sounds.node_sound_leaves_defaults().dug)
	end,
	on_death = kill_adjacent,
})
local dripleaf_big = {
	description = S("Big Dripleaf"),
	_doc_items_create_entry = S("Big Dripleaf"),
	_doc_items_entry_name = S("Big Dripleaf"),
	_doc_items_longdesc = S("Big Dripleaf"),
	groups = {shearsy=1, handy=1, plant=1, dig_by_piston=1, dripleaf=1},
	drawtype = "mesh",
	paramtype2 = "facedir",
	mesh = "dripleaf_big.obj",
	use_texture_alpha = "clip",
	tiles = {"mcl_lush_caves_dripleaf_big.png"},
	collision_box = {
		type = "fixed",
		fixed = {-0.5,0.45,-0.5,0.5,0.5,0.5}
	},
	on_place = function (itemstack, placer, pointed_thing)
		local pos = vector.offset(pointed_thing.above,0,-1,0)
		local node = core.get_node(pos)
		if node.name == "mcl_lush_caves:dripleaf_big" then
			mcl_lush_caves.bone_meal_dripleaf_big(pos)
			core.sound_play(mcl_sounds.node_sound_leaves_defaults().place)
			if not core.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		elseif table.indexof(dripleaf_big_allowed_nodes, node.name) ~= -1 then
			core.sound_play(mcl_sounds.node_sound_leaves_defaults().place)
			core.item_place_node(itemstack, placer, pointed_thing)
		end
		return itemstack
	end,
	on_dig = function (pos, node, digger)
		for object in core.objects_in_area(pos, vector.offset(pos,0,-1,0)) do
			if object then
				local entity = object:get_luaentity()
				entity.object:punch(entity.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = {fleshy = 1},
				}, nil)
			end
		end
		core.node_dig(pos, node, digger)
		return true
	end,
	_on_bone_meal = function (_, _, _, pos)
		mcl_lush_caves.bone_meal_dripleaf_big(pos)
	end,
}
local dripleaf_big_tipped_half = table.merge(dripleaf_big, {
	groups = {not_in_creative_inventory=1},
	mesh = "dripleaf_big_tipped_half.obj",
	on_timer = function(pos)
		local n = core.get_node(pos)
		core.swap_node(pos, {name="mcl_lush_caves:dripleaf_big_tipped_full", param2=n.param2})
		local t = core.get_node_timer(pos)
		t:start(3)
	end,
})
local dripleaf_big_tipped_full = table.merge(dripleaf_big, {
	groups = {not_in_creative_inventory=1},
	walkable= false,
	mesh = "dripleaf_big_tipped_full.obj",
	on_timer = function(pos)
		local n = core.get_node(pos)
		core.swap_node(pos, {name="mcl_lush_caves:dripleaf_big", param2=n.param2})
	end,
})
core.register_node("mcl_lush_caves:dripleaf_big", dripleaf_big)
core.register_node("mcl_lush_caves:dripleaf_big_tipped_half", dripleaf_big_tipped_half)
core.register_node("mcl_lush_caves:dripleaf_big_tipped_full", dripleaf_big_tipped_full)

local player_dripleaf = {}
core.register_globalstep(function(dtime)
	for _,p in pairs(core.get_connected_players()) do
		local pos = vector.offset(p:get_pos(),0,-1,0)
		local node = core.get_node(pos)
		if node and node.name == "mcl_lush_caves:dripleaf_big"
			and mcl_redstone.get_power(pos) == 0 then
			if not player_dripleaf[p] then player_dripleaf[p] = 0 end
			player_dripleaf[p] = player_dripleaf[p] + dtime
			if player_dripleaf[p] > 0.5 then
				core.swap_node(pos,{name = "mcl_lush_caves:dripleaf_big_tipped_half", param2 = node.param2})
				player_dripleaf[p] = nil
				local t = core.get_node_timer(pos)
				t:start(0.5)
			end
		end
	end
end)
