minetest.after(1, function()
	if minetest.global_exists("mcla_generated_translations") then
		local wp = minetest.get_worldpath().."/mcla_translate"
		minetest.mkdir(wp)
		local filename_dirs = wp.."/mod_dirs.txt"
		local file_dirs, _ = io.open(filename_dirs, "w")

		for modname, strings in pairs(mcla_generated_translations) do
			local filename_mod = wp.."/"..modname.."_translations_tmp.lua"
			local file, _ = io.open(filename_mod, "w")
			file_dirs:write(minetest.get_modpath(modname).." "..modname.."_translations_tmp.lua\n")
			table.sort(strings)
			for _, str in ipairs(strings) do
				file:write("NS(" .. dump(str) .. ")\n")
			end
			file:close()
		end
		file_dirs:close()
	end
	minetest.request_shutdown()
end)
