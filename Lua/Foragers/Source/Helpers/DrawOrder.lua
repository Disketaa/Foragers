local DrawOrder = {}

local sortBuffer = {}

---@param entries table[] { path, data, instance }
---@return table Sprite[] reusable sort buffer
function DrawOrder.collect(entries)
	local n = 0
	for i = 1, #entries do
		local sprite = entries[i].instance
		if sprite then
			n = n + 1
			sortBuffer[n] = sprite
			-- zKey = layer * 1e6 + sortY * 1e3 + x → layer dominates, sortY breaks ties, x sorts same-foot sprites
			sprite.zKey = (sprite.layer or 0) * 1000000 + (sprite.sortY or 0) * 1000 + (sprite.x or 0)
		end
	end
	for i = n + 1, #sortBuffer do
		sortBuffer[i] = nil
	end
	return sortBuffer
end

---@param list table Sprite[] buffer from collect()
function DrawOrder.sort(list)
	table.sort(list, function(a, b)
		return a.zKey < b.zKey
	end)
end

return DrawOrder
