local S = core.get_translator(core.get_current_modname())
local builtin = core.get_translator("__builtin")

core.register_chatcommand("summon", {
	params = builtin("<EntityName> [<X>,<Y>,<Z>] | <EntityName> [<PlayerName>]"),
	description = builtin("Spawn entity at given (or your) position"),
	privs = {give=true, interact=true},
	func = function(name, param)
		if param == "" then
			return false
		end
		local entityname, x, y, z, target_name
		entityname, x, y, z = string.match(param, "^([^ ]+)%s+([%d.~-]+)%s+([%d.~-]+)%s+([%d.~-]+)$")

		if not entityname then
			entityname, target_name = string.match(param, "^([^ ]+)%s+([^ ]+)$")
		end

		if not entityname then
			entityname = string.match(param, "^([^ ]+)$")
		end

		if not entityname then
			return false, builtin("EntityName required.")
		end
		core.log("action", ("%s invokes /spawnentity, entityname=%q")
				:format(name, entityname))
		local player = core.get_player_by_name(name)
		if player == nil then
			core.log("error", "Unable to spawn entity, player is nil")
			return false, builtin("Unable to spawn entity, player is nil.")
		end
		local ent = core.registered_entities[entityname]
		if not ent then
			return false, builtin("Cannot spawn an unknown entity.")
		end
		if core.settings:get_bool("only_peaceful_mobs", false) and ent and ent.is_mob and ent.type == "monster" then
			return false, S("Only peaceful mobs allowed!")
		end

		local p
		if x and y and z then
			p = core.parse_coordinates(x, y, z, player:get_pos())
			if not p then
				return false, builtin("Invalid parameters (@1).", param)
			end
		elseif target_name then
			local target = core.get_player_by_name(target_name)
			if not target then
				return false, builtin("Invalid parameters (@1).", param)
			end
			p = target:get_pos()
		else
			p = player:get_pos()
		end
		p.y = p.y + 1

		local obj = core.add_entity(p, entityname)
		if obj then
			return true, builtin("@1 spawned.", entityname)
		else
			return false, builtin("@1 failed to spawn.", entityname)
		end
	end
})