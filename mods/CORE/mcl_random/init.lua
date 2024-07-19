-- Minetest and LUA provide several sources of randomness, each having its own
-- limitations
--
-- math.random is a global resource that might be spoofable in multiplayer
-- scenarios.
--
-- PseudoRandom supports seeds in the range -32768..32767, but negative numbers
-- may not work correctly when passed from LUA on all platforms. It also has
-- rather bad randomness properties and is slower than PcgRandom which provides
-- the same (for Mineclonia's purposes) interface. It's not a good choice for
-- new worlds, but necessary for reproducability in existing worlds.
--
-- PcgRandom supports seeds in the range 0..2^64-1, but when passing numbers
-- through LUA about 8 bits will get lost, because the float representation has
-- 53 significant bits, making most numbers between 2^53 and 2^64
-- unrepresentable. Minetest 5.9 provides another option of initializing a
-- PcgRandom instance which allows passing a full 64 bit seed. PcgRandom is a
-- good choice for new worlds.
--
-- SecureRandom (hopefully) provides high quality entropy, but is not available
-- on all systems.


mcl_random = {}

-- Enum of supported rng configurations
local supported_rng = {
	["PseudoRandom"] = true,
	["PseudoRandom_limited"] = true,
	["PcgRandom"] = true,
	["PcgRandom_secure"] = true,
	-- ?? add a lua based implementation of the PseudoRandom interface
	-- ?? backed by SecureRandom
}

-- SecureRandom may not be available on all systems
-- in that case the constructor returns nil
local secure_random = SecureRandom()

-- simple check whether SecureRandom actually provides entropy by trying to
-- compress some bytes
local test_len = 32
local test_data = secure_random:next_bytes(test_len)
local comp_data = minetest.compress(test_data, "deflate", 9)

if #comp_data < test_len then
	minetest.log("warning", "[mcl_random] data obtained from SecureRandom is compressible. Disabling SecureRandom.")
	secure_random = nil
end

local rng_override_msg = "You may override the world's rng setting in mcl_random.conf in the world path, but that *will* create problems in existing worlds."

-- error out if rng configuration is not valid to prevent breaking the mapgen
-- and other world features depending on reproducible rng sequences
local function validate_rng(rng)
	if rng and not supported_rng[rng] then
		error("[mcl_random] unsupported rng: \"" .. rng .. "\". Please update Mineclonia. " .. rng_override_msg)
	end

	return rng
end

-- read world specific rng setting
local random_settings = Settings(minetest.get_worldpath() .. DIR_DELIM .. "mcl_random.conf")
local rng = validate_rng(random_settings:get("use_world_rng"))

if not rng then
	rng = validate_rng(minetest.settings:get("mcl_secret_setting_use_world_rng"))

	if not rng then
		-- default to backwards compatibility
		-- TODO: find a way to determine if this is the first start of a new world
		-- in that case default to PcgRandom (or PcgRandom_secure if requirements met?)
		rng = "PseudoRandom"
	end

	random_settings:set("use_rng", rng)
	if not random_settings:write() then
		minetest.log("error", "[mcl_random] failed to update world rng settings")
	end
end

if rng == "PcgRandom_secure" then
	if not secure_random and not minetest.features.random_state_restore then
		error("[mcl_random] PcgRandom_secure selected, but both SecureRandom and PcgRandom state restore feature not available. Exiting now to protect your world. " .. rng_override_msg)
	elseif not secure_random then
		error("[mcl_random] PcgRandom_secure selected, but SecureRandom not available. Exiting now to protect your world. " .. rng_override_msg)
	elseif not minetest.features.random_state_restore then
		error("[mcl_random] PcgRandom_secure selected, but PcgRandom state restore feature not available. Exiting now to protect your world. Please update your Minetest version. " .. rng_override_msg)
	end
end

minetest.log("info", "[mcl_random] using world rng " .. rng)

local context_random_source = {}

local function get_non_secure_seed()
	-- TODO: determine whether this provides reasonable seed values
	-- collectgarbage("count") is prone to be zero during startup
	return os.time() * math.min(collectgarbage("count"), 1) * math.random(6700417)
end

if rng == "PseudoRandom" then
	-- full backwards compatibility with existing worlds
	--
	-- limits auto generated seed values to 0..32767, but doesn't touch
	-- predetermined seed values
	function mcl_random.get_random(seed)
		seed = seed and tonumber(seed) or (get_non_secure_seed() % 32768)
		return PseudoRandom(seed)
	end
elseif rng == "PseudoRandom_limited" then
	-- use PseudoRandom, but limit all seed values to 0..32767
	-- not fully backwards compatible with existing worlds
	--
	-- TODO: determine whether this is actually a useful variant
	function mcl_random.get_random(seed)
		seed = seed and tonumber(seed) or get_non_secure_seed()
		return PseudoRandom(seed % 32767)
	end
elseif rng == "PcgRandom" then
	-- use PcgRandom initalization using the constructor
	--
	-- this is probably good enough for Mineclonia's needs
	function mcl_random.get_random(seed)
		seed = seed and tonumber(seed) or get_non_secure_seed()
		return PcgRandom(seed)
	end
elseif rng == "PcgRandom_secure" then
	-- use PcgRandom and initalize it using set_state() passing full 64 bits
	-- of entropy (using the default m_inc value)
	--
	-- intended to be the currently best available option for new worlds
	-- TODO: determine whether it actually achieves that goal
	local m_inc = PcgRandom(0):get_state():sub(17)

	function mcl_random.get_random(seed)
		seed = seed and tonumber(seed)
		if seed then
			return PcgRandom(seed)
		else
			-- get seed value (plus m_inc) from SecureRandom
			local m_state = ""
			for i = 1, 8 do
				m_state = m_state .. string.format("%02x", secure_random:next_bytes():byte())
			end
			local rng = PcgRandom(0)
			rng:set_state(m_state .. m_inc)
			rng:next() -- exercise rng algorithm once mimicking PcgRandom constructor
			return rng
		end
	end
end

function mcl_random.random(min, max, context)
	context = context or ""
	if not context_random_source[context] then
		context_random_source[context] = mcl_random.get_random()
	end

	return context_random_source[context]:next(min, max)
end
