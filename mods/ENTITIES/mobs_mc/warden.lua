--[[

1 -  Range attack not working properly :(
2 -  Upon death, the mob returns and disappears after the animation.
3 -  the censor is missing, future perhaps?
4 -  Sniffing animation, there is no option for that..
5 -  Vibration animation, no nodes, haven't tried and there is no option for that...


]]

mcl_mobs.register_mob("mobs_mc:the_warden", {
	type = "monster",
	spawn_class = "hostile",
	attack_animals = true,
	attack_npcs = true,
	damage = 1, -- 45
	hp_min = 500,
	hp_max = 500,
	xp_min = 5,
	xp_max = 5,
	attack_type = "dogshoot",
	--double_melee_attack = false,
	reach = 3, -- Height: 2.9 blocks
	--[[
	arrow = "mobs_mc:sonic_boom",
	shoot_interval = 1.8,-- 0.9 seconds
	shoot_offset = 1.0,
	attack_range = 8,
	]]
	armor = 10,
	collisionbox = { -0.6, 0, -0.6, 0.6, 2, 0.6 },
	visual = "mesh",
	mesh = "mobs_mc_warden.b3d",
	visual_size = { x = 1, y = 1},
	textures = { "mobs_mc_warden.png" },
	glow = 4,
	walk_velocity = 1,
	run_velocity = 2,
	sounds = {
	   -- random = "",
	},
	drops = {
	   {name = "mcl_sculk:catalyst", chance = 1, min = 1, max = 2},
	},
	view_range = 0, -- 16 nodes
	stepheight = 1.1,
	--instant_death = true,
	fire_resistant = true,
	suffocation = false,
	all_damage = false,
	knock_back = false,

	animation = {
				-- spawned = 80 ,260
			-- sniffing = 420,530
			-- vibration = 530,542
			-- Damage = 546 ,554

		stand_start = 0, stand_end = 60, stand_speed = 25,
		walk_start = 300, walk_end = 380, speed_normal = 25,
		run_start = 300, run_end = 380, speed_run = 50,
		punch_start = 558, punch_end = 574, punch_speed =50,

		-- Attack Range = 580,660
		shoot_start = 580, shoot_end = 660, shoot_speed = 20,
		-- Despawing = 690,960
		die_start = 690, die_end = 960, die_speed = 25,--die_loop = 0,
	},




	do_custom = function(self,dtime)

	self.timer = self.timer + dtime
		if self.timer >= 1 then -- default warden 0.9..



			 for _, player in ipairs(minetest.get_connected_players()) do




				   local controls = player:get_player_control()


					 if controls.sneak then

					   self.view_range = 0

					   --return
					  -- minetest.chat_send_player(player:get_player_name(), "Senak")
						 else


					   self.view_range = 16

					--  minetest.chat_send_player(player:get_player_name(), "No Senak !")
					 end


				   --self.object:set_animation({x=558, y=574},30, 1, false) -- punch animation


			end

			   self.timer = 0
		end -- timer end



	end,


	on_spawn = function(self, pos)
		  self.object:set_animation({x = 80, y = 260}, 50, 0, false)

		   local pos = self.object:get_pos()

			minetest.add_particlespawner({
			amount = 50,
			time = 7,
			minpos = {x = pos.x - 1, y = pos.y, z = pos.z - 1},
			maxpos = {x = pos.x +1, y = pos.y + 0.5, z = pos.z + 1},
			minvel = {x = 0, y = -2, z = 0},
			maxvel = {x = 0, y = -4, z = 0},
			minacc = {x = 0, y = -1, z = 0},
			maxacc = {x = 0, y = -1, z = 0},
			minexptime = 1,
			maxexptime = 2,
			minsize = 1,
			maxsize = 3,
			texture = "mcl_sculk_catalyst_top.png",
			glow = 8,
			})

		end



	--[[
	  on_die = function(self, pos)

	end
	]]


})


mcl_mobs.register_egg("mobs_mc:the_warden", "Warden", "#061118", "#b6a180", 0)


-- fireball (projectile)
mcl_mobs.register_arrow("mobs_mc:sonic_boom", {
	description = "Sonic Boom",
	visual = "sprite",
	visual_size = {x = 1, y = 1},
	textures = {"sonic_boom.png"},
		velocity = 7,
	tail = 1,
	tail_texture = "sonic_boom.png",
	tail_size = 10,
	glow = 5,
	expire = 1,
	collisionbox = {-.5, -.5, -.5, .5, .5, .5},
	redirectable = true,




	hit_player = mcl_mobs.get_arrow_damage_func(0, "sonic_boom"), -- 45
	hit_mob = mcl_mobs.get_arrow_damage_func(0, "sonic_boom"), -- 45



	hit_node = function(self, pos, _)

	end
})
