local function expSmooth(dt, smoothness)
	if smoothness and smoothness > 0 then
		return 1 - math.exp(-dt / smoothness)
	end
	return 1
end

return { expSmooth = expSmooth }
