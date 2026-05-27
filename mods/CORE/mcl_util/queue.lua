-- mineclonia/mods/CORE/mcl_util/queue.lua
minetest.log("action", "[util/queue.lua] 05/05 C++ API.")
-- the queue class is using clever tricks to avoid allocating more memory than needed
-- it stores its back and front indices in the same table as the elements
-- index 1: the queue's back
-- index 2: the queue's front
local queue_class = {
	enqueue = function(self, value)
		self[self[1]] = value
		self[1] = self[1] + 1
	end,

	dequeue = function(self)
		local value = self[self[2]]
		if value == nil then
			return
		end
		self[self[2]] = nil
		self[2] = self[2] + 1
		return value
	end,

	peek = function(self)
		return self[self[2]]
	end,

	size = function(self)
		return self[1] - self[2]
	end,

	iterate = function(self)
		local idx = self[2] - 1
		return function()
			idx = idx + 1
			if self[1] <= idx then
				return nil
			end
			return self[idx]
		end
	end,
}

queue_class.__index = queue_class

-- ─── 【第3章完全閉幕：キュークラスのメソッドをC++最速筋肉へピンポイントですり替えるスイッチ】 ───
if mclcapi and mclcapi.native_enqueue then
	queue_class.enqueue = mclcapi.native_enqueue
	queue_class.dequeue = mclcapi.native_dequeue
	queue_class.peek    = mclcapi.native_peek    -- 👑 覗き見機能もC++へすり替え！
	queue_class.size    = mclcapi.native_queue_size
	queue_class.iterate = mclcapi.native_iterate -- 👑 ループクロージャのゴミ撒き散らしをC++筋肉で完全駆逐！
end

return function()
	return setmetatable({3, 3}, queue_class)
end
