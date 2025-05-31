------------------------------------------------------------------------
-- Simple utility functions.
------------------------------------------------------------------------

function mcl_levelgen.fisher_yates (tbl, rng)
	for i = #tbl, 2, -1 do
		local j = 1 + rng:next_within (i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

if core then

------------------------------------------------------------------------
-- Minetest-specific utilities.
------------------------------------------------------------------------

local OVERWORLD_MIN_MINECRAFT = -64
local OVERWORLD_OFFSET = OVERWORLD_MIN_MINECRAFT - mcl_vars.mg_overworld_min
mcl_levelgen.OVERWORLD_OFFSET = OVERWORLD_OFFSET

-- Convert from Minetest to Minecraft positions and vice versa.
function mcl_levelgen.conv_pos (v)
	-- Minecraft's Z axis is inverted such that North is -Z.
	--
	-- This function converts a Minetest position to the
	-- equivalent that is considered by the level generator.  As
	-- it is imperative for performance that level generator
	-- chunks should be aligned with Minetest MapBlocks, Minetest
	-- positions are further offset along the Z axis by a delta of
	-- -1.
	return vector.new (v.x, v.y + OVERWORLD_OFFSET, -v.z - 1)
end

end
