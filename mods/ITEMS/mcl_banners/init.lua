mcl_banners = {}
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local D = mcl_util.get_dynamic_translator(modname)

local node_sounds
if minetest.get_modpath("mcl_sounds") then
	node_sounds = mcl_sounds.node_sound_wood_defaults()
end
dofile(modpath.."/items.lua")

-- Max. number lines in the descriptions for the banner layers.
-- This is done to avoid huge tooltips.
local max_layer_lines = 6

-- Format:
-- mcl_banners.colors.unicolor_grey = {
--    banner_name = D("Grey Banner"),
--    color_key = "silver", -- used in banner, wool, and dye itemname
--    color_name = "Grey", -- English, for use by dynamic translation
--    rgb = "#818177",
-- }
mcl_banners.colors = {
	-- Backward compatibility with previously wrong unicolor color names.
	["unicolor_brown"] = { color_key = "brown" },
	["unicolor_pink"]  = { color_key = "pink"  },
	["unicolor_lime"]  = { color_key = "lime"  },
	-- Up to date dye colours are added below.
}

local function init_colors ()
	local dye_colors = mcl_dyes.colors
	for k,v in pairs(mcl_dyes.colors) do
		mcl_banners.colors["unicolor_" .. v.unicolor] = { color_key = k }
	end
	for _,v in pairs(mcl_banners.colors) do
		local dye_key = v.color_key -- Set above, "silver"
		local color = dye_colors[dye_key]
		v.color_name = color.readable_name -- "Grey"
		v.banner_name = D(color.readable_name .. " Banner") -- "Grey Banner"
		v.rgb = color.rgb -- "#d0d6d7"
	end
end
init_colors()

-- Helper functions
local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function mcl_banners.read_layers (meta)
	local raw = meta:get_string("layers")
	local layers = core.deserialize(raw)
	if type(layers) ~= "table" then return {}, "" end
	return layers, raw
end

function mcl_banners.write_layers (meta, layers)
	if type(layers) ~= "table" or #layers <= 0 then
		meta:set_string("layers", "")
	else
		meta:set_string("layers", core.serialize(layers))
	end
end

function mcl_banners.is_same_layers (A, B)
	if type(A) ~= type(B) or type(A) ~= "table" or #A ~= #B then return false end
	for i = 1, #A do
		if A[i].pattern ~= B[i].pattern or A[i].color ~= B[i].color then
			return false
		end
	end
	return true
end

-- Update banner description, returning description, name
function mcl_banners.update_description (itemstack)
	local meta = itemstack:get_meta()
	local name = meta:get_string("name")
	local layers = mcl_banners.read_layers(meta)
	if name ~= "" and name:find("Ominous Banner") then name = "" end -- Pre-0.84.0 Ominous Banners
	if name == "" then
		name = itemstack:get_definition().description
		if core.get_modpath("mcl_raids")
		and mcl_raids.is_banner_item(itemstack, layers) then
			local orig_name = mcl_banners.colors["unicolor_white"].banner_name
			name = name:gsub(orig_name:gsub("%W", "%%%1"), mcl_raids.ominous_banner_name)
		end
	else
		name = core.colorize(tt.NAME_COLOR, name)
	end
	local newdesc = mcl_banners.make_advanced_banner_description(name, layers)
	meta:set_string("description", newdesc)
	return newdesc, name
end

-- Create a banner description containing all the layer names
function mcl_banners.make_advanced_banner_description (name, layers)
	if layers == nil or #layers == 0 then return name end
	local layerstrings = {}
	for l=1, math.min(#layers, max_layer_lines) do
		local layer = layers[l] -- {pattern="border", color="white"}
		local colour_tab = layer and mcl_banners.colors[layer.color or ""]
		if colour_tab then
			local pattern_name = mcl_banners.patterns[layer.pattern].name
			table.insert(layerstrings, S(pattern_name, colour_tab.color_name))
		end
	end
	if #layers == max_layer_lines + 1 then
		table.insert(layerstrings, S("And one additional layer"))
	elseif #layers > max_layer_lines + 1 then
		table.insert(layerstrings, S("And @1 additional layers", #layers - max_layer_lines))
	end

	-- Final string concatenations: Just a list of strings
	local append = table.concat(layerstrings, "\n")
	return name .. "\n" .. core.colorize(mcl_colors.GRAY, append)
end

-- Add pattern/emblazoning crafting recipes
dofile(modpath.."/patterncraft.lua")

-- Overlay ratios (0-255)
local base_color_ratio = 224

local standing_banner_entity_offset = { x=0, y=-0.499, z=0 }
local hanging_banner_entity_offset = { x=0, y=-1.7, z=0 }

local function rotation_level_to_yaw(rotation_level)
	return (rotation_level * (math.pi/8)) + math.pi
end

local function on_dig_banner(pos, _, digger)
	-- Check protection
	local name = digger:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return
	end

	local inv = minetest.get_meta(pos):get_inventory()
	local item = inv:get_stack("banner", 1)
	tt.reload_itemstack_description(item) -- Update description of pre-0.111 banners.
	local item_str = item:is_empty() and "mcl_banners:banner_item_white" or item:to_string()

	minetest.handle_node_drops(pos, { item_str }, digger)

	item:set_count(0)
	inv:set_stack("banner", 1, item)

	-- Remove node
	minetest.remove_node(pos)
end

local function on_destruct_banner(pos, hanging)
	local offset, nodename
	if hanging then
		offset = hanging_banner_entity_offset
		nodename = "mcl_banners:hanging_banner"
	else
		offset = standing_banner_entity_offset
		nodename = "mcl_banners:standing_banner"
	end
	-- Find this node's banner entity and remove it
	local checkpos = vector.add(pos, offset)
	for v in minetest.objects_inside_radius(checkpos, 0.5) do
		local ent = v:get_luaentity()
		if ent and ent.name == nodename then
			v:remove()
			break
		end
	end

	-- Drop item only if it was not handled in on_dig_banner
	local inv = minetest.get_meta(pos):get_inventory()
	local item = inv:get_stack("banner", 1)
	if not item:is_empty() then
		minetest.handle_node_drops(pos, {item:to_string()})
	end
end

local function on_destruct_standing_banner(pos)
	return on_destruct_banner(pos, false)
end

local function on_destruct_hanging_banner(pos)
	return on_destruct_banner(pos, true)
end

function mcl_banners.make_banner_texture(base_color, layers)
	local colorize
	if mcl_banners.colors[base_color] then
		colorize = mcl_banners.colors[base_color].rgb
	end
	if not colorize then return "mcl_banners_banner_base.png" end
	-- Base texture with base color
	local result = "(mcl_banners_banner_base.png^[mask:mcl_banners_base_inverted.png)^((mcl_banners_banner_base.png^[colorize:"..colorize..":"..base_color_ratio..")^[mask:mcl_banners_base.png)"
	if not layers then return result end

	-- Optional pattern layers
	for l=1, #layers do
		local layerinfo = layers[l]
		if layerinfo and layerinfo.pattern and layerinfo.color and mcl_banners.colors[layerinfo.color] then
			local pattern = "mcl_banners_" .. layerinfo.pattern .. ".png"
			local color = mcl_banners.colors[layerinfo.color].rgb

			-- Generate layer texture
			local layer = "(("..pattern.."^[colorize:"..color..":255)^[mask:"..pattern..")"

			result = result .. "^" .. layer
		end
	end
	return result
end

local function spawn_banner_entity(pos, hanging, itemstack)
	local banner = core.add_entity(pos, hanging and "mcl_banners:hanging_banner" or "mcl_banners:standing_banner")
	if banner == nil then return banner end

	local imeta = itemstack:get_meta()
	local desc, name = mcl_banners.update_description(itemstack)
	local layers = mcl_banners.read_layers(imeta)
	local colorid = itemstack:get_definition()._unicolor
	banner:get_luaentity():_set_textures(colorid, layers)
	banner:get_luaentity()._item_name = name
	banner:get_luaentity()._item_description = desc
	return banner
end

local function respawn_banner_entity(pos, node, force)
	local is_hanging = node.name == "mcl_banners:hanging_banner"
	local offset = is_hanging and hanging_banner_entity_offset or standing_banner_entity_offset
	local bpos = vector.add(pos, offset)
	for v in minetest.objects_inside_radius(bpos, 0.5) do
		local ent = v:get_luaentity()
		if ent and (ent.name == "mcl_banners:standing_banner" or ent.name == "mcl_banners:hanging_banner") then
			if not force then return end -- Banner exists, not forcing removal, just quit.
			v:remove()
		end
	end

	-- Spawn new entity and set rotation
	local meta = minetest.get_meta(pos)
	local banner_item = meta:get_inventory():get_stack("banner", 1)
	local banner_entity = spawn_banner_entity(bpos, is_hanging, banner_item)
	local rotation_level = meta:get_int("rotation_level")
	local final_yaw = rotation_level_to_yaw(rotation_level)
	if banner_entity then
		banner_entity:set_yaw(final_yaw)
	end
end

local function get_banner_stack(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	return inv:get_stack("banner", 1)
end

-- Banner nodes.
-- These are an invisible nodes which are only used to destroy the banner entity.
-- All the important banner information (such as color) is stored in the entity.
-- It is used only used internally.

-- Standing banner node
-- This one is also used for the help entry to avoid spamming the help with 16 entries.
minetest.register_node("mcl_banners:standing_banner", {
	_doc_items_entry_name = S("Banner"),
	_doc_items_image = "mcl_banners_item_base_48.png^mcl_banners_item_overlay_48.png",
	_doc_items_longdesc = S("Banners are tall colorful decorative blocks. They can be placed on the floor and at walls. Banners can be emblazoned with a variety of patterns by placing it with a dye in the loom, or with lots of dyes in crafting table."),
	_doc_items_usagehelp = S("Emblazoned banners can be emblazoned again to combine patterns. Up to 12 patterns can be layered on a banner. To wash off a banner's top-most layer, using it on a cauldron with water .").."\n"..
		S("An emblazoned banner can be copied by placing two banners of the same base color in the crafting grid — one needs to be emblazoned, the other one must be clean."),
	walkable = false,
	is_ground_content = false,
	paramtype = "light",
	sunlight_propagates = true,
	drawtype = "nodebox",
	-- Nodebox is drawn as fallback when the entity is missing, so that the
	-- banner node is never truly invisible.
	-- If the entity is drawn, the nodebox disappears within the real banner mesh.
	node_box = {
		type = "fixed",
		fixed = { -1/32, -0.49, -1/32, 1/32, 1.49, 1/32 },
	},
	-- This texture is based on the banner base texture
	tiles = { "mcl_banners_fallback_wood.png" },

	inventory_image = "mcl_banners_item_base_48.png",
	wield_image = "mcl_banners_item_base_48.png",

	selection_box = {type = "fixed", fixed= {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3} },
	groups = {axey=1,handy=1, attached_node = 1, not_in_creative_inventory = 1, banner = 1, not_in_craft_guide = 1, material_wood=1, dig_by_piston=1, flammable=-1, unmovable_by_piston = 1},
	stack_max = 16,
	sounds = node_sounds,
	drop = "", -- Item drops are handled in entity code

	on_dig = on_dig_banner,
	on_destruct = on_destruct_standing_banner,
	on_punch = function(pos, node)
		respawn_banner_entity(pos, node)
	end,
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	_mcl_baseitem = get_banner_stack,
	on_rotate = function(pos, node, _, mode)
		if mode == screwdriver.ROTATE_FACE then
			local meta = minetest.get_meta(pos)
			local rot = meta:get_int("rotation_level")
			rot = (rot - 1) % 16
			meta:set_int("rotation_level", rot)
			respawn_banner_entity(pos, node, true)
			return true
		else
			return false
		end
	end,
})

local screwdriver_rot_by_param2 = { 0, 12, 4, 0, 8 }

-- Hanging banner node
minetest.register_node("mcl_banners:hanging_banner", {
	walkable = false,
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	drawtype = "nodebox",
	inventory_image = "mcl_banners_item_base_48.png",
	wield_image = "mcl_banners_item_base_48.png",
	tiles = { "mcl_banners_fallback_wood.png" },
	node_box = {
		type = "wallmounted",
		wall_side = { -0.49, 0.41, -0.49, -0.41, 0.49, 0.49 },
		wall_top = { -0.49, 0.41, -0.49, -0.41, 0.49, 0.49 },
		wall_bottom = { -0.49, -0.49, -0.49, -0.41, -0.41, 0.49 },
	},
	selection_box = {type = "wallmounted", wall_side = {-0.5, -0.5, -0.5, -4/16, 0.5, 0.5} },
	groups = {axey=1,handy=1, attached_node = 1, not_in_creative_inventory = 1, banner = 1, not_in_craft_guide = 1, material_wood=1, flammable=-1, unmovable_by_piston = 1},
	stack_max = 16,
	sounds = node_sounds,
	drop = "", -- Item drops are handled in entity code

	on_dig = on_dig_banner,
	on_destruct = on_destruct_hanging_banner,
	on_punch = respawn_banner_entity,
	_mcl_hardness = 1,
	_mcl_blast_resistance = 1,
	_mcl_baseitem = get_banner_stack,
	on_rotate = function(pos, node, _, mode)
		if mode ~= screwdriver.ROTATE_FACE then return false end
		local r = screwdriver.rotate.wallmounted(pos, node, mode)
		node.param2 = r
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		local rot = screwdriver_rot_by_param2[ r or 0 ] or 0
		meta:set_int("rotation_level", rot)
		respawn_banner_entity(pos, node, true)
		return true
	end,
})

local function init_banner_registration ()
	local mod_wool = core.get_modpath("mcl_core") and core.get_modpath("mcl_wool")
	local mod_doc = minetest.get_modpath("doc")
	local patterns = mcl_banners.patterns
	patterns[""] = {}
	for uni_key, colortab in pairs(mcl_banners.colors) do
		local color_id = colortab.color_key
		for pattern_id, _ in pairs(patterns) do
			local desc = colortab.banner_name
			local color = colortab.rgb

			local recipe = patterns[pattern_id]
			if recipe and recipe.name then
				desc = S(recipe.name, colortab.color_name)
			end

			local itemstring
			if pattern_id == "" then
				itemstring = "mcl_banners:banner_item_" .. color_id
			else
				itemstring = "mcl_banners:banner_preview_" .. pattern_id .. "_" .. color_id
			end

			local item_texture
			if pattern_id == "" then
				-- Base texture with base color
				item_texture = "mcl_banners_item_base_48.png^(mcl_banners_item_overlay_48.png^[colorize:"..color..")"
			else
				-- Banner item preview background
				local base = "mcl_banners_item_base_48.png^(mcl_banners_item_overlay_48.png^[colorize:#CCCCCC)^[resize:48x48"
				local pattern = "mcl_banners_" .. pattern_id .. ".png"
				-- Pattern Texture size 64x64, Front at offset 1,1 size 20x40.  Item texture 48x48 offset 14,4.
				local layer = "[combine:20x40:-1,-1=\\("..pattern.."\\^[resize\\:64x64\\)^[colorize:"..color..":255"

				function escape(text)
					return text:gsub("%^", "\\%^"):gsub(":", "\\:") -- :gsub("%(", "\\%("):gsub("%)", "\\%)")
				end

				item_texture = "[combine:48x48:0,0=" .. escape(base) .. ":14,4=" .. escape(layer)
			end

			-- Banner items.
			-- This is the player-visible banner item. It comes in 16 base colors with a lot of patterns.
			-- The multiple items are really only needed for the different item images.
			-- TODO: Combine the items into only 1 item.
			local groups
			if pattern_id == "" then
				groups = { banner = 1, deco_block = 1, flammable = -1 }
			else
				groups = { not_in_creative_inventory = 1 }
			end

			minetest.register_craftitem(itemstring, {
				description = desc,
				_tt_help = S("Paintable decoration"),
				_doc_items_create_entry = false,
				inventory_image = item_texture,
				wield_image = item_texture,
				-- Banner group groups together the banner items, but not the nodes.
				-- Used for crafting.
				groups = groups,
				stack_max = 16,
				_mcl_burntime = 15,
				_unicolor = uni_key,
				on_place = function(itemstack, placer, pointed_thing)
					local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
					if rc then return rc end
					local above = pointed_thing.above
					local under = pointed_thing.under

					local node_under = minetest.get_node(under)
					if placer and not placer:get_player_control().sneak then
						if mcl_util.check_position_protection(under, placer) then return itemstack end

						if minetest.get_item_group(node_under.name, "cauldron_water") > 0 then
							if mcl_cauldrons.add_level(pointed_thing.under, -1) then
								local imeta = itemstack:get_meta()
								local layers = mcl_banners.read_layers(imeta)
								if #layers > 0 then
									table.remove(layers)
									mcl_banners.write_layers(imeta, layers)
									tt.reload_itemstack_description(itemstack)
								end
								return itemstack
							end
						end
					end

					-- Place the node!
					local is_hanging = false

					-- Standing or hanging banner. The placement rules are enforced by the node definitions
					local _, success = minetest.item_place_node(ItemStack("mcl_banners:standing_banner"), placer, pointed_thing)
					if not success then
						-- Forbidden on ceiling
						if pointed_thing.under.y ~= pointed_thing.above.y then
							return itemstack
						end
						_, success = minetest.item_place_node(ItemStack("mcl_banners:hanging_banner"), placer, pointed_thing)
						if not success then
							return itemstack
						end
						is_hanging = true
					end
					local place_pos
					local def_under = minetest.registered_nodes[node_under.name]
					if def_under and def_under.buildable_to then
						place_pos = under
					else
						place_pos = above
					end
					local bnode = minetest.get_node(place_pos)
					if bnode.name ~= "mcl_banners:standing_banner" and bnode.name ~= "mcl_banners:hanging_banner" then
						minetest.log("error", "[mcl_banners] The placed banner node is not what the mod expected!")
						return itemstack
					end
					local meta = minetest.get_meta(place_pos)
					local inv = meta:get_inventory()
					inv:set_size("banner", 1)
					local store_stack = ItemStack(itemstack)
					store_stack:set_count(1)
					inv:set_stack("banner", 1, store_stack)

					-- Spawn entity
					local entity_place_pos
					local offset = is_hanging and hanging_banner_entity_offset or standing_banner_entity_offset
					entity_place_pos = vector.add(place_pos, offset)
					local banner_entity = spawn_banner_entity(entity_place_pos, is_hanging, itemstack)
					local name = itemstack:get_meta():get_string("name")
					if name ~= "" then
						meta:set_string("infotext", name)
					end
					-- Set rotation
					local final_yaw, rotation_level
					if is_hanging then
						local pdir = vector.direction(pointed_thing.under, pointed_thing.above)
						final_yaw = minetest.dir_to_yaw(pdir)
						if pdir.x > 0 then
							rotation_level = 4
						elseif pdir.z > 0 then
							rotation_level = 8
						elseif pdir.x < 0 then
							rotation_level = 12
						else
							rotation_level = 0
						end
					else
						-- Determine the rotation based on player's yaw
						local yaw = placer:get_look_horizontal()
						-- Select one of 16 possible rotations (0-15)
						rotation_level = round((yaw / (math.pi*2)) * 16)
						if rotation_level >= 16 then
							rotation_level = 0
						end
						final_yaw = rotation_level_to_yaw(rotation_level)
					end
					meta:set_int("rotation_level", rotation_level)

					if banner_entity then
						banner_entity:set_yaw(final_yaw)
					end

					if not minetest.is_creative_enabled(placer:get_player_name()) then
						itemstack:take_item()
					end
					minetest.sound_play({name="default_place_node_hard", gain=1.0}, {pos = place_pos}, true)

					return itemstack
				end,

				_mcl_generate_description = mcl_banners.update_description,
			})

			if mod_wool and pattern_id == "" then
				local wool = "mcl_wool:" .. color_id
				core.register_craft({
					output = itemstring,
					recipe = {
						{ wool, wool, wool },
						{ wool, wool, wool },
						{ "", "mcl_core:stick", "" },
					}
				})
			end

			if mod_doc then
				doc.add_entry_alias("nodes", "mcl_banners:standing_banner", "craftitems", itemstring)
			end
		end
	end
	
	if mod_doc then
		doc.add_entry_alias("nodes", "mcl_banners:standing_banner", "nodes", "mcl_banners:hanging_banner")
	end
end
init_banner_registration()


-- Banner entities.
local entity_standing = {
	initial_properties = {
		physical = false,
		collide_with_objects = false,
		visual = "mesh",
		mesh = "amc_banner.b3d",
		visual_size = { x=2.499, y=2.499 },
		textures = {mcl_banners.make_banner_texture()},
		pointable = false,
	},

	_base_color = nil, -- base color of banner
	_layers = nil, -- table of layers painted over the base color.
		-- This is a table of tables with each table having the following fields:
			-- color: layer color ID (see colors table above)
			-- pattern: name of pattern (see list above)

	get_staticdata = function(self)
		local out = { _base_color = self._base_color, _layers = self._layers, _name = self._name }
		return minetest.serialize(out)
	end,
	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
			local inp = minetest.deserialize(staticdata)
			self._base_color = inp._base_color
			self._layers = inp._layers
			self._name = inp._name
			self.object:set_properties({
				textures = {mcl_banners.make_banner_texture(self._base_color, self._layers)},
			})
		end
		-- Make banner slowly swing
		self.object:set_animation({x=0, y=80}, 25)
		self.object:set_armor_groups({immortal=1})
	end,

	-- Set the banner textures. This function can be used by external mods.
	-- Meaning of parameters:
	-- * self: Lua entity reference to entity.
	-- * other parameters: Same meaning as in mcl_banners.make_banner_texture
	_set_textures = function(self, base_color, layers)
		if base_color then
			self._base_color = base_color
		end
		if layers then
			self._layers = layers
		end
		self.object:set_properties({textures = {mcl_banners.make_banner_texture(self._base_color, self._layers)}})
	end,
	_mcl_pistons_unmovable = true
}
minetest.register_entity("mcl_banners:standing_banner", entity_standing)

local entity_hanging = table.copy(entity_standing)
entity_hanging.initial_properties.mesh = "amc_banner_hanging.b3d"
minetest.register_entity("mcl_banners:hanging_banner", entity_hanging)

-- FIXME: Prevent entity destruction by /clearobjects
minetest.register_lbm({
	label = "Respawn banner entities",
	name = "mcl_banners:respawn_entities",
	run_at_every_load = true,
	nodenames = {"mcl_banners:standing_banner", "mcl_banners:hanging_banner"},
	action = function(pos, node)
		respawn_banner_entity(pos, node)
	end,
})