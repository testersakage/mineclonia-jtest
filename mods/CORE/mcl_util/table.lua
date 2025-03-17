-- Updates all values in t using values from ...
function table.update(t, ...)
	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from ...
function table.update_nil(t, ...)
	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

-- Recursively updates all values in t using values from ...
function table.update_deep(t, ...)
	for _, to in ipairs{...} do
		for k, v in pairs(to) do
			if type(t[k]) == "table" and type(v) == "table" then
				table.update_deep(t[k], v)
			else
				t[k] = v
			end
		end
	end
	return t
end

-- Merges t with ..., returning a new table
function table.merge(t, ...)
	local t2 = table.copy(t)
	return table.update(t2, ...)
end

-- Recursively merges t with ..., returning a new table
function table.merge_deep(t, ...)
	local t2 = table.copy(t)
	return table.update_deep(t2, ...)
end

-- Reverses the order of elements inside t
function table.reverse(t)
	local a, b = 1, #t
	while a < b do
		t[a], t[b] = t[b], t[a]
		a, b = a + 1, b - 1
	end
end

-- Returns the maximum numerical index of t
function table.max_index(t)
	local max = 0
	for k, _ in pairs(t) do
		if type(k) == "number" and k > max then max = k end
	end
	return max
end

-- Returns the amount of elements of t that are suitable by does_it_count (optional)
function table.count(t, does_it_count)
	local r = 0
	for k, v in pairs(t) do
		if does_it_count == nil or (type(does_it_count) == "function" and does_it_count(k, v)) then
			r = r + 1
		end
	end
	return r
end

-- Returns a random element out of t
function table.random_element(t)
	local keyset = {}
	for k, _ in pairs(t) do
		table.insert(keyset, k)
	end
	local rk = keyset[math.random(#keyset)]
	return t[rk], rk
end
