local S = minetest.get_translator(minetest.get_current_modname())
local mod_doc = minetest.get_modpath("doc")

local wool_descriptions = {
	white = S("White Wool"),
	silver = S("Light Grey Wool"),
	grey = S("Grey Wool"),
	black = S("Black Wool"),
	purple = S("Purple Wool"),
	blue = S("Blue Wool"),
	light_blue = S("Light Blue Wool"),
	cyan = S("Cyan Wool"),
	green = S("Green Wool"),
	lime = S("Lime Wool"),
	yellow = S("Yellow Wool"),
	brown = S("Brown Wool"),
	orange = S("Orange Wool"),
	red = S("Red Wool"),
	magenta = S("Magenta Wool"),
	pink = S("Pink Wool"),
}

local carpet_descriptions = {
	white = S("White Carpet"),
	silver = S("Light Grey Carpet"),
	grey = S("Grey Carpet"),
	black = S("Black Carpet"),
	purple = S("Purple Carpet"),
	blue = S("Blue Carpet"),
	light_blue = S("Light Blue Carpet"),
	cyan = S("Cyan Carpet"),
	green = S("Green Carpet"),
	lime = S("Lime Carpet"),
	yellow = S("Yellow Carpet"),
	brown = S("Brown Carpet"),
	orange = S("Orange Carpet"),
	red = S("Red Carpet"),
	magenta = S("Magenta Carpet"),
	pink = S("Pink Carpet"),
}

-- Backwards compatibility with jordach's 16-color wool mod
minetest.register_alias("mcl_wool:dark_blue", "wool:blue")
minetest.register_alias("mcl_wool:gold", "wool:yellow")

local messy_textures = { --translator table for the bed texture filenames names not adhering to the common color names of mcl_dyes
	["light_blue"] = "mcl_wool_light_blue",
	["grey"] = "wool_dark_grey",
	["silver"] = "wool_grey",
	["green"] = "wool_dark_green",
	["lime"] = "mcl_wool_lime",
	["purple"] = "wool_violet",
}

local canonical_color = "white"

for color,colordef in pairs(mcl_dyes.colors) do
	local create_entry = false
	local longdesc_carpet, longdesc_wool, name_carpet, name_wool

	local is_canonical = color == canonical_color
	if is_canonical then
		name_carpet = S("Carpet")
		name_wool = S("Wool")
		longdesc_wool = S("Wool is a decorative block which comes in many different colors.")
		longdesc_carpet = S("Carpets are thin floor covers which come in many different colors.")
		create_entry = true
	end
	local texcolor = "wool_"..color
	if messy_textures[color] then
		texcolor = messy_textures[color]
	end

	minetest.register_node("mcl_wool:"..color, {
		description = wool_descriptions[color],
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = name_wool,
		_doc_items_longdesc = longdesc_wool,
		is_ground_content = false,
		tiles = {texcolor..".png"},
		groups = {handy=1,shearsy_wool=1, flammable=1,fire_encouragement=30, fire_flammability=60, wool=1,building_block=1,["unicolor_"..color]=1},
		sounds = mcl_sounds.node_sound_wool_defaults(),
		_color = color,
		_mcl_hardness = 0.8,
		_mcl_blast_resistance = 0.8,
		_mcl_burntime = 5
	})
	minetest.register_node("mcl_wool:"..color.."_carpet", {
		description = carpet_descriptions[color],
		_doc_items_create_entry = create_entry,
		_doc_items_entry_name = name_carpet,
		_doc_items_longdesc = longdesc_carpet,
		is_ground_content = false,
		tiles = {texcolor..".png"},
		wield_image = texcolor..".png",
		wield_scale = { x=1, y=1, z=0.5 },
		groups = {handy=1, carpet=1,supported_node=1,flammable=1,fire_encouragement=60, fire_flammability=20, dig_by_water=1,deco_block=1,["unicolor_"..color]=1},
		sounds = mcl_sounds.node_sound_wool_defaults(),
		paramtype = "light",
		sunlight_propagates = true,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
			},
		},
		_color = color,
		_mcl_hardness = 0.1,
		_mcl_blast_resistance = 0.1,
		_mcl_burntime = 3.35
	})

	if mod_doc and not is_canonical then
		doc.add_entry_alias("nodes", "mcl_wool:"..canonical_color, "nodes", "mcl_wool:"..color)
		doc.add_entry_alias("nodes", "mcl_wool:"..canonical_color.."_carpet", "nodes", "mcl_wool:"..color.."_carpet")
	end

	minetest.register_craft({
		type = "shapeless",
		output = "mcl_wool:"..color,
		recipe = { "group:wool", "mcl_dyes:"..color }
	})

	minetest.register_craft({
		output = "mcl_wool:"..color.."_carpet 3",
		recipe = {{"mcl_wool:"..color, "mcl_wool:"..color}},
	})
end

minetest.register_craft({
	output = "mcl_wool:white",
	recipe = {
		{ "mcl_mobitems:string", "mcl_mobitems:string" },
		{ "mcl_mobitems:string", "mcl_mobitems:string" },
	},
})
