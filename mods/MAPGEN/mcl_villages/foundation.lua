local circles = minetest.settings:get_bool("mcl_villages_circles", true)
local terrace = minetest.settings:get_bool("mcl_villages_terrace", true)
local padding = tonumber(minetest.settings:get("mcl_villages_padding")) or 2
local top_padding = tonumber(minetest.settings:get("mcl_villages_top_padding")) or 8
local terrace_max_ext = tonumber(minetest.settings:get("mcl_villages_terrace_max_ext")) or 6

-- Empty space above ground
local function overground(pos, fwidth, fdepth, fheight)

	if circles then
		local y = math.ceil(pos.y + 1)
		local radius_base = math.max(fwidth, fdepth)
		local radius = math.round((radius_base / 2) + padding)
		local dome = fheight + top_padding

		for count2 = 1, fheight + top_padding do
			if terrace and radius_base > 3 then
				if count2 > dome then
					radius = radius - 1
				elseif count2 <= terrace_max_ext then
					radius = radius + 1
				end
			end

			mcl_util.circle_bulk_set_node_vm(radius, pos, y, "air")

			y = y + 1
		end
	else
		local count = 1
		if terrace then
			for y_adj = 1, pos.y + fheight + top_padding do
				local pos1 = vector.offset(pos, -count, y_adj, -count)
				local pos2 = vector.offset(pos, fwidth + count, y_adj, fdepth + count)
				mcl_util.bulk_set_node_vm(pos1, pos2, "air")

				if terrace and count <= terrace_max_ext then
					count = count + 1
				end
			end
		else
			local x_adjust = fwidth / 2
			local z_adjust = fdepth / 2

			local pos1 = vector.offset(pos, -x_adjust, 0, -z_adjust)
			local pos2 = vector.offset(pos, x_adjust, fheight, z_adjust)
			mcl_util.bulk_set_node_vm(pos1, pos2, "air")
		end
	end
end

function mcl_villages.terraform_new(settlement_info)
	local fheight, fwidth, fdepth

	-- Do ground first so that we can clear overhang for lower buildings
	for i, schematic_data in ipairs(settlement_info) do
		local pos = vector.copy(schematic_data["pos"])
		fwidth = schematic_data["size"]["x"]
		fdepth = schematic_data["size"]["z"]

		if schematic_data["name"] ~= "lamp" then
			mcl_util.create_ground_turnip(pos, fwidth, fdepth)
		end
	end

	for i, schematic_data in ipairs(settlement_info) do
		local pos = vector.copy(schematic_data["pos"])

		fwidth = schematic_data["size"]["x"]
		fdepth = schematic_data["size"]["z"]
		fheight = schematic_data["size"]["y"]

		if schematic_data["name"] ~= "lamp" then
			overground(pos, fwidth, fdepth, fheight)
		end
	end
end
