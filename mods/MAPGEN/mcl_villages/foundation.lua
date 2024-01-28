local mod_name = minetest.get_current_modname()
local S = minetest.get_translator(mod_name)

local domain = mcl_villages.setting_domain

mcla_settings.register_bool(
	domain,
	"circles",
	true,
	S("Use circles for building foundations"),
	S("Will use rectangles if this is false")
)
mcla_settings.register_bool(
	domain,
	"terrace",
	true,
	S("Terrace above ground instead of having straight sides"),
	S("Set to false to have straight sides")
)
mcla_settings.register(
	domain,
	"padding",
	2,
	S("Extra width to clear over ground"),
	S("Set to zero to approximate old style")
)
mcla_settings.register(
	domain,
	"top_padding",
	8,
	S("Extra height to clear above building"),
	S("Set to a big number to approximate old style")
)
mcla_settings.register(
	domain,
	"terrace_max_ext",
	6,
	S("Maximum width terracing is allowed to extend beyond building radius"),
	S("This may impact other buildings iof it's too big")
)

-------------------------------------------------------------------------------
-- function to fill empty space below baseplate when building on a hill
-------------------------------------------------------------------------------
function mcl_villages.ground(pos, pr) -- role model: Wendelsteinkircherl, Brannenburg
	local p2 = vector.new(pos)
	local cnt = 0
	local mat = "mcl_core:dirt"
	p2.y = p2.y-1
	while true do
		cnt = cnt+1
		if cnt > 20 then break end
		if cnt>pr:next(2,4) then
			mat = "mcl_core:stone"
		end
		minetest.swap_node(p2, {name=mat})
		p2.y = p2.y-1
	end
end

-------------------------------------------------------------------------------
-- function clear space above baseplate
-------------------------------------------------------------------------------
function mcl_villages.terraform(settlement_info, pr)
	local fheight, fwidth, fdepth, schematic_data

	for i, built_house in ipairs(settlement_info) do
		-- pick right schematic_info to current built_house
		for j, schem in ipairs(mcl_villages.schematic_table) do
			if settlement_info[i]["name"] == schem["name"] then
				schematic_data = schem
				break
			end
		end
		local pos = settlement_info[i]["pos"]
		if settlement_info[i]["rotat"] == "0" or settlement_info[i]["rotat"] == "180" then
			fwidth = schematic_data["hwidth"]
			fdepth = schematic_data["hdepth"]
		else
			fwidth = schematic_data["hdepth"]
			fdepth = schematic_data["hwidth"]
		end
		fheight = schematic_data["hheight"]  -- remove trees and leaves above

		--
		-- now that every info is available -> create platform and clear space above
		--
		for xi = 0,fwidth-1 do
			for zi = 0,fdepth-1 do
				for yi = 0,fheight *3 do
					if yi == 0 then
						local p = {x=pos.x+xi, y=pos.y, z=pos.z+zi}
						mcl_villages.ground(p, pr)
					else
						-- write ground
						minetest.swap_node({x=pos.x+xi, y=pos.y+yi, z=pos.z+zi},{name="air"})
					end
				end
			end
		end
	end
end

-- Empty space above ground
local function overground(pos, fwidth, fdepth, fheight)

	-- Avoid globals so they reflect in game changes
	local terrace = mcla_settings.get(domain, "terrace")
	local padding = mcla_settings.get(domain, "padding")
	local top_padding = mcla_settings.get(domain, "top_padding")
	local terrace_max_ext = mcla_settings.get(domain, "terrace_max_ext")
	local circles = mcla_settings.get(domain, "circles")

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
		if not terrace then
			count = count + 2
		end

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
