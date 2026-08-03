local Gizmo = {}

local rects = {}
local fills = {}
local points = {}

local DEFAULT_LINE_COLOR = { 1, 0.2, 0.2, 0.9 }
local DEFAULT_POINT_COLOR = { 1, 1, 1, 1 }

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

-- LÖVE has no native dash primitive, so edges are split into dash/gap segments.
local function drawDashedLine(x1, y1, x2, y2, dash, gap)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	if len <= 0 then
		return
	end
	local ux, uy = dx / len, dy / len
	local t = 0
	while t < len do
		local segEnd = math.min(t + dash, len)
		love.graphics.line(x1 + ux * t, y1 + uy * t, x1 + ux * segEnd, y1 + uy * segEnd)
		t = t + dash + gap
	end
end

local function drawDashedRect(x1, y1, x2, y2, thickness)
	local dash = math.max(2, thickness * 4)
	local gap = math.max(1, thickness * 2)
	drawDashedLine(x1, y1, x2, y1, dash, gap)
	drawDashedLine(x2, y1, x2, y2, dash, gap)
	drawDashedLine(x2, y2, x1, y2, dash, gap)
	drawDashedLine(x1, y2, x1, y1, dash, gap)
end

-- Append groups not yet in `order` so unconfigured groups still draw with defaults.
local function bucketInto(list, kind, buckets, seen, order)
	for _, e in ipairs(list) do
		local b = buckets[e.group]
		if not b then
			b = { fills = {}, rects = {}, points = {} }
			buckets[e.group] = b
			if not seen[e.group] then
				seen[e.group] = true
				order[#order + 1] = e.group
			end
		end
		b[kind][#b[kind] + 1] = e
	end
end

--- Render buffered gizmos. Entries are grouped by their group name; each group's
--- settings style its own fills (`backgroundColor`), outlines (`color` + `decor`)
--- and point markers. Groups draw in ascending `priority`, so a higher priority
--- group (e.g. collisions) layers on top of a lower one (e.g. boundaries).
---@param w2s function World-to-screen transform: (wx, wy) -> (sx, sy)
---@param groups table Map of group name -> settings ({ color, backgroundColor, decor, thickness, size, priority })
function Gizmo.draw(w2s, groups)
	groups = groups or {}

	local order = {}
	local seen = {}
	for name in pairs(groups) do
		seen[name] = true
		order[#order + 1] = name
	end
	table.sort(order, function(a, b)
		return (groups[a].priority or 0) < (groups[b].priority or 0)
	end)

	-- Bucket entries per group once, so each buffer is scanned a single time
	-- and each group's style is set once rather than per entry.
	local buckets = {}
	bucketInto(fills, "fills", buckets, seen, order)
	bucketInto(rects, "rects", buckets, seen, order)
	bucketInto(points, "points", buckets, seen, order)

	local drew = false
	for _, name in ipairs(order) do
		local g = groups[name] or {}
		local b = buckets[name]

		if #b.fills > 0 then
			local bg = g.backgroundColor
			if bg and bg[1] then
				love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
				for _, f in ipairs(b.fills) do
					local x1, y1 = w2s(f.x, f.y)
					local x2, y2 = w2s(f.x + f.w, f.y + f.h)
					love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
				end
				drew = true
			end
		end

		if #b.rects > 0 then
			local color = g.color or DEFAULT_LINE_COLOR
			local thickness = g.thickness or 1
			local decor = g.decor or "diagonal"
			local dashed = decor == "dashed"
			local diagonals = decor == "diagonal" or decor == "cross"
			local cross = decor == "cross"
			love.graphics.setLineWidth(thickness)
			love.graphics.setColor(color[1], color[2], color[3], color[4])
			for _, r in ipairs(b.rects) do
				local x1, y1 = w2s(r.x, r.y)
				local x2, y2 = w2s(r.x + r.w, r.y + r.h)
				x1, y1 = math.floor(x1 + 0.5), math.floor(y1 + 0.5)
				x2, y2 = math.floor(x2 + 0.5), math.floor(y2 + 0.5)
				if dashed then
					drawDashedRect(x1, y1, x2, y2, thickness)
				else
					love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
				end
				if diagonals then
					love.graphics.line(x1, y1, x2, y2)
					if cross then
						love.graphics.line(x1, y2, x2, y1)
					end
				end
			end
			drew = true
		end

		if #b.points > 0 then
			local color = g.color or DEFAULT_POINT_COLOR
			love.graphics.setColor(color[1], color[2], color[3], color[4])
			for _, p in ipairs(b.points) do
				local hw = p.size / 2
				local x1, y1 = w2s(p.x - hw, p.y - hw)
				local x2, y2 = w2s(p.x + hw, p.y + hw)
				love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
			end
			drew = true
		end
	end

	if drew then
		love.graphics.setColor(1, 1, 1, 1)
	end
end

return Gizmo
