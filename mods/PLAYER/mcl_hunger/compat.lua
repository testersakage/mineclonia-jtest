-- backwards compatibility for callers of the old and deprecated API

function mcl_hunger.register_food(name, hunger_change, replace_with_item, poisontime, poison, exhaust, poisonchance, sound)
	core.log("error", "mcl_hunger.register_food is removed and no longer used.")
end

function mcl_hunger.eat(hunger_points, replace_with_item, itemstack, user, _)
	core.log("error", "mcl_hunger.eat is removed and no longer used.")
end

function mcl_hunger.item_eat(hunger_points, replace_with_item, poisontime, poison, exhaust, poisonchance)
	return function(itemstack, user)
		core.log("error", "mcl_hunger.eat is removed and no longer used.")
		return itemstack
	end
end
