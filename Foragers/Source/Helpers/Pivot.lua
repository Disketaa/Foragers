--- Resolve a pivot spec into a pixel offset from the sprite's top-left.
--- `value` may be:
---   - a pixel number (e.g. 8 on a 16px axis = halfway)
---   - a keyword string: "left" | "right" | "center" for X,
---     or "top" | "bottom" | "center" for Y.
--- `size` is the axis length in pixels. `default` is the fallback used when
--- `value` is nil; it is itself resolved (so it may be a pixel or keyword too).
local Pivot = {}

function Pivot.px(value, size, default)
	if type(value) == "number" then
		return value
	elseif type(value) == "string" then
		local v = value:lower()
		if v == "left" or v == "top" then
			return 0
		elseif v == "right" or v == "bottom" then
			return size
		elseif v == "center" then
			return size / 2
		end
	end
	if default ~= nil then
		return Pivot.px(default, size, 0)
	end
	return 0
end

return Pivot
