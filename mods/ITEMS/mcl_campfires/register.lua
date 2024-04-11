local S = minetest.get_translator(minetest.get_current_modname())

-- Register Plain Campfire
mcl_campfires.register_campfire("mcl_campfires:campfire", {
	description = S("Campfire"),
	inv_texture = "mcl_campfires_campfire_inv.png",
	fire_texture = "mcl_campfires_campfire_fire.png",
	lit_logs_texture = "mcl_campfires_campfire_log_lit.png",
	drops = "mcl_core:charcoal_lump 2",
	lightlevel = 14,
	damage = 1,
})

-- Register Soul Campfire
mcl_campfires.register_campfire("mcl_campfires:soul_campfire", {
	description = S("Soul Campfire"),
	inv_texture = "mcl_campfires_soul_campfire_inv.png",
	fire_texture = "mcl_campfires_soul_campfire_fire.png",
	lit_logs_texture = "mcl_campfires_soul_campfire_log_lit.png",
	drops = "mcl_blackstone:soul_soil",
	lightlevel = 10,
	damage = 2,
})

-- Register Campfire Crafting
minetest.register_craft({
	output = "mcl_campfires:campfire_lit",
	recipe = {
		{ "", "mcl_core:stick", "" },
		{ "mcl_core:stick", "group:coal", "mcl_core:stick" },
		{ "group:tree", "group:tree", "group:tree" },
	}
})

minetest.register_craft({
	output = "mcl_campfires:soul_campfire_lit",
	recipe = {
		{ "", "mcl_core:stick", "" },
		{ "mcl_core:stick", "group:soul_block", "mcl_core:stick" },
		{ "group:tree", "group:tree", "group:tree" },
	}
})

local function get_smoketime(pos, _)
	if minetest.get_node(vector.offset(pos, 0, -1, 0)).name == "mcl_farming:hay_block" then
		return {
			minexptime = 6,
			maxexptime = 8,
		}
	end
end

local psdef = {
	amount = 2,
	time = 0,
	minpos = vector.new(-0.25,0.25,-0.25),
	maxpos = vector.new(0.25,0.25,0.25),
	minvel = vector.new(-0.1,0.5,-0.1),
	maxvel = vector.new(0.1,1.2,0.1),
	minacc = vector.new(-0.1,0.2,-0.1),
	maxacc = vector.new(0.1,0.5,0.1),
	minexptime = 2.75,
	maxexptime = 4.75,
	minsize = 3,
	maxsize = 5,
	collisiondetection = true,
	vertical = true,
	texture = "mcl_campfires_particle_9.png",
	texpool = {
		{ name = "mcl_campfires_particle_1.png" },
		{ name = "mcl_campfires_particle_2.png" },
		{ name = "mcl_campfires_particle_3.png" },
		{ name = "mcl_campfires_particle_4.png" },
		{ name = "mcl_campfires_particle_5.png" },
		{ name = "mcl_campfires_particle_6.png" },
		{ name = "mcl_campfires_particle_7.png" },
		{ name = "mcl_campfires_particle_8.png" },
		{ name = "mcl_campfires_particle_9.png" },
		{ name = "mcl_campfires_particle_10.png" },
		{ name = "mcl_campfires_particle_11.png" },
		{ name = "mcl_campfires_particle_11.png" },
		{ name = "mcl_campfires_particle_12.png" },
	}
}

mcl_node_particles.register_particlespawner("mcl_campfires:campfire_lit", psdef, get_smoketime)
mcl_node_particles.register_particlespawner("mcl_campfires:soul_campfire_lit", psdef, get_smoketime)
