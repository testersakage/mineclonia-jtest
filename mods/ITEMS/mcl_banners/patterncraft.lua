local S = minetest.get_translator(minetest.get_current_modname())
local NS = function(s) return s end

-- Pattern crafting. This file contains the code for crafting all the
-- emblazonings you can put on the banners. It's quite complicated;
-- run-of-the-mill crafting won't work here.

-- Maximum number of layers which can be put on a banner by crafting.
local max_layers_crafting = 12

-- Max. number lines in the descriptions for the banner layers.
-- This is done to avoid huge tooltips.
local max_layer_lines = 6

local function populate_patterns () 
	-- List of patterns with crafting rules
	local d, e = "group:dye", ""
	mcl_banners.patterns = {
		["border"] = {
			name = NS("@1 Bordure"),
			{ d, d, d },
			{ d, e, d },
			{ d, d, d },
		},
		["bricks"] = {
			name = NS("@1 Bricks"),
			signature = "mcl_core:brick_block",
		},
		["circle"] = {
			name = NS("@1 Roundel"),
			{ e, e, e },
			{ e, d, e },
			{ e, e, e },
		},
		["creeper"] = {
			name = NS("@1 Creeper Charge"),
			signature = "mcl_heads:creeper",
		},
		["cross"] = {
			name = NS("@1 Saltire"),
			{ d, e, d },
			{ e, d, e },
			{ d, e, d },
		},
		["curly_border"] = {
			name = NS("@1 Bordure Indented"),
			signature = "mcl_core:vine",
		},
		["diagonal_up_left"] = {
			name = NS("@1 Per Bend Inverted"),
			{ e, e, e },
			{ d, e, e },
			{ d, d, e },
		},
		["diagonal_up_right"] = {
			name = NS("@1 Per Bend Sinister Inverted"),
			{ e, e, e },
			{ e, e, d },
			{ e, d, d },
		},
		["diagonal_right"] = {
			name = NS("@1 Per Bend"),
			{ e, d, d },
			{ e, e, d },
			{ e, e, e },
		},
		["diagonal_left"] = {
			name = NS("@1 Per Bend Sinister"),
			{ d, d, e },
			{ d, e, e },
			{ e, e, e },
		},
		["flower"] = {
			name = NS("@1 Flower Charge"),
			signature = "mcl_flowers:oxeye_daisy",
		},
		["gradient"] = {
			name = NS("@1 Gradient"),
			{ d, e, d },
			{ e, d, e },
			{ e, d, e },
		},
		["gradient_up"] = {
			name = NS("@1 Base Gradient"),
			{ e, d, e },
			{ e, d, e },
			{ d, e, d },
		},
		["half_horizontal_bottom"] = {
			name = NS("@1 Per Fess Inverted"),
			{ e, e, e },
			{ d, d, d },
			{ d, d, d },
		},
		["half_horizontal"] = {
			name = NS("@1 Per Fess"),
			{ d, d, d },
			{ d, d, d },
			{ e, e, e },
		},
		["half_vertical"] = {
			name = NS("@1 Per Pale"),
			{ d, d, e },
			{ d, d, e },
			{ d, d, e },
		},
		["half_vertical_right"] = {
			name = NS("@1 Per Pale Inverted"),
			{ e, d, d },
			{ e, d, d },
			{ e, d, d },
		},
		["thing"] = {
			-- Symbol used for the “Thing”: U+1F65D 🙝
			name = NS("@1 Thing Charge"),
			signature = "mcl_banners:pattern_thing",
		},
		["globe"] = {
			name = NS("@1 Globe Charge"),
			signature = "mcl_banners:pattern_globe",
		},
		["piglin"] = {
			name = NS("@1 Piglin Charge"),
			signature = "mcl_banners:pattern_piglin",
		},
		["rhombus"] = {
			name = NS("@1 Lozenge"),
			{ e, d, e },
			{ d, e, d },
			{ e, d, e },
		},
		["skull"] = {
			name = NS("@1 Skull Charge"),
			signature = "mcl_banners:pattern_skull",
		},
		["small_stripes"] = {
			name = NS("@1 Paly"),
			{ d, e, d },
			{ d, e, d },
			{ e, e, e },
		},
		["square_bottom_left"] = {
			name = NS("@1 Base Dexter Canton"),
			{ e, e, e },
			{ e, e, e },
			{ d, e, e },
		},
		["square_bottom_right"] = {
			name = NS("@1 Base Sinister Canton"),
			{ e, e, e },
			{ e, e, e },
			{ e, e, d },
		},
		["square_top_left"] = {
			name = NS("@1 Chief Dexter Canton"),
			{ d, e, e },
			{ e, e, e },
			{ e, e, e },
		},
		["square_top_right"] = {
			name = NS("@1 Chief Sinister Canton"),
			{ e, e, d },
			{ e, e, e },
			{ e, e, e },
		},
		["straight_cross"] = {
			name = NS("@1 Cross"),
			{ e, d, e },
			{ d, d, d },
			{ e, d, e },
		},
		["stripe_bottom"] = {
			name = NS("@1 Base"),
			{ e, e, e },
			{ e, e, e },
			{ d, d, d },
		},
		["stripe_center"] = {
			name = NS("@1 Pale"),
			{ e, d, e },
			{ e, d, e },
			{ e, d, e },
		},
		["stripe_downleft"] = {
			name = NS("@1 Bend Sinister"),
			{ e, e, d },
			{ e, d, e },
			{ d, e, e },
		},
		["stripe_downright"] = {
			name = NS("@1 Bend"),
			{ d, e, e },
			{ e, d, e },
			{ e, e, d },
		},
		["stripe_left"] = {
			name = NS("@1 Pale Dexter"),
			{ d, e, e },
			{ d, e, e },
			{ d, e, e },
		},
		["stripe_middle"] = {
			name = NS("@1 Fess"),
			{ e, e, e },
			{ d, d, d },
			{ e, e, e },
		},
		["stripe_right"] = {
			name = NS("@1 Pale Sinister"),
			{ e, e, d },
			{ e, e, d },
			{ e, e, d },
		},
		["stripe_top"] = {
			name = NS("@1 Chief"),
			{ d, d, d },
			{ e, e, e },
			{ e, e, e },
		},
		["triangle_bottom"] = {
			name = NS("@1 Chevron"),
			{ e, e, e },
			{ e, d, e },
			{ d, e, d },
		},
		["triangle_top"] = {
			name = NS("@1 Chevron Inverted"),
			{ d, e, d },
			{ e, d, e },
			{ e, e, e },
		},
		["triangles_bottom"] = {
			name = NS("@1 Base Indented"),
			{ e, e, e },
			{ d, e, d },
			{ e, d, e },
		},
		["triangles_top"] = {
			name = NS("@1 Chief Indented"),
			{ e, d, e },
			{ d, e, d },
			{ e, e, e },
		},
		["flow"] = {
			name = NS("@1 Flow"),
			signature = "mcl_banners:pattern_flow",
		},
		["guster"] = {
			name = NS("@1 Guster"),
			signature = "mcl_banners:pattern_guster",
		},
	}
end
populate_patterns()

local pattern_index = {} -- Index of patterns by ordered dye index or by special item name.
function mcl_banners.rebuild_index ()
	local dummy = "mcl_banners:banner_item_white" -- Dummy banner output.  Must be in the banner group.
	pattern_index = {}
	for pattern_id, pattern in pairs(mcl_banners.patterns) do
		local signature, current = pattern.signature
		if signature then
			if pattern_index[signature] then
				core.log("warning", "A banner pattern already exists for " .. signature)
			else
				pattern_index[signature] = {}
				current = pattern_index[signature]
				-- Register shapeless recipe.
				recipe = { "group:banner", "group:dye", signature }
				core.register_craft({ type = "shapeless", output = dummy, recipe = recipe })
			end
		else
			current = pattern_index
			local grids = { pattern[1][1], pattern[1][2], pattern[1][3],
			                pattern[2][1], pattern[2][2], pattern[2][3],
			                pattern[3][1], pattern[3][2], pattern[3][3], } -- Flattened to match craft callback
			for i = 1, 9 do
				local item = grids[i]
				if item == "group:dye" then
					-- Found dye, build index.
					if not current[i] then current[i] = {} end
					current = current[i]
				elseif item ~= "" then
					core.log("warning", "[mcl_banner] Shaped banner pattern can only have empty slots and dyes.  Found " .. item .. " in " .. pattern_id)
				end
			end
		end
		if current then
			current.id = pattern_id
			current.name = pattern.name
		end
	end

	-- Register dummy shapeless recipes for _shaped_ patterns, by dye count.
	local recipe = {}
	for i = 1, 8 do
		recipe[i] = "group:dye" -- Add one dye per loop.
		recipe[i+1] = "group:banner" -- The banner, will be overwritten by next loop.
		core.register_craft({ type = "shapeless", output = dummy, recipe = recipe })
	end
end
mcl_banners.rebuild_index()

local function readable_name(str)
	str = str:gsub("_", " ")
	return (str:gsub("^%l", string.upper))
end

function mcl_banners.register_pattern(name,recipe)
	patterns[name] = table.merge({ name = readable_name(name) }, recipe)
end

-- Just a simple reverse-lookup table from dye itemstring to banner color ID
-- to avoid some pointless future iterations.
local dye_to_colorid_mapping = {}
for colorid, colortab in pairs(mcl_banners.colors) do
	dye_to_colorid_mapping[colortab[5]] = colorid
end

local dye_to_itemid_mapping = {}
for _, colortab in pairs(mcl_banners.colors) do
	dye_to_itemid_mapping[colortab[5]] = colortab[1]
end

-- Create a banner description containing all the layer names
function mcl_banners.make_advanced_banner_description(description, layers)
	if layers == nil or #layers == 0 then
		-- No layers, revert to default
		return ""
	else
		local layerstrings = {}
		for l=1, #layers do
			-- Prevent excess length description
			if l > max_layer_lines then
				break
			end
			-- Layer text line.
			if mcl_banners.colors[layers[l]] then
				local color = mcl_banners.colors[layers[l].color][6]
				local pattern_name = patterns[layers[l].pattern].name
				table.insert(layerstrings, S(pattern_name, color))
			end
		end
		-- Warn about missing information
		if #layers == max_layer_lines + 1 then
			table.insert(layerstrings, S("And one additional layer"))
		elseif #layers > max_layer_lines + 1 then
			table.insert(layerstrings, S("And @1 additional layers", #layers - max_layer_lines))
		end

		-- Final string concatenations: Just a list of strings
		local append = table.concat(layerstrings, "\n")
		description = description .. "\n" .. minetest.colorize(mcl_colors.GRAY, append)
		return description
	end
end

function mcl_banners.parse_layers (meta)
	local raw = meta:get_string("layers")
	local layers = core.deserialize(raw)
	if type(layers) ~= "table" then return {}, "" end
	return layers, raw
end

-- Deduce whether the provided dye pattern is actually valid, and set output depending on predict or not.
local function banner_pattern_craft(itemstack, player, old_craft_grid, craft_inv, craft_predict)
	local output_name = itemstack:get_name()
	if output_name == "" or output_name:sub(1,19) ~= "mcl_banners:banner_" then return end
	--if core.get_item_group(itemstack:get_name(), "banner") ~= 1 then return end
	local craftsize = player:get_inventory():get_size("craft")
	if craftsize < 9 then return ItemStack("") end -- Require crafting table.

	-- Pattern Matching
	local banner -- banner item
	local banner2 -- second banner item (used when copying)
	local dye -- itemstring of the dye being used
	local pattern_obj -- itemstring of the pattern object being used
	local banner_index -- crafting inventory index of the banner
	local banner2_index
	local current = pattern_index -- Cursor on pattern index tree.
	for i = 1, craftsize do
		local itemname = old_craft_grid[i]:get_name()
		if itemname ~= "" then
			if core.get_item_group(itemname, "dye") == 1 then
				if current then
					current = current[i] -- Walk down the index.
					-- Don't check nil here.  First dye can match an item recipe, even if current = nil.
				elseif dye then
					return ItemStack("") -- No match, second dye or more.  Abort.
				end
				if dye and dye ~= itemname then return ItemStack("") end -- Mixing different dyes.
				dye = itemname
			elseif core.get_item_group(itemname, "banner") == 1 then
				if not banner then
					banner, banner_index = old_craft_grid[i], i
				else
					banner2, banner2_index = old_craft_grid[i], i
					break
				end
			else
				-- Enhancement: Support item group to enable adding such patterns by mods.
				pattern_obj = itemname
				if dye then break end
			end
		end
	end
	if pattern_obj then current = pattern_index[pattern_obj] end

	-- Banner Copy
	if banner2 then
		local b1name, b2name = banner:get_name(), banner2:get_name()
		if b1name ~= b2name then return ItemStack("") end -- Different base colours.

		local b1layers, b1_raw = mcl_banners.parse_layers(banner :get_meta())
		local b2layers, b2_raw = mcl_banners.parse_layers(banner2:get_meta())

		-- For copying to be allowed, one banner has to have no layers while the other one has at least 1 layer.
		-- The banner with layers will be used as a source.
		local src_banner, src_layers, src_layers_raw, src_desc, src_index
		if #b1layers == 0 and #b2layers > 0 then
			src_banner = banner2
			src_layers = b2layers
			src_layers_raw = b2_raw
			src_index = banner2_index
		elseif #b2layers == 0 and #b1layers > 0 then
			src_banner = banner
			src_layers = b1layers
			src_layers_raw = b1_raw
			src_index = banner_index
		else
			return ItemStack("") -- Both banners empty, or both has layers.
		end
		if #src_layers > max_layers_crafting then return ItemStack("") end -- Too many layers, e.g. code created banner.
		src_desc = core.registered_items[src_banner:get_name()].description

		-- Set output metadata.
		itemstack = ItemStack(b1name)
		local imeta = itemstack:get_meta()
		imeta:set_string("layers", src_layers_raw)
		-- Generate new description. This clears any (anvil) name from the original banners.
		imeta:set_string("description", mcl_banners.make_advanced_banner_description(src_desc, src_layers))

		if not craft_predict then -- Retain source banner, leaving output as true copy.
			craft_inv:set_stack("craft", src_index, src_banner)
		end
		return itemstack
	end

	-- Add new layer.
	if not current or not current.id then return ItemStack("") end -- No pattern found.
	-- Get old layers.
	local ometa = banner:get_meta()
	local layers = mcl_banners.parse_layers(ometa)
	if #layers >= max_layers_crafting then return ItemStack("") end -- Too many layers.

	if craft_predict then
		local color = dye_to_itemid_mapping[dye]
		return ItemStack("mcl_banners:banner_preview_" .. current.id .. "_" .. color)
	else
		-- Add new layer and copy or regen other metadata.
		local color = dye_to_colorid_mapping[dye]
		table.insert(layers, {pattern=current.id, color=color})

		itemstack = ItemStack(banner:get_name())
		local imeta = itemstack:get_meta()
		imeta:set_string("layers", core.serialize(layers))

		local mname = ometa:get_string("name")
		-- Change description if banner is nameless.
		if mname == "" then
			local odesc = itemstack:get_definition().description
			local description = mcl_banners.make_advanced_banner_description(odesc, layers)
			imeta:set_string("description", description)
		else
			imeta:set_string("description", ometa:get_string("description"))
			imeta:set_string("name", mname)
		end
		return itemstack
	end
end

core.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
	return banner_pattern_craft(itemstack, player, old_craft_grid, craft_inv, true)
end)
core.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	return banner_pattern_craft(itemstack, player, old_craft_grid, craft_inv, false)
end)

-- Recipe for banner copy.
core.register_craft({
	type = "shapeless",
	output = "mcl_banners:banner_item_white",
	recipe = { "group:banner", "group:banner" },
})