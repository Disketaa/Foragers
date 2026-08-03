local Gizmo = {}

local rects = {}

--- Queue a world-space rect for the next gizmo pass. Pure accumulation — safe
--- to call inside the world canvas draw while the real rendering happens later
--- at native resolution in draw().
function Gizmo.rect(x, y, w, h)
	table.insert(rects, { x = x, y = y, w = w, h = h })
end

function Gizmo.clear()
	rects = {}
end

---@param w2s function World-to-screen transform: (wx, wy) -> (sx, sy)
---@param style table|nil Optional { thickness = number, color = {r,g,b,a} }
function Gizmo.draw(w2s, style)
	if #rects == 0 then
		return
	end
	local color = (style and style.color) or { 1, 0.2, 0.2, 0.9 }
	love.graphics.setLineWidth((style and style.thickness) or 1)
	love.graphics.setColor(color[1], color[2], color[3], color[4])
	for _, r in ipairs(rects) do
		local x1, y1 = w2s(r.x, r.y)
		local x2, y2 = w2s(r.x + r.w, r.y + r.h)
		x1, y1 = math.floor(x1 + 0.5), math.floor(y1 + 0.5)
		x2, y2 = math.floor(x2 + 0.5), math.floor(y2 + 0.5)
		love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
		love.graphics.line(x1, y1, x2, y2)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

return Gizmo
