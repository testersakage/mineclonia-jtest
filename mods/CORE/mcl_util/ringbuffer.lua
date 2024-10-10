local ringbuffer_class = {}
local ringbuffer = {}
ringbuffer_class.__index = ringbuffer_class

function ringbuffer.new(size, initial_values)
	local values = initial_values or {}
	-- use initial_values as is, unless number of entries exceeds size,
	-- then copy newest entries into new list
	if #values > size then
		values = {}
		for i = #initial_values - size, #initial_values do
			values[#values] = initial_values[i]
		end
	end
	return setmetatable({
		data = values,
		size = size,
	}, ringbuffer_class)
end

function ringbuffer_class:insert(record)
	if #self.data >= self.size then
		table.remove(self.data, 1)
	end
	table.insert(self.data, record)
end

function ringbuffer_class:indexof(val)
	local i = table.indexof(self.data, val)
	return i ~= -1 and i or false
end

function ringbuffer_class:insert_if_not_exists(record)
	local insert = not self:indexof(record)
	if insert then
		self:insert(record)
	end
	return insert
end

function ringbuffer_class:serialize()
	return minetest.serialize(self.data)
end

function ringbuffer.deserialize(size, serialized_data)
	local rb_data = minetest.deserialize(serialized_data)
	return rb_data and ringbuffer.new(size, rb_data)
end

return setmetatable(ringbuffer, ringbuffer_class)
