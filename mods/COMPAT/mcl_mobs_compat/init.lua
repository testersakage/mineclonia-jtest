-- No-op in MCL2 (capturing mobs is not possible).
-- Provided for compability with Mobs Redo
function mcl_mobs.capture_mob(self, clicker, chance_hand, chance_net, chance_lasso, force_take, replacewith)
	return false
end

-- No-op in MCL2 (protecting mobs is not possible).
function mcl_mobs.protect(self, clicker)
	return false
end
