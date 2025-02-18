-- See https://github.com/luanti-org/luanti/issues/15692
-- Adapted from a script by appgurueu from https://codeberg.org/mineclonia/mineclonia/pulls/2918#issuecomment-2839381
-- needs modlib

assert(modlib.version >= 103)

local media_paths = modlib.minetest.media.paths

local function nodes(filepath)
	local stream = assert(io.open(filepath, "rb"))
	local model = assert(modlib.b3d.read(stream))
	stream:close()

	return coroutine.wrap(function()
		local function visit(node)
			coroutine.yield(node)
			for _, child in ipairs(node.children) do
				visit(child)
			end
		end
		visit(model.node)
	end)
end

local function isclose(a, b)
	return math.abs(a - b) < 1e-3
end

core.register_on_mods_loaded(function()

for name, path in pairs(media_paths) do
	if name:match"%.b3d$" then
		local _, it = xpcall(function() return nodes(path) end, function(err)
			core.log("warning", ("Failed to read model %s: %s"):format(name, err))
			return function() end
		end)
		for node in it do
			for k, v in pairs(core.registered_entities) do
				if v._mesh == name then
					local entname = k
					local rot_quat = node.rotation
					local rot_mat = modlib.matrix4.rotation(rot_quat)
					local rxx, ryy, rzz = rot_mat[1][1], rot_mat[2][2], rot_mat[3][3]
					local function abs1(x) return isclose(math.abs(x), 1) end
					local is_scaling = abs1(rxx) and abs1(ryy) and abs1(rzz)
					local flips_axis = isclose(rxx, -1) or isclose(ryy, -1) or isclose(rzz, -1)
					if is_scaling and flips_axis then
						--if first then
						--	print(("Possibly affected bones in `%s`:"):format(name))
						--end
						--first = false
						local ent = core.registered_entities[entname]
						local sx, sy, sz = unpack(node.scale)
						if ent and ent._arm_poses then
							for k,v in pairs(ent._arm_poses) do
								if ent._arm_poses[k][node.name] then
									print(('core.registered_entities["%s"]._arm_poses["%s"]["%s"][3] = vector.new(%0.1f, %0.1f, %0.1f)'):format(entname, k, node.name, sx*rxx, sy*ryy, sz*rzz))
								end
							end
						end
						--print(("%s = vector.new(%.01f, %.01f, %.01f)"):format(
						--		node.name, sx * rxx, sy * ryy, sz * rzz))
					end
				end
			end
		end
	end
end

end)
