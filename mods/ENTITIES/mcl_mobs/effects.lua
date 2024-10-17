local mob_class = mcl_mobs.mob_class
local active_particlespawners = {}
local enable_blood = minetest.settings:get_bool("mcl_damage_particles", true)
local DEFAULT_FALL_SPEED = -9.81*1.5
local PI_THIRD = math.pi / 3 -- 60 degrees

local player_transfer_distance = tonumber(minetest.settings:get("player_transfer_distance")) or 128
if player_transfer_distance == 0 then player_transfer_distance = math.huge end

-- custom particle effects
function mcl_mobs.effect(pos, amount, texture, min_size, max_size, radius, gravity, glow, go_down)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or DEFAULT_FALL_SPEED
	glow = glow or 0
	go_down = go_down or false

	local ym
	if go_down then
		ym = 0
	else
		ym = -radius
	end

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = ym, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = 0, y = gravity, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end

function mcl_mobs.death_effect(pos, yaw, collisionbox, rotate)
	local min, max
	if collisionbox then
		min = {x=collisionbox[1], y=collisionbox[2], z=collisionbox[3]}
		max = {x=collisionbox[4], y=collisionbox[5], z=collisionbox[6]}
	else
		min = { x = -0.5, y = 0, z = -0.5 }
		max = { x = 0.5, y = 0.5, z = 0.5 }
	end
	if rotate then
		min = vector.rotate(min, {x=0, y=yaw, z=math.pi/2})
		max = vector.rotate(max, {x=0, y=yaw, z=math.pi/2})
		min, max = vector.sort(min, max)
		min = vector.multiply(min, 0.5)
		max = vector.multiply(max, 0.5)
	end

	minetest.add_particlespawner({
		amount = 50,
		time = 0.001,
		minpos = vector.add(pos, min),
		maxpos = vector.add(pos, max),
		minvel = vector.new(-5,-5,-5),
		maxvel = vector.new(5,5,5),
		minexptime = 1.1,
		maxexptime = 1.5,
		minsize = 1,
		maxsize = 2,
		collisiondetection = false,
		vertical = false,
		texture = "mcl_particles_mob_death.png^[colorize:#000000:255",
	})

	minetest.sound_play("mcl_mobs_mob_poof", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 8,
	}, true)
end


-- play sound
function mob_class:mob_sound(soundname, is_opinion, fixed_pitch)
	local soundinfo = self.child and self.sounds_child or self.sounds
	local sound = soundinfo and soundinfo[soundname]

	if sound then
		if is_opinion and not self:check_timer("opinion_sound_cooloff", self.opinion_sound_cooloff) then
			return
		end
		local pitch
		if not fixed_pitch then
			local base_pitch = soundinfo.base_pitch or 1
			pitch = ( self.child and not self.sounds_child and base_pitch * 1.5 or base_pitch ) + math.random(-10, 10) * 0.005 -- randomize the pitch a bit
		end
		-- Should be 0.1 to 0.2 for mobs. Cow and zombie farms loud. At least have cool down.
		local sound_params = self.sound_params and table.copy(self.sound_params) or {
			max_hear_distance = self.sounds.distance,
			pitch = pitch,
		}
		sound_params.object = self.object
		minetest.sound_play(sound, sound_params, true)
	end
end

function mob_class:add_texture_mod(mod)
	local full_mod = ""
	local already_added = false
	for i=1, #self.texture_mods do
		if mod == self.texture_mods[i] then
			already_added = true
		end
		full_mod = full_mod .. self.texture_mods[i]
	end
	if not already_added then
		full_mod = full_mod .. mod
		table.insert(self.texture_mods, mod)
	end
	self.object:set_texture_mod(full_mod)
end

function mob_class:remove_texture_mod(mod)
	local full_mod = ""
	local remove = {}
	for i=1, #self.texture_mods do
		if self.texture_mods[i] ~= mod then
			full_mod = full_mod .. self.texture_mods[i]
		else
			table.insert(remove, i)
		end
	end
	for i=#remove, 1, -1 do
		table.remove(self.texture_mods, remove[i])
	end
	self.object:set_texture_mod(full_mod)
end

function mob_class:damage_effect(damage)
	-- damage particles
	if enable_blood and damage > 0 then
		local amount_large = math.floor(damage / 2)
		local amount_small = damage % 2

		local pos = self.object:get_pos()

		local cbox = self.object:get_properties().collisionbox
		pos.y = pos.y + (cbox[5] - cbox[2]) * .5

		local texture = "mobs_blood.png"
		-- full heart damage (one particle for each 2 HP damage)
		if amount_large > 0 then
			mcl_mobs.effect(pos, amount_large, texture, 2, 2, 1.75, 0, nil, true)
		end
		-- half heart damage (one additional particle if damage is an odd number)
		if amount_small > 0 then
			-- TODO: Use "half heart"
			mcl_mobs.effect(pos, amount_small, texture, 1, 1, 1.75, 0, nil, true)
		end
	end
end

function mob_class:remove_particlespawners(pn)
	if not active_particlespawners[pn] then return end
	if not active_particlespawners[pn][self.object] then return end
	for _, v in pairs(active_particlespawners[pn][self.object]) do
		minetest.delete_particlespawner(v)
	end
end

function mob_class:add_particlespawners(pn)
	if not active_particlespawners[pn] then active_particlespawners[pn] = {} end
	if not active_particlespawners[pn][self.object] then active_particlespawners[pn][self.object] = {} end
	for _,ps in pairs(self.particlespawners) do
		ps.attached = self.object
		ps.playername = pn
		table.insert(active_particlespawners[pn][self.object],minetest.add_particlespawner(ps))
	end
end

function mob_class:check_particlespawners(dtime)
	if not self.particlespawners then return end
	--minetest.log(dump(active_particlespawners))
	if self._particle_timer and self._particle_timer >= 1 then
		self._particle_timer = 0
		local players = {}
		for player in mcl_util.connected_players() do
			local pn = player:get_player_name()
			table.insert(players,pn)
			if not active_particlespawners[pn] then
				active_particlespawners[pn] = {} end

			local dst = vector.distance(player:get_pos(),self.object:get_pos())
			if dst < player_transfer_distance and not active_particlespawners[pn][self.object] then
				self:add_particlespawners(pn)
			elseif dst >= player_transfer_distance and active_particlespawners[pn][self.object] then
				self:remove_particlespawners(pn)
			end
		end
	elseif not self._particle_timer then
		self._particle_timer = 0
	end
	self._particle_timer = self._particle_timer + dtime
end


-- set defined animation
function mob_class:set_animation(anim, fixed_frame)
	if not self.animation or not anim then
		return
	end

	if self.jockey_vehicle and self.object:get_attach () then
		anim = "jockey"
	end

	if self.dead and anim ~= "die" and anim ~= "stand" then
		return
	end

	if self.attack and self._punch_animation_timeout then
		anim = "punch"
	end

	self._current_animation = self._current_animation or ""

	if (anim == self._current_animation
	or not self.animation[anim .. "_start"]
	or not self.animation[anim .. "_end"]) and not self.dead then
		return
	end

	self._current_animation = anim

	local a_start = self.animation[anim .. "_start"]
	local a_end
	if fixed_frame then
		a_end = a_start
	else
		a_end = self.animation[anim .. "_end"]
	end
	if a_start and a_end then
		local loop = self.animation[anim .. "_loop"] ~= false
		self.object:set_animation({x = a_start,
					   y = a_end},
			self.animation[anim .. "_speed"] or self.animation.speed_normal or 15,
			0, loop)
		if not loop then
			self._current_animation = nil
		end
	end
end

-- above function exported for mount.lua
function mcl_mobs.set_animation(self, anim)
	self:set_animation(anim)
end

function mob_class:who_are_you_looking_at()
	local pos = self.object:get_pos()

	if self.order == "sleep" then
		self._locked_object = nil
		return
	end

	local stop_look_at_player_chance = math.random(833/self.curiosity)
	-- was 10000 - div by 12 for avg entities as outside loop

	local stop_look_at_player = stop_look_at_player_chance == 1

	if self.attack then
		self._locked_object = self.attack
	elseif self.following then
		self._locked_object = self.following
	elseif self.mate then
		self._locked_object = self.mate
	elseif self._locked_object then
		if stop_look_at_player then
			--minetest.log("Stop look: ".. self.name)
			self._locked_object = nil
		end
	elseif not self._locked_object then
		if math.random(1, 30) then
			-- For the wither this was 20/60=0.33, so probably need to rebalance and divide rates.
			-- but frequency of check isn't good as it is costly. Making others too infrequent requires testing
			local look_at_player_chance = math.random(math.max(1,20/self.curiosity))

			-- was 5000 but called in loop based on entities. so div by 12 as estimate avg of entities found,
			-- then div by 20 as less freq lookup

			local look_at_player = look_at_player_chance == 1

			for obj in minetest.objects_inside_radius(pos, 8) do
				if obj:is_player() and vector.distance(pos,obj:get_pos()) < 4 then
					self._locked_object = obj
					break
				elseif obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name == self.name and self ~= obj:get_luaentity()) then
					if look_at_player then
						self._locked_object = obj
						break
					end
				end
			end
		end

	end
end

function mob_class:check_head_swivel(dtime, clear)
	if not self.head_swivel or type(self.head_swivel) ~= "string" then return end

	if clear then
	   self._locked_object = nil
	else
	   self:who_are_you_looking_at ()
	end

	local oldp, oldr
	local newr = vector.zero()
	if self.object.get_bone_override then -- minetest >= 5.9
		local ov = self.object:get_bone_override(self.head_swivel)
		oldp, oldr = ov.position.vec, ov.rotation.vec
	else -- minetest < 5.9
		oldp, oldr = self.object:get_bone_position(self.head_swivel)
		oldr = vector.apply(oldr, math.rad) -- old API uses radians
	end

	local locked_object = self._locked_object
	if locked_object and (locked_object:is_player() or locked_object:get_luaentity()) and locked_object:get_hp() > 0 then
		local _locked_object_eye_height = 1.5
		if locked_object:is_player() then
			_locked_object_eye_height = locked_object:get_properties().eye_height
		elseif locked_object:get_luaentity() then
			_locked_object_eye_height = locked_object:get_luaentity().head_eye_height
		end
		if _locked_object_eye_height then
			local self_rot = self.object:get_rotation()
			-- If a mob is attached, should we really be
			-- messing with what it is looking at?  Should
			-- this be excluded?
			if self.object:get_attach() and self.object:get_attach():get_rotation() then
				self_rot = self.object:get_attach():get_rotation()
			end

			local ps = self.object:get_pos()
			ps.y = ps.y + self.head_eye_height * .7
			local pt = locked_object:get_pos()
			pt.y = pt.y + _locked_object_eye_height
			local dir = vector.direction(ps, pt)
			local mob_yaw = self_rot.y + math.atan2(dir.x, dir.z) + self.head_yaw_offset
			local mob_pitch = math.asin(-dir.y) * self.head_pitch_multiplier

			if (mob_yaw < -PI_THIRD or mob_yaw > PI_THIRD) and not (self.attack and not self.runaway) then
				newr = vector.multiply(oldr, 0.9)
			elseif self.attack and not self.runaway then
				if self.head_yaw == "y" then
					newr = vector.new(mob_pitch, mob_yaw, 0)
				elseif self.head_yaw == "z" then
					newr = vector.new(mob_pitch, 0, -mob_yaw)
				end
			else
				if self.head_yaw == "y" then
					newr = vector.new((mob_pitch-oldr.x)*.3+oldr.x, (mob_yaw-oldr.y)*.3+oldr.y, 0)
				elseif self.head_yaw == "z" then
					newr = vector.new((mob_pitch-oldr.x)*.3+oldr.x, 0, ((mob_yaw-oldr.y)*.3+oldr.y)*-3)
				end
			end
		end
	elseif not locked_object and math.abs(oldr.y) > 0.05 and math.abs(oldr.x) < 0.05 then
		newr = vector.multiply(oldr, 0.9)
	end

	local newp = vector.new(0, self.bone_eye_height, self.horizontal_head_height)
	-- 0.02 is about 1.14 degrees tolerance, to update less often
	if math.abs(oldr.x-newr.x) < 0.02 and math.abs(oldr.y-newr.y) < 0.02 and math.abs(oldr.z-newr.z) < 0.02 and vector.equals(oldp, newp) then return end

	if self.object.get_bone_override then -- minetest >= 5.9
		self.object:set_bone_override(self.head_swivel, {
			position = { vec = newp, absolute = true },
			rotation = { vec = newr, absolute = true } })
	else -- minetest < 5.9
		-- old API uses degrees not radians
		self.object:set_bone_position(self.head_swivel, newp, vector.apply(newr, math.deg))
	end
end

-- set animation speed relative to velocity
function mob_class:set_animation_speed(custom_speed)
	local anim = self._current_animation
	if not anim then
		return
	end
	local name = anim .. "_speed"
	local normal_speed = self.animation[name]
		or self.animation.speed_normal
		or 25
	if anim ~= "walk" and self.anim ~= "run" then
		self.object:set_animation_frame_speed (normal_speed)
		return
	end
	local speed = custom_speed or normal_speed
	local v = self:get_velocity ()
	local scaled_speed = speed * self.frame_speed_multiplier
	self.object:set_animation_frame_speed (scaled_speed * math.min (1, v))
end

minetest.register_on_leaveplayer(function(player)
	local pn = player:get_player_name()
	if not active_particlespawners[pn] then return end
	for _,m in pairs(active_particlespawners[pn]) do
		for _, v in pairs(m) do
			minetest.delete_particlespawner(v)
		end
	end
	active_particlespawners[pn] = nil
end)

----------------------------------------------------------------------------------
-- Smooth rotation.  In the long run, most mob models should receive a root bone,
-- enabling client-side interpolation.
----------------------------------------------------------------------------------

local function norm_radians (x)
	local x = x % (math.pi * 2)
	if x >= math.pi then
		x = x - math.pi * 2
	end
	if x < -math.pi then
		x = x + math.pi * 2
	end
	return x
end

function mob_class:rotation_info ()
	if not self._rotation_info then
		local oldyaw
			= self.object:get_yaw () + self.rotate
		self._rotation_info = {
			yaw = {
				current	= norm_radians (oldyaw),
				remaining_turn = 0,
				amt_per_second = 0,
			},
			pitch = {
				current = self.object:get_rotation ().x,
				remaining_turn = 0,
				amt_per_second = 0,
			},
		}
	end
	return self._rotation_info
end

local ROTATE_TIME = 1/0.15 -- 3 minecraft ticks.

function mob_class:rotate_axis (axis, target)
	local rotation_info = self:rotation_info ()[axis]
	local current_rot

	if axis == "yaw" then
		current_rot = self.object:get_yaw ()
		if self.rotate ~= 0 then
			current_rot
				= norm_radians (current_rot + self.rotate)
		end
	else
		current_rot = self.object:get_rotation ().x
	end

	rotation_info.current = current_rot
	rotation_info.remaining_turn
		= norm_radians (target - current_rot)
	rotation_info.amt_per_second
		= rotation_info.remaining_turn * ROTATE_TIME
end

function mob_class:rotate_gradually (info, axis, dtime)
	local info = info[axis]
	local rem = info.remaining_turn

	if math.abs (info.remaining_turn) > 1.0e-5 then
		local increment = info.amt_per_second * dtime

		if (increment < 0 and increment < info.remaining_turn)
			or (increment > 0 and increment > info.remaining_turn) then
			increment = info.remaining_turn
		end

		local target = info.current + increment
		info.remaining_turn = rem - increment
		info.current = norm_radians (target)
		return info.current
	else
		if axis == "yaw" and self._target_yaw then
			info.current = self._target_yaw
		elseif self._target_pitch then
			info.current = self._target_pitch
		end
		return info.current
	end
end

function mob_class:get_roll ()
	return self.object:get_rotation ().z
end

function mob_class:rotate_step (dtime)
	local yaw, pitch
	local info = self:rotation_info ()
	yaw = self:rotate_gradually (info, "yaw", dtime)
	pitch = self:rotate_gradually (info, "pitch", dtime)
	if self.shaking then
		yaw = yaw + (math.random() * 2 - 1) * 5 * dtime
	end
	self.object:set_rotation ({
			x = pitch,
			y = yaw - self.rotate,
			z = self.dead and self:get_roll () or 0,
	})
end

function mob_class:set_yaw (yaw)
	if self.noyaw then return end

	self:rotate_axis ("yaw", yaw)
	self._target_yaw = yaw
	return yaw
end

function mob_class:get_yaw (yaw)
	return self._target_yaw or (self.object:get_yaw () + self.rotate)
end

function mob_class:set_pitch (pitch)
	self:rotate_axis ("pitch", pitch)
	self._target_pitch = pitch
end

function mob_class:get_pitch ()
	return self._target_pitch or self.object:get_rotation ().x
end


----------------------------------------------------------------------------------
-- Invisibility.  This invisibility exempts attached objects and armor by altering
-- textures rather than visual size.
----------------------------------------------------------------------------------

function mob_class:set_invisible (hide)
	if hide then
		self._mob_invisible = true
		self:set_textures (self._active_texture_list)
	elseif not hide then
		self._mob_invisible = false
		self:set_textures (self._active_texture_list)
	end
end

function mob_class:set_textures (textures)
	self._active_texture_list = textures
	if self._mob_invisible then
		textures = table.copy (textures)
		for i = self.wears_armor and 2 or 1, #textures do
			textures[i] = "blank.png"
		end
	end
	self.object:set_properties ({
			textures = textures,
	})
end
