local UIComponent = require("Source.UI.Components.UI")
local Pivot = require("Source.Helpers.Core.Pivot")

local Layout = {}

--- Apply pivot and active tween offsets; `canvas` is the render context
--- (width/height), passed like Camera.update so layout stays free of game state.
function Layout.positionUI(ui, canvas)
	local w = ui.sprite.frameWidth or ui.sprite.image:getWidth()
	local h = ui.sprite.frameHeight or ui.sprite.image:getHeight()
	local px, py = UIComponent.calculate(ui.ui, canvas.width, canvas.height, w, h)
	local tweens = ui.sprite.tweens
	local tweenX = tweens and tweens.x and tweens.x:getValue() or 0
	local tweenY = tweens and tweens.y and tweens.y:getValue() or 0
	ui.sprite.x = px + Pivot.px(ui.sprite.pivotX, w, 0) + tweenX
	ui.sprite.y = py + Pivot.px(ui.sprite.pivotY, h, 0) + tweenY
end

return Layout
