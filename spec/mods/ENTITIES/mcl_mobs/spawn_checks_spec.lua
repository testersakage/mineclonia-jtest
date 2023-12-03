dofile("mods/ENTITIES/mcl_mobs/spawn_checks.lua")

describe("spawn checks", function()
	describe("has_room()", function()
		it("should work on valid input", function()
			assert.is_true(has_room())
		end)
	end)
end)
