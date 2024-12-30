local modname			   = minetest.get_current_modname()
local mod_registername	  = modname .. ":"
local S					 = minetest.get_translator(modname)
local C                 = minetest.colorize

local function readable_name(str)
	str = str:gsub("_", " ")
    return (str:gsub("^%l", string.upper))
end

for template_name, template_defs in pairs(mcl_armor.trims.overlays) do
	minetest.register_craftitem(mod_registername .. template_name, {
		description = S("@1 Armor Trim", S(readable_name(template_name))),
		_tt_help = S("Smithing Template").."\n\n"..
		C(mcl_colors.GRAY, S("Applies to:")).."\n"..C(mcl_colors.BLUE, " "..S("Armor")).."\n"..
		C(mcl_colors.GRAY, S("Ingredients:")).."\n"..C(mcl_colors.BLUE, " "..S("Ingot & Crystals")),
		inventory_image  = template_name .. "_armor_trim_smithing_template.png",
		groups = { smithing_template = 1, rarity = template_defs.rarity or 1 },
	})

	if template_defs.dupe_item then
		minetest.register_craft({
			output = mod_registername .. template_name .. " 2",
			recipe = {
				{ "mcl_core:diamond", mod_registername .. template_name, "mcl_core:diamond" },
				{ "mcl_core:diamond", template_defs.dupe_item, "mcl_core:diamond" },
				{ "mcl_core:diamond", "mcl_core:diamond", "mcl_core:diamond" },
			}
		})
	end
end
