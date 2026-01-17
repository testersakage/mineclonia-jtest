function mcl_util.apply_enchantment_glint(image)
	local texture = nil
	local h = 64 * 16
	for i = 0, 63 do
		local y = i * 16
		texture = string.format("%s[combine:16x%d:0,%d=%s", texture and texture.."^" or "", h, y, image)
	end
	texture = texture.."^[overlay:mcl_util_enchantment_glint.png"

	return {
		name = texture,
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 2,
		},
	}
end
