-- Made for MineClone 2 by Michieal.
-- Texture made by Michieal; The model borrows the top from NathanS21's (Nathan Salapat) Lectern model; The rest of the
-- lectern model was created by Michieal.
-- lectern GUI code by cora

local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape

local function get_formspec(text, title, author)
	return "size[8,9]" ..
	"no_prepend[]" .. mcl_vars.gui_nonbg .. mcl_vars.gui_bg_color ..
	"style_type[button;border=false;bgimg=mcl_books_button9.png;bgimg_pressed=mcl_books_button9_pressed.png;bgimg_middle=2,2]" ..
	"background[-0.5,-0.5;9,10;mcl_books_book_bg.png]" ..
	"hypertext[0,0.3;8,0.7;title;<style color=black font=normal size=24><center>"..F(title or "").."</center></style>]"..
	"hypertext[0.75,0.8;7.25,0.5;author;<style color=black font=normal size=12>by </style><style color=#1E1E1E font=mono size=14>"..F(author or "").."</style>]"..
	"textarea[0.75,1.24;7.20,7.5;;" .. F(text or "") .. ";]" ..
	"button_exit[1.25,7.95;3,1;ok;" .. F(S("Done")) .. "]"..
	"button[4.25,7.95;3,1;take;" .. F(S("Take Book")) .. "]"
end

local S = minetest.get_translator(minetest.get_current_modname())

local lectern_tpl = {
	description = S("Lectern"),
	_tt_help = S("Lecterns not only look good, but are job site blocks for Librarians."),
	_doc_items_longdesc = S("Lecterns not only look good, but are job site blocks for Librarians."),
	_doc_items_usagehelp = S("Place the Lectern on a solid node for best results. May attract villagers, so it's best to place outside of where you call 'home'."),
	sounds = mcl_sounds.node_sound_wood_defaults(),
	paramtype = "light",
	use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
	paramtype2 = "facedir",
	drawtype = "mesh",
	mesh = "mcl_lectern_lectern.obj",
	tiles = {"mcl_lectern_lectern.png", },
	drop = "mcl_lectern:lectern",
	groups = {handy = 1, axey = 1, flammable = 2, fire_encouragement = 5, fire_flammability = 5, solid = 1, deco_block=1, lectern = 1},
	sunlight_propagates = true,
	is_ground_content = false,
	node_placement_prediction = "",
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
	_mcl_burntime = 15,
	selection_box = {
		type = "fixed",
		fixed = {
			--   L,    T,    Ba,    R,    Bo,    F.
			{-0.32, 0.46, -0.32, 0.32, 0.175, 0.32},
			{-0.18, 0.175, -0.055, 0.18, -0.37, 0.21},
			{-0.32, -0.37, -0.32, 0.32, -0.5, 0.32},
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			--   L,    T,    Ba,    R,    Bo,    F.
			{-0.32, 0.46, -0.32, 0.32, 0.175, 0.32},
			{-0.18, 0.175, -0.055, 0.18, -0.37, 0.21},
			{-0.32, -0.37, -0.32, 0.32, -0.5, 0.32},
		}
	},

	on_place = function(itemstack, placer, pointed_thing)

		if not placer or not placer:is_player() then
			return itemstack
		end

		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		if minetest.is_protected(pointed_thing.above, placer:get_player_name()) then
			minetest.record_protection_violation(pointed_thing.above, placer:get_player_name())
			return
		end

		if minetest.dir_to_wallmounted(vector.subtract(pointed_thing.under,  pointed_thing.above)) == 1 then
			local _, success = minetest.item_place_node(itemstack, placer, pointed_thing, minetest.dir_to_facedir(vector.direction(placer:get_pos(),pointed_thing.above)))
			if not success then
				return
			end
			minetest.sound_play(mcl_sounds.node_sound_wood_defaults().place, {pos=pointed_thing.above, gain=1}, true)
		end
		return itemstack
	end,
}

minetest.register_node("mcl_lectern:lectern", table.merge(lectern_tpl,{
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if itemstack:get_name() == "mcl_books:written_book" then
			local player_name = clicker:get_player_name()
			if minetest.is_protected(pos, player_name) then
				minetest.record_protection_violation(pos, player_name)
				return
			end
			local im = itemstack:get_meta()
			local nm = minetest.get_meta(pos)
			node.name = "mcl_lectern:lectern_with_book"
			minetest.swap_node(pos,node)
			nm:set_string("formspec",get_formspec(im:get_string("text"),im:get_string("title"),im:get_string("author")))
			nm:set_string("bookmeta",minetest.serialize(im:to_table()))
			if not minetest.is_creative_enabled(player_name) then
				itemstack:take_item()
			end
			return itemstack
		end
	end
}))

local function create_book(bookmeta)
	local is = ItemStack("mcl_books:written_book")
	is:get_meta():from_table(minetest.deserialize(bookmeta))
	return is:to_string()
end

minetest.register_node("mcl_lectern:lectern_with_book", table.merge( lectern_tpl,{
	groups = table.merge(lectern_tpl.groups, {not_in_creative_inventory = 1}),
	tiles = {"mcl_lectern_lectern_with_book.png", },
	on_receive_fields = function(pos, formname, fields, sender)
		local sender_name = sender:get_player_name()
		if minetest.is_protected(pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		end
		if fields and fields.take then
			local inv = sender:get_inventory()
			local node = minetest.get_node(pos)
			local nm = minetest.get_meta(pos)
			local vid = nm:get_string("villager")
			inv:add_item("main",create_book(nm:get_string("bookmeta")))
			node.name = "mcl_lectern:lectern"
			minetest.set_node(pos,node) --set node and reset of villager id on purpose because formspec field won't reset manually
			nm:set_string("villager",vid)
		end
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local is = create_book(oldmetadata.fields.bookmeta)
		minetest.add_item(pos,is)
	end,
}))

mcl_wip.register_wip_item("mcl_lectern:lectern")

-- April Fools setup
local date = os.date("*t")
if (date.month == 4 and date.day == 1) then
	minetest.override_item("mcl_lectern:lectern", {waving = 2})
end

minetest.register_craft({
	output = "mcl_lectern:lectern",
	recipe = {
		{"group:wood_slab", "group:wood_slab", "group:wood_slab"},
		{"", "mcl_books:bookshelf", ""},
		{"", "group:wood_slab", ""},
	}
})
