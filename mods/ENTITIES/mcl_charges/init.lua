local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Cooldown time and global storing of cooldown
local cooldown_time = 1
mcl_charges_cooldown_data = {}
mcl_charges = {}
	
local S = minetest.get_translator("mcl_charges")
	
--Wind Charge Particle effects
function mcl_charges.add_effects(pos, radius, drops)
	local texture = "mcl_particles_smoke.png"
	local most = 0
		minetest.add_particlespawner({
			amount = 64,
			time = 0.3,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = vector.new(-1, 0, -1),
			maxvel = vector.new(1, 2, 1),
			minacc = vector.new(0, -10, 0),
			minexptime = 0.8,
			maxexptime = 2.0,
			minsize = radius * 0.66,
			maxsize = radius * 3,
			texture = texture,
			collisiondetection = true,
		})
end
-- Chorus flower destruction effects
function mcl_charges.chorus_flower_effects(pos, radius, drops)
	local tex = "mcl_end_chorus_flower_1.png", "mcl_end_chorus_flower_2.png", "mcl_end_chorus_flower_3.png"
	local most = 0
		minetest.add_particlespawner({
			amount = 10,
			time = 0.3,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = vector.new(-5, 0, -5),
			maxvel = vector.new(5, 3, 5),
			minacc = vector.new(0, -10, 0),
			minexptime = 0.8,
			maxexptime = 2.0,
			minsize = radius * 0.66,
			maxsize = radius * 1.00,
			texpool = {tex},
			collisiondetection = true,
		})
end
-- decorated pot destruction effects
function mcl_charges.pot_effects(pos, radius, drops)
	local tex = "mcl_pottery_sherds_pot_1.png", "mcl_pottery_sherds_pot_2.png", "mcl_pottery_sherds_pot_3.png"
	local most = 0
		minetest.add_particlespawner({
			amount = 10,
			time = 0.3,
			minpos = vector.subtract(pos, radius / 2),
			maxpos = vector.add(pos, radius / 2),
			minvel = vector.new(-5, 0, -5),
			maxvel = vector.new(5, 3, 5),
			minacc = vector.new(0, -10, 0),
			minexptime = 0.8,
			maxexptime = 2.0,
			minsize = radius * 0.66,
			maxsize = radius * 1.00,
			texpool = {tex},
			collisiondetection = true,
		})
end
-- Initial knockback function	
function mcl_charges.wind_burst_velocity(pos1, pos2, old_vel, power)

		if vector.equals(pos1, pos2) then
	return old_vel
end

	local vel = vector.direction(pos1, pos2)
		vel = vector.normalize(vel)
		vel = vector.multiply(vel, power)

	local dist = vector.distance(pos1, pos2)
		dist = math.max(dist, 1)
		vel = vector.divide(vel, dist)
		vel = vector.add(vel, old_vel)
		vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	dist = vector.length(vel)
		if dist > 250 then
			vel = vector.divide(vel, dist / 250)
		end
	return vel
end
local RADIUS = 4
local damage_radius = (RADIUS / math.max(1, RADIUS)) * RADIUS
local radius = 2
-- Wind Burst registry
function mcl_charges.wind_burst(pos, radius)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		local dist = math.max(1, vector.distance(pos, obj_pos))
		local damage = (0 / dist) * radius
			if obj:is_player() then
				local dir = vector.normalize(vector.subtract(obj_pos, pos))
				local moveoff = vector.multiply(dir, math.random(1.5, 1.8) / dist * RADIUS)
				obj:add_velocity(moveoff)
				obj:set_hp(obj:get_hp() - damage)
			else
		local luaobj = obj:get_luaentity()
			if luaobj then
				local do_damage = false
				local do_knockback = true
				local entity_drops = {}
				local objdef = minetest.registered_entities[luaobj.name]
				if objdef and objdef.on_blast then
					do_damage, do_knockback, entity_drops = objdef.on_blast(luaobj, damage)
				end
				if do_knockback then
					local obj_vel = obj:get_velocity()
					obj:set_velocity(mcl_charges.wind_burst_velocity(pos, obj_pos, obj_vel, radius * 3))
				end
				if do_damage then
					if not obj:get_armor_groups().immortal then
						obj:punch(node, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = {fleshy = damage},
						}, nil)
					end
				end
				for _, item in pairs(entity_drops) do
					add_drop(drops, item)
				end
			end
		end
	end
end
--throwable charge registry
function register_charge(name, descr, def)
 	minetest.register_craftitem("mcl_charges:" .. name .. "", {
		description = S(descr),
		inventory_image = "mcl_charges_" .. name .. ".png",
		stack_max = 64,

		on_place = function(itemstack, placer, pointed_thing)


local player_name = placer:get_player_name()
      local pos = placer:getpos()
      local dir = placer:get_look_dir()

      local playername = placer:get_player_name()
      if mcl_charges_cooldown_data[playername] == nil then
          mcl_charges_cooldown_data[playername] = 0
      end

      local ig_time = minetest.get_gametime()
      if ig_time - mcl_charges_cooldown_data[playername] >= cooldown_time then
       mcl_charges_cooldown_data[playername] = ig_time
       
			local velocity = 30
			local dir = placer:get_look_dir()
			local playerpos = placer:get_pos()

			local obj = minetest.add_entity({
				x = playerpos.x + dir.x,
				y = playerpos.y + 1.3 + dir.y,
				z = playerpos.z + dir.z
			}, "mcl_charges:" .. name .. "_flying")

			local vec = {x = dir.x * velocity, y = dir.y * velocity, z = dir.z * velocity}
			local acc = {x = 0, y = 0, z = 0}

			obj:set_velocity(vec)
			obj:set_acceleration(acc)

local ent = obj:get_luaentity() ; ent.posthrow = playerpos

			itemstack:take_item()

			return itemstack
					 else
        local remaining_cooldown = math.ceil(cooldown_time - (ig_time - mcl_charges_cooldown_data[playername]))
      	end
		end,
		on_secondary_use = function(itemstack, placer, pointed_thing)

		 local playername = placer:get_player_name()
      if mcl_charges_cooldown_data[playername] == nil then
          mcl_charges_cooldown_data[playername] = 0
      end

      local ig_time = minetest.get_gametime()
      if ig_time - mcl_charges_cooldown_data[playername] >= cooldown_time then
       mcl_charges_cooldown_data[playername] = ig_time

			local velocity = 30
			local dir = placer:get_look_dir()
			local playerpos = placer:get_pos()

			local obj = minetest.add_entity({
				x = playerpos.x + dir.x,
				y = playerpos.y + 2 + dir.y,
				z = playerpos.z + dir.z
			}, "mcl_charges:" .. name .. "_flying")

			local vec = {x = dir.x * velocity, y = dir.y * velocity, z = dir.z * velocity}
			local acc = {x = 0, y = 0, z = 0}

			obj:set_velocity(vec)
			obj:set_acceleration(acc)

local ent = obj:get_luaentity() ; ent.posthrow = playerpos

			itemstack:take_item()

			return itemstack
				else
        local remaining_cooldown = math.ceil(cooldown_time - (ig_time - mcl_charges_cooldown_data[playername]))
       

	end
		end,
		_on_dispense = function(stack, pos, droppos, dropnode, dropdir)
		local shootpos = vector.add(pos, vector.multiply(dropdir, 0.51))
		local charge = minetest.add_entity(shootpos, "mcl_charges:" .. name .. "_flying")
		if charge and charge:get_pos() then
			local ent_charge = charge:get_luaentity()
			ent_charge._shot_from_dispenser = true
			local v = ent_charge.velocity or 20
			charge:set_velocity(vector.multiply(dropdir, v))
			ent_charge.switch = 1
		end
		stack:take_item()
	end,
})
-- Entity registry
minetest.register_entity("mcl_charges:" .. name .. "_flying", {
	initial_properties = {
		visual = "mesh",
		mesh = "wind_charge_test3.obj",
		visual_size = {x=2, y=1.5},
		textures = {"mcl_charges_" .. name .. "_test.png"},
		hp_max = 20,
		collisionbox = {-0.1,-0.1,-0.1, 0.1,0.0,0.1},
		collide_with_objects = true,
	},
		hit_player = def.hit_player,
		hit_mob = def.hit_mob,
		on_activate = def.on_activate,
		on_step = function(self, dtime)
			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			local n = node.name
				if n ~= "air" then
					def.hit_node(self, pos, node)
			--[[	node:punch(node, 1.0, {
        				   full_punch_interval = 1.0,
        				    damage_groups = {fleshy = 0},
        				}, nil)]]
					self.object:remove()
				end
					if self.hit_player or self.hit_mob or self.hit_object then
						for _,player in pairs(minetest.get_objects_inside_radius(pos, 0.6)) do
							if self.hit_player and player:is_player() then
								self.hit_player(self, player)
								def.hit_player_alt(self, pos)
								minetest.after(0.01, function()
									if self.object:get_luaentity() then
        									self.object:remove()
									end
							end)					
					return
			end
			local entity = player:get_luaentity()
				if entity then
					if self.hit_mob	and entity.is_mob then
						self.hit_mob(self, player)
						def.hit_mob_alt(self, pos)
						self.object:remove()
					return
				end
					if self.hit_object and (not entity.is_mob) and tostring(player) ~= self.owner_id and entity.name ~= self.object:get_luaentity().name then
						self.hit_object(self, player)
						def.hit_player_alt(self, pos)
						self.object:remove()
					return
				end
			end
		end
	end
		self.lastpos = pos
	end,
	})
end

dofile(modpath.."/wind_charge.lua")