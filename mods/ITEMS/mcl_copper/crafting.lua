
local waxable_blocks = { "block", "block_cut", "block_exposed", "block_exposed_cut", "block_weathered", "block_weathered_cut", "block_oxidized", "block_oxidized_cut" }

for _, w in ipairs(waxable_blocks) do
	minetest.register_craft({
		output = "mcl_copper:"..w.."_preserved",
		recipe = {
			{ "mcl_copper:"..w, "mcl_honey:honeycomb" },
		},
	})
end
