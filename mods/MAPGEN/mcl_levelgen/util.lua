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

local function iter_nil ()
	return nil, nil, nil
end

local function make_ipos_iterator ()
	local x1
	local y1, iy
	local z1, iz
	local x2
	local y2
	local z2

	local function ipos_iterate ()
		local x, y, z = nil, nil, nil
		if iz < z2 then
			iz = iz + 1
			z = iz
			y = iy
			x = x1
		elseif iy < y2 then
			iy = iy + 1
			iz = z1
			z = iz
			y = iy
			x = x1
		elseif x1 < x2 then
			x1 = x1 + 1
			iz = z1
			iy = y1
			z = iz
			y = iy
			x = x1
		end
		return x, y, z
	end

	return function (ix1, iy1, iz1, ix2, iy2, iz2)
		if ix1 > ix2 or iy1 > iy2 or iz1 > iz2 then
			return iter_nil
		end
		x1, x2, y1, y2, z1, z2 = ix1, ix2, iy1, iy2, iz1, iz2
		iy, iz = y1, z1 - 1
		return ipos_iterate
	end
end

mcl_levelgen.make_ipos_iterator = make_ipos_iterator

-- Note: ipos1 and ipos2 are reserved for the level generator, and if
-- there is any potential for a function that invokes ipos3 to be
-- invoked while it is in use, consider creating your own iterator
-- (outside any hot code for performance) with `make_ipos_iterator',
-- or introduce a new `ipos4' here.

mcl_levelgen.ipos1 = make_ipos_iterator ()
mcl_levelgen.ipos2 = make_ipos_iterator ()
mcl_levelgen.ipos3 = make_ipos_iterator ()

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
