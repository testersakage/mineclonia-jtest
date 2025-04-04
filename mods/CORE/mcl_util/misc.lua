function mcl_util.file_exists(name)
	if type(name) ~= "string" then return end
	local f = io.open(name)
	if not f then
		return false
	end
	f:close()
	return true
end

function mcl_util.get_color(colorstr)
	local mc_color = mcl_colors[colorstr:upper()]
	if mc_color then
		colorstr = mc_color
	elseif #colorstr ~= 7 or colorstr:sub(1, 1) ~= "#" then
		return
	end
	local hex = tonumber(colorstr:sub(2, 7), 16)
	if hex then
		return colorstr, hex
	end
end

-- Create a translator that supports dynamic generation of translatable strings.
--
-- The function returned by `get_dynamic_translator` can be used just like the
-- standard translator created by `minetest.get_translator`. The recommended
-- name is `D`, but - in contrast to the standard translator - the name used in
-- the source files is not important.
--
-- While the standard translation tools extract string constants from the source
-- files themselves, the extended translation workflow records all values passed
-- to the dynamic translator *during mod load time*.
--
-- The extended workflow includes the standard tooling and both can be used
-- together in the same mod. If a textdomain is not specified when creating the
-- dynamic translator, `minetest.get_current_modname()` is used as the
-- textdomain for that particular invocation. So API mods using this mechanism
-- can create translatable strings in the textdomain of their calling mods.
if minetest.get_modpath("mcla_generate_translation_strings") then
	mcla_generated_translations = {}
	function mcl_util.get_dynamic_translator(textdomain)
		local mod = textdomain or minetest.get_current_modname()
		return function(s, ...)
			mcla_generated_translations[mod] = mcla_generated_translations[mod] or {}
			mcla_generated_translations[mod][s] = true
			return minetest.translate(mod, s, ...)
		end
	end
else
	function mcl_util.get_dynamic_translator(textdomain)
		local mod = textdomain or minetest.get_current_modname()
		return function(s, ...)
			return minetest.translate(mod, s, ...)
		end
	end
end

local rng = PcgRandom (os.time())

function mcl_util.dist_triangular(base, magnitude)
	local r = 1 / 2147483647
	local dist = (rng:next(0, 2147483647) * r - rng:next(0, 2147483647) * r)
	return base + magnitude * dist
end

function mcl_util.float_random(from, to)
	to = to or 1
	return from + (math.random() * (to - from))
end

local function round_trunc(x)
	return math.floor(x + 0.5)
end

function mcl_util.get_nodepos(pos)
	return vector.apply(pos, round_trunc)
end

function mcl_util.norm_radians (x)
	local x = x % (math.pi * 2)
	if x >= math.pi then
		x = x - math.pi * 2
	end
	if x < -math.pi then
		x = x + math.pi * 2
	end
	return x
end

function mcl_util.calculate_knockback (velocity, factor, resistance, standing, x, z)
	local factor = factor * (1.0 - math.min (1.0, resistance))
	if factor <= 1.0e-5 then
		return vector.zero()
	end
	local v = vector.normalize(vector.new(x, 0, z)) * factor

	-- Counterbalance it with a reduced version of the current
	-- velocity.
	v.x = (velocity.x / 2 + (v.x * 20)) * 0.546
	v.z = (velocity.z / 2 + (v.z * 20)) * 0.546
	-- Apply vertical force if standing
	v.y = standing and (math.min (0.4 * 20, velocity.y / 2.0 + factor * 10)) or velocity.y
	return v
end
