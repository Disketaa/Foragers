local Gizmo = {}

local rects = {}
local fills = {}
local points = {}

--- Queue a world-space rect for the next gizmo pass. Pure accumulation — safe
--- to call inside the world canvas draw while the real rendering happens later
--- at native resolution in draw().
---@param group string Group name — styles resolved from the `groups` map in draw().
---@param x number
---@param y number
---@param w number
---@param h number
function Gizmo.rect(group, x, y, w, h)
	table.insert(rects, { group = group, x = x, y = y, w = w, h = h })
end

---@param group string Group name — styles resolved from the `groups` map in draw().
---@param x number
---@param y number
---@param w number
---@param h number
function Gizmo.fillRect(group, x, y, w, h)
	table.insert(fills, { group = group, x = x, y = y, w = w, h = h })
end

--- Queue a solid square marker centered on a world point (e.g. a pivot).
---@param group string
---@param x number Center x in world coords
---@param y number Center y in world coords
---@param size number Square side length in world px (drawn as `color` fill)
function Gizmo.point(group, x, y, size)
	table.insert(points, { group = group, x = x, y = y, size = size })
end

function Gizmo.clear()
	rects = {}
	fills = {}
	points = {}
end

--- Render buffered gizmos. Entries are grouped by their group name; each group's
--- settings style its own fills (`backgroundColor`), outlines (`color`) and point
--- markers. Groups are drawn in ascending `priority`, so a higher priority group
--- (e.g. collisions) always layers on top of a lower one (e.g. boundaries).
---@param w2s function World-to-screen transform: (wx, wy) -> (sx, sy)
---@param groups table Map of group name -> settings ({ color, backgroundColor, thickness, size, priority })
function Gizmo.draw(w2s, groups)
	groups = groups or {}

	local order = {}
	for name in pairs(groups) do
		table.insert(order, name)
	end
	table.sort(order, function(a, b)
		return (groups[a].priority or 0) < (groups[b].priority or 0)
	end)

	for _, name in ipairs(order) do
		local g = groups[name]

		for _, f in ipairs(fills) do
			local bg = f.group == name and g.backgroundColor
			if bg and bg[1] then
				love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
				local x1, y1 = w2s(f.x, f.y)
				local x2, y2 = w2s(f.x + f.w, f.y + f.h)
				love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
			end
		end

		for _, r in ipairs(rects) do
			if r.group == name then
				local color = g.color or { 1, 0.2, 0.2, 0.9 }
				love.graphics.setLineWidth(g.thickness or 1)
				love.graphics.setColor(color[1], color[2], color[3], color[4])
				local x1, y1 = w2s(r.x, r.y)
				local x2, y2 = w2s(r.x + r.w, r.y + r.h)
				x1, y1 = math.floor(x1 + 0.5), math.floor(y1 + 0.5)
				x2, y2 = math.floor(x2 + 0.5), math.floor(y2 + 0.5)
				love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
				love.graphics.line(x1, y1, x2, y2)
			end
		end

		for _, p in ipairs(points) do
			if p.group == name then
				local color = g.color or { 1, 1, 1, 1 }
				love.graphics.setColor(color[1], color[2], color[3], color[4])
				local hw = p.size / 2
				local x1, y1 = w2s(p.x - hw, p.y - hw)
				local x2, y2 = w2s(p.x + hw, p.y + hw)
				love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
			end
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

return Gizmo
