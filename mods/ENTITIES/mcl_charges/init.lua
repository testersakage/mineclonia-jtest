	local S = minetest.get_translator("mcl_charges")
	
	--=================================================--
	--===Wind Explosion Function For the Wind Charge===--
	--===Based on some code from the tnt mod for mtg===--
	--=================================================--
	
	local function add_effects(pos, radius, drops)
	--[[minetest.add_particlespawner({
		amount = 64,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = vector.new(-10, -10, -10),
		maxvel = vector.new(10, 10, 10),
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 2.5,
		minsize = radius * 1,
		maxsize = radius * 3,
		texture = "mcl_particles_smoke.png",
	})]]

	-- we just dropped some items. Look at the items entities and pick
	-- one of them to use as texture
	local texture = "mcl_particles_smoke.png" --fallback texture
	local most = 0
	
	minetest.add_particlespawner({
		amount = 64,
		time = 0.3,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = vector.new(-5, 0, -5),
		maxvel = vector.new(5, 3, 5),
		minacc = vector.new(0, -10, 0),
		minexptime = 0.8,
		maxexptime = 2.0,
		minsize = radius * 0.66,
		maxsize = radius * 3,
		texture = texture,
		collisiondetection = true,
	})
end
	
	
	local function calc_velocity(pos1, pos2, old_vel, power)
	-- Avoid errors caused by a vector of zero length
	if vector.equals(pos1, pos2) then
		return old_vel
	end

	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)

	-- randomize it a bit
	vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	-- Limit to terminal velocity
	dist = vector.length(vel)
	if dist > 250 then
		vel = vector.divide(vel, dist / 250)
	end
	return vel
end
local RADIUS = 4
local damage_radius = (RADIUS / math.max(1, RADIUS)) * RADIUS
local radius = 2
local function entity_physics(pos, radius--[[, drops]])
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		local damage = (0 / dist) * radius
		if obj:is_player() then
			local dir = vector.normalize(vector.subtract(obj_pos, pos))
			local moveoff = vector.multiply(dir, math.random(2, 2.5) / dist * RADIUS)
			obj:add_velocity(moveoff)

			obj:set_hp(obj:get_hp() - damage)
		else
			local luaobj = obj:get_luaentity()
			-- object might have disappeared somehow
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
					obj:set_velocity(calc_velocity(pos, obj_pos, obj_vel, radius * 1))
				end
				if do_damage then
					if not obj:get_armor_groups().immortal then
						obj:punch(obj, 1.0, {
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
	

minetest.register_node(":mcl:invis_tnt", {
		tiles = {"blank.png"},
		drawtype = "airlike",
		walkable = false,
		drop = "",
		pointable = false,
		buildable_to = true,
		groups = {not_in_creative_inventory = 1},
		on_construct = function(pos)
			--minetest.sound_play("tnt_ignite", {pos = pos}, true)
			minetest.get_node_timer(pos):start(0.1)
			--minetest.check_for_falling(pos)
		end,
		on_timer = function(pos, elapsed)
			entity_physics(pos, damage_radius)
			minetest.set_node(pos, {name = 'air'})
		end
	})	
	
	--=================--
	--===Wind Charge===--
	--=================--



local function mcl_charge(name, descr, def)
 	minetest.register_craftitem("mcl_charges:" .. name .. "", {
		description = S(descr),
		inventory_image = "mcl_charges_" .. name .. ".png",
		stack_max = 64,

		on_place = function(itemstack, placer, pointed_thing)

			--weapons_shot(itemstack, placer, pointed_thing, def.velocity, name)
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
		end,
		on_secondary_use = function(itemstack, placer, pointed_thing)

			--weapons_shot(itemstack, placer, pointed_thing, def.velocity, name)
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
		end,
		_on_dispense = function(stack, pos, droppos, dropnode, dropdir)
		-- Throw fire charge
		local shootpos = vector.add(pos, vector.multiply(dropdir, 0.51))
		local wind_charge = minetest.add_entity(shootpos, "mcl_charges:".. name .. "_flying")
		if wind_charge and wind_charge:get_pos() then
			local ent_wind = wind_charge:get_luaentity()
			ent_wind._shot_from_dispenser = true
			local v = ent_wind.velocity or 10
			wind_charge:set_velocity(vector.multiply(dropdir, v))
			ent_wind.switch = 1
		end
		stack:take_item()
	end,
})


	minetest.register_entity("mcl_charges:" .. name .. "_flying", {
	

		initial_properties = {

			textures = {"mcl_charges_" .. name .. ".png"},
			hp_max = 20,
			collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
			--collide_with_objects = true,
			collisiondetection = true,
		},

		on_step = function(self, dtime)

			local pos = self.object:get_pos()
			local node = minetest.get_node(pos)
			local n = node.name

			if n ~= "air" then
				def.hit_node(self, pos)
				self.object:remove()
			end
		end
	})
end

mcl_charge("wind_charge", "Wind Charge", {

	hit_player = function(self, player)
	entity_physics(pos, damage_radius)
	add_effects(pos, radius, drops)
	minetest.sound_play("tnt_explode", { pos = pos, gain = 1.0, max_hear_distance = 8 }, true)
	end,

	hit_mob = function(self, player)
	entity_physics(pos, damage_radius)
	add_effects(pos, radius, drops)
	player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 6}
		})

	minetest.sound_play("tnt_explode", { pos = pos, gain = 1.0, max_hear_distance = 8 }, true)
	end,
	hit_node = function(self, pos)
	entity_physics(pos, damage_radius)
	add_effects(pos, radius, drops)
	minetest.sound_play("tnt_explode", { pos = pos, gain = 1.0, max_hear_distance = 8 }, true)
	end

})
	


minetest.register_craft({
	output = "mcl_charges:wind_charge 4",
	type = "shapeless",
	recipe = {"mcl_mobitems:breeze_rod"}
})

