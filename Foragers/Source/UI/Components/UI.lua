--- Data-only component. No update/draw — positioned by Main using calculate().
---@class UIComponent
---@field parent Sprite|nil
---@field type "ui"
---@field horizontalAlign string "left"|"center"|"right"
---@field verticalAlign string "top"|"center"|"bottom"
---@field offsetX number
---@field offsetY number
local UI = {}
UI.__index = UI

---@param data table
---@return UIComponent
function UI.new(data)
	return setmetatable({
		type = "ui",
		horizontalAlign = data.horizontalAlign or "left",
		verticalAlign = data.verticalAlign or "top",
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
	}, UI)
end

---@param comp UIComponent
---@param containerW number
---@param containerH number
---@param elemW number
---@param elemH number
---@return number x, number y
function UI.calculate(comp, containerW, containerH, elemW, elemH)
	local x = comp.offsetX or 0
	local y = comp.offsetY or 0

	if comp.horizontalAlign == "center" then
		x = math.floor((containerW - elemW) / 2) + x
	elseif comp.horizontalAlign == "right" then
		x = containerW - elemW - x
	end

	if comp.verticalAlign == "center" then
		y = math.floor((containerH - elemH) / 2) + y
	elseif comp.verticalAlign == "bottom" then
		y = containerH - elemH - y
	end

	return x, y
end

return UI