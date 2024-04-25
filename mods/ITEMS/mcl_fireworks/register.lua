local S = minetest.get_translator(minetest.get_current_modname())

local tt_help = S("Flight Duration:")
local description = S("Firework Rocket")

function mcl_fireworks.use_rocket(itemstack, user, pointed_thing, duration, force)
	local elytra = mcl_player.players[user].elytra
	if elytra.active and elytra.rocketing <= 0 then
		elytra.rocketing = duration
		if not minetest.is_creative_enabled(user:get_player_name()) then
			itemstack:take_item()
		end
		minetest.sound_play("mcl_fireworks_rocket", {pos = user:get_pos()})
	elseif elytra.active then
		minetest.chat_send_player(user:get_player_name(), S("@1s power left. Not using rocket.", math.round(elytra.rocketing, 1)))
	elseif minetest.get_item_group(user:get_inventory():get_stack("armor", 3):get_name(), "elytra") ~= 0 then
		minetest.chat_send_player(user:get_player_name(), S("Elytra not deployed. Jump while falling down to deploy."))
	else
		minetest.chat_send_player(user:get_player_name(), S("Elytra not equipped."))
	end
	return itemstack
end


local function register_rocket(n, duration, force)
	minetest.register_craftitem("mcl_fireworks:rocket_" .. n, {
		description = description,
		_tt_help = tt_help .. " " .. duration,
		inventory_image = "mcl_fireworks_rocket.png",
		on_use = function(itemstack, user, pointed_thing)
			return mcl_fireworks.use_rocket(itemstack, user, pointed_thing, duration, force)
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			return mcl_fireworks.use_rocket(itemstack, user, pointed_thing, duration, force)
		end,
	})
end

minetest.register_alias("mcl_bows:rocket", "mcl_fireworks:rocket_2")

register_rocket(1, 2.2, 10)
register_rocket(2, 4.5, 20)
register_rocket(3, 6, 30)
