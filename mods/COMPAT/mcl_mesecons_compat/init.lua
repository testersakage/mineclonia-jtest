-- Make it possible to acquire mesecons from redstone
if core.get_modpath("mesecons") then
	core.register_craft({
		output = "mesecons:mesecon",
		type = "shapeless",
		recipe = { "mcl_redstone:redstone" },
	})
end
