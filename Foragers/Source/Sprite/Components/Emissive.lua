local Pivot = require("Source.Helpers.Core.Pivot")

local Emissive = {}
Emissive.__index = Emissive

function Emissive.new()
	return setmetatable({
		type = "emissive",
	}, Emissive)
end

--- Draw emissive sprites directly to screen AFTER post-process blit.
--- No separate canvas, no UV sampling — same transform as main canvas,
--- so alignment is pixel-perfect by construction.
---@param entries table[] Entries with `.instance` (sprite)
---@param canvas table Canvas instance (for scale/offset)
---@param camPixelX number
---@param camPixelY number
---@param camSubX number
---@param camSubY number
---@param zoom number
---@param zpx number Zoom pivot X
---@param zpy number Zoom pivot Y
function Emissive.drawToScreen(entries, canvas, camPixelX, camPixelY, camSubX, camSubY, shakeX, shakeY, zoom, zpx, zpy)
	local s = canvas.scale
	local finalX = canvas.offsetX + math.floor(shakeX or 0) + camSubX * s - s
	local finalY = canvas.offsetY + math.floor(shakeY or 0) + camSubY * s - s

	love.graphics.push()
	-- Zoom transform (mirrors Canvas:draw)
	if zoom ~= 1 then
		love.graphics.translate(zpx, zpy)
		love.graphics.scale(zoom, zoom)
		love.graphics.translate(-zpx, -zpy)
	end
	-- Canvas blit origin
	love.graphics.translate(finalX, finalY)
	-- Canvas scale (pixel-perfect)
	love.graphics.scale(s, s)
	-- World-space offset (same as translate inside canvas:draw drawFunc)
	love.graphics.translate(camPixelX, camPixelY)

	-- Alpha blend: sprite keeps original texture color on top of graded world.
	-- Minecraft-style emissive: no darkening, no extra brightness boost.
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)

	for _, entry in ipairs(entries) do
		local sprite = entry.instance or entry
		if sprite and sprite.components then
			local emComp = sprite:findComponent("emissive", function(c) return not c._broken end)
			if emComp then
				local rot = 0
				local t = sprite.tweens
				if t then
					local angleTween = t.swing_angle or t.angle
					if angleTween then
						rot = math.rad(angleTween:getValue())
					end
				end
				if rot == 0 and sprite.angle then
					rot = math.rad(sprite.angle)
				end

				local scaleX, scaleY = 1, 1
				if t then
					if t.scale_x then
						scaleX = t.scale_x:getValue()
					end
					if t.scale_y then
						scaleY = t.scale_y:getValue()
					end
				end

				local spritesheet = sprite:findComponent("spritesheet", function(c) return not c._broken end)
				if spritesheet then
					love.graphics.push()
					love.graphics.translate(sprite.x, sprite.y)
					-- drawCurrentFrame handles flipX+sx/sy internally, so only pass tween scale
					love.graphics.scale(scaleX, scaleY)
					love.graphics.rotate(rot)
					spritesheet:drawCurrentFrame(0, 0, 0)
					love.graphics.pop()
				elseif sprite.image then
					if sprite.flipX then
						scaleX = -scaleX
					end
					local w = sprite.frameWidth or sprite.image:getWidth()
					local h = sprite.frameHeight or sprite.image:getHeight()
					local ox = Pivot.px(sprite.pivotX, w, 0)
					local oy = Pivot.px(sprite.pivotY, h, 0)
					love.graphics.draw(sprite.image, sprite.x, sprite.y, rot, scaleX, scaleY, ox, oy)
				end
			end
		end
	end

	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

return Emissive