mcla_potions = {}
local S = minetest.get_translator(minetest.get_current_modname())
--local brewhelp = S("Try different combinations to create potions.")

local function potion_image(colorstring, overlay, texture, opacity)
	if not opacity then
		opacity = 127
	end
	return overlay.."^[colorize:"..(colorstring or "#00FF00")..":"..tostring(opacity).."^"..texture
	--return "mcl_potions_potion_overlay.png^[colorize:"..(colorstring or "#00FF00")..":"..tostring(opacity).."^mcl_potions_potion_bottle.png"
end

local arrow_def = minetest.registered_items["mcl_bows:arrow"]
local arrow_longdesc = arrow_def._doc_items_longdesc or ""
local arrow_tt = arrow_def._tt_help or ""

function mcla_potions.register_arrow(name, desc, color, def)

	minetest.register_craftitem(":mcl_potions:"..name.."_arrow",table.merge(arrow_def, {
		description = desc,
		_tt_help = arrow_tt .. "\n" .. (def.tt or ""),
		_doc_items_longdesc = arrow_longdesc .. "\n" ..
			S("This particular arrow is tipped and will give an effect when it hits a player or mob.") .. "\n" ..
			(def.longdesc or ""),
		inventory_image = "mcl_bows_arrow_inv.png^(mcl_potions_arrow_inv.png^[colorize:"..color..":100)",
		groups = { ammo=1, ammo_bow=1, brewitem=1},
	}))

	local ARROW_ENTITY = table.copy(minetest.registered_entities["mcl_bows:arrow_entity"])
	ARROW_ENTITY._extra_hit_func = function(object)
		mcl_status_effects.start_effect(object, name, {factor = def.factor})
	end
	ARROW_ENTITY._itemstring = "mcl_potions:"..name.."_arrow"

	minetest.register_entity(":mcl_potions:"..name.."_arrow_entity", ARROW_ENTITY)

	minetest.register_craft({
		output = "mcl_potions:"..name.."_arrow 8",
		recipe = {
			{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"},
			{"mcl_bows:arrow","mcl_potions:"..name.."_lingering","mcl_bows:arrow"},
			{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"}
		}
	})

	if minetest.get_modpath("doc_identifier") then
		doc.sub.identifier.register_object("mcl_bows:arrow_entity", "craftitems", "mcl_bows:arrow")
	end
end

local how_to_drink = S("Use the “Place” key to drink it.")
--local potion_intro = S("Drinking a potion gives you a particular effect.")
local function time_string(dur)
	if not dur then
		return nil
	end
	return math.floor(dur/60)..string.format(":%02d",math.floor(dur % 60))
end
local function perc_string(num)

	local rem = math.floor((num-1.0)*100 + 0.1) % 5
	local out = math.floor((num-1.0)*100 + 0.1) - rem

	if (num - 1.0) < 0 then
		return out.."%"
	else
		return "+"..out.."%"
	end
end
-- potion
-- lingering
-- splash
-- effects
local function get_drink_potion_func(def, variant)
	return function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
			if rc then return rc end
		elseif pointed_thing.type == "object" then
			return itemstack
		end

		if def.effect then def.effects = { [def.effect] = true } end

		for effect, v in pairs(def.effects or def[variant].effects or {}) do
			local efdata = { factor = def[variant].factor or def.factor or 1, duration = def[variant].duration or def.duration or 0 }
			if type(v) == "table" then
				efdata = { factor = v.factor or def[variant].factor or def.factor or 1, duration = v.duration or def[variant].duration or def.duration or 0 }
			end
			mcl_status_effects.start_effect(placer, effect, efdata)
		end
		return minetest.do_item_eat(0, "mcl_potions:glass_bottle", itemstack, placer, pointed_thing)
	end
end

function mcla_potions.register_potion(def)
	if def.potion == nil or type(def.potion) == "table" then
		local img = potion_image(def.color, "mcl_potions_potion_overlay.png", "mcl_potions_potion_bottle.png")
		minetest.register_craftitem("mcla_potions:"..def.name, table.merge({
			description = S("Potion of @1", def.description or ""),
			_doc_items_longdesc = def.longdesc,
			_tt_help = perc_string(def.factor or 1).." | "..time_string(def.duration or 0),
			_doc_items_usagehelp = how_to_drink,
			stack_max = 1,
			inventory_image = img,
			wield_image = img,
			groups = {brewitem=1, food=3, can_eat_when_full=1, potion = 1 },
			on_place = get_drink_potion_func(def, "potion"),
			on_secondary_use = get_drink_potion_func(def, "potion")
		}, def.potion or {}))
	end

	if def.splash == nil or type(def.splash) == "table" then
		local img = potion_image(def.color, "mcl_potions_splash_overlay.png", "mcl_potions_splash_bottle.png")
		minetest.register_craftitem("mcla_potions:"..def.name.."_splash", table.merge({
			description = S("Potion of @1", def.description or ""),
			_doc_items_longdesc = def.longdesc,
			_tt_help = perc_string(def.factor or 1).." | "..time_string(def.duration or 0),
			_doc_items_usagehelp = how_to_drink,
			stack_max = 1,
			inventory_image = img,
			wield_image = img,
			groups = {brewitem=1, food=3, can_eat_when_full=1, potion = 1 },
			on_place = get_drink_potion_func(def, "potion"),
			on_secondary_use = get_drink_potion_func(def, "potion")
		}, def.splash or {}))
	end

	if def.lingering == nil or type(def.lingering) == "table" then
		local img = potion_image(def.color, "mcl_potions_splash_overlay.png", "mcl_potions_lingering_bottle.png")
		minetest.register_craftitem("mcla_potions:"..def.name.."_lingering", table.merge({
			description = S("Potion of @1", def.description or ""),
			_doc_items_longdesc = def.longdesc,
			_tt_help = perc_string(def.factor or 1).." | "..time_string(def.duration or 0),
			_doc_items_usagehelp = how_to_drink,
			stack_max = 1,
			inventory_image = img,
			wield_image = img,
			groups = {brewitem=1, food=3, can_eat_when_full=1, potion = 1 },
			on_place = get_drink_potion_func(def, "potion"),
			on_secondary_use = get_drink_potion_func(def, "potion")
		}, def.lingering or {}))
	end

	if def.arrow == nil or type(def.arrow) == "table" then
		mcla_potions.register_arrow(def.name, S("Arrow of @1", def.description), def.color, table.merge({
			--tt = get_tt(def._tt, def.effect, dur/8.),
			--longdesc = def._longdesc,
			--potion_fun = get_arrow_fun(def.effect, dur/8.),
			--no_effect = def.no_effect,
			--instant = def.instant,
		}, def.arrow or {}))
	end
end

mcla_potions.register_potion({
	name = "healing",
	description = S("Healing"),
	longdesc = S("Instantly heals."),
	effect = "healing",
	color = "#F82423",
	potion = {
		_tt = S("+4 HP"),
		factor = 4,
	},
	lvl2 = {
		_tt_2 = S("+8 HP"),
		factor = 8,
	},
})

mcla_potions.register_potion({
	name = "harming",
	description = S("Harming"),
	longdesc = S("Instantly deals damage."),
	effect = "harming",
	color = "#430A09",
	potion = {
		factor = 6,
		_tt = S("-6 HP"),
	},
	lvl2 = {
		factor = 12,
		_tt = S("-12 HP"),

	},
})

mcla_potions.register_potion({
	name = "night_vision",
	description = S("Night Vision"),
	longdesc = S("Increases the perceived brightness of light under a dark sky."),
	color = "#1F1FA1",
})

mcla_potions.register_potion({
	name = "swiftness",
	description = S("Swiftness"),
	longdesc = S("Increases walking speed."),
	color = "#7CAFC6",
	potion = {
		factor = 1.2,
	},
})

mcla_potions.register_potion({
	name = "slowness",
	description = S("Slowness"),
	longdesc = S("Decreases walking speed."),
	color = "#5A6C81",
	potion = {
		factor= 0.85,
	}
})

mcla_potions.register_potion({
	name = "leaping",
	description = S("Leaping"),
	longdesc = S("Increases jump strength."),
	color = "#22FF4C",
	potion = {
		factor = 1.15,
	},
})

mcla_potions.register_potion({
	name = "withering",
	description = S("Withering"),
	longdesc = S("Applies the withering effect which deals damage at a regular interval and can kill."),
	color = "#000000",
	potion = {
		factor = 4,
	},
})

mcla_potions.register_potion({
	name = "poison",
	description = S("Poison"),
	longdesc = S("Applies the poison effect which deals damage at a regular interval."),
	color = "#4E9331",
	potion = {
		factor = 2.5,
	},
})

mcla_potions.register_potion({
	name = "regeneration",
	description = S("Regeneration"),
	longdesc = S("Regenerates health over time."),
	color = "#CD5CAB",
	potion = {
		factor = 2.5,
	},
})

mcla_potions.register_potion({
	name = "invisibility",
	description = S("Invisibility"),
	longdesc = S("Grants invisibility."),
	color = "#7F8392",
})

mcla_potions.register_potion({
	name = "water_breathing",
	description = S("Water Breathing"),
	longdesc = S("Grants limitless breath underwater."),
	color = "#2E5299",
})

mcla_potions.register_potion({
	name = "fire_resistance",
	description = S("Fire Resistance"),
	longdesc = S("Grants immunity to damage from heat sources like fire."),
	color = "#E49A3A",
})

mcla_potions.register_potion({
	name = "awkward",
	tt = S("No effect"),
	longdesc = S("Has an awkward taste and is used for brewing potions."),
	potion = {
		description = S("Awkward Potion"),
	},
	splash = {
		description = S("Awkward Splash Potion"),
	},
	lingering = {
		description = S("Awkward Lingering Potion"),
	},
	arrow = false,
	color = "#0000FF",
})

mcla_potions.register_potion({
	name = "mundane",
	tt = S("No effect"),
	longdesc = S("Has a terrible taste and is not useful for brewing potions."),
	potion = {
		description = S("Mundane Potion"),
	},
	splash = {
		description = S("Mundane Splash Potion"),
	},
	lingering = {
		description = S("Mundane Lingering Potion"),
	},
	arrow = false,
	color = "#0000FF",
})

mcla_potions.register_potion({
	name = "thick",
	tt = S("No effect"),
	longdesc = S("Has a bitter taste and is not useful for brewing potions."),
	potion = {
		description = S("Thick Potion"),
	},
	splash = {
		description = S("Thick Splash Potion"),
	},
	lingering = {
		description = S("Thick Lingering Potion"),
	},
	arrow = false,
	color = "#0000FF",
})

mcla_potions.register_potion({
	name = "dragon_breath",
	potion = {
		description = S("Dragon's Breath"),
		wield_image = "mcl_potions_dragon_breath.png",
		inventory_image = "mcl_potions_dragon_breath.png",
		groups = { brewitem = 1, potion = 1},
		stack_max = 64,
	},
	splash = false,
	lingering = false,
	arrow = false,
	longdesc = S("This item is used in brewing and can be combined with splash potions to create lingering potions."),
})
