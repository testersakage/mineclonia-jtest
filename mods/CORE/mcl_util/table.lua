-- Updates all values in t using values from to*.
function table.update(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from to*.
function table.update_nil(t, ...)
	for _, to in ipairs {...} do
		for k, v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

function table.merge(t, ...)
	local t2 = table.copy(t)
	return table.update(t2, ...)
end

function table.reverse(t)
	local a, b = 1, #t
	while a < b do
		t[a], t[b] = t[b], t[a]
		a, b = a + 1, b - 1
	end
end

function table.max_index(t)
	local max = 0
	for k, _ in pairs(t) do
		if type(k) == "number" and k > max then max = k end
	end
	return max
end

function table.count(t, does_it_count)
	local r = 0
	for k, v in pairs(t) do
		if does_it_count == nil or ( type(does_it_count) == "function" and does_it_count(k, v) ) then
			r = r + 1
		end
	end
	return r
end

function table.random_element(t)
	local keyset = {}
	for k, _ in pairs(t) do
		table.insert(keyset, k)
	end
	local rk = keyset[math.random(#keyset)]
	return t[rk], rk
end
