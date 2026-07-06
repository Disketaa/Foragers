local TweenModule = require("Source.Sprite.Components.Tween")
local Events = require("Source.Helpers.Events")

local attacker = nil

local function swingCurve(easeFunc)
	return function(t)
		if t <= 0.5 then
			return easeFunc(t * 2)
		else
			return easeFunc((1 - t) * 2)
		end
	end
end

local function getWeaponData(sprite)
	for _, comp in ipairs(sprite and sprite.components or {}) do
		if comp.type == "weapon" then
			return comp.range, comp.cooldown, comp.damage, comp.swing
		end
	end
	return 20, 0.5, 1, { angleFrom = -30, angleTo = 30, duration = 0.15, offsetX = 0, offsetY = -8, curve = "Sine", smoothness = 0 }
end

local function getWeaponFollow(ws)
	if ws then
		for _, comp in ipairs(ws.components or {}) do
			if comp.type == "follow" then
				return comp
			end
		end
	end
	return nil
end

local function cleanupTween(ws, key)
	if ws and ws.tweens and ws.tweens[key] and ws.tweens[key]:isFinished() then
		ws.tweens[key] = nil
	end
end

local AttackSystem = {}

function AttackSystem.registerAttacker(sprite, weaponSprite)
	attacker = {
		sprite = sprite,
		weaponSprite = weaponSprite,
		cooldownTimer = 0,
		currentTarget = nil,
	}
end

function AttackSystem.update(dt, allObjects)
	if not attacker or not attacker.sprite then
		return
	end

	local ws = attacker.weaponSprite
	local range, cooldown, damage, swing = getWeaponData(ws)
	local weaponFollow = getWeaponFollow(ws)
	local ax, ay = attacker.sprite.x, attacker.sprite.y

	if attacker.cooldownTimer > 0 then
		attacker.cooldownTimer = attacker.cooldownTimer - dt
	end

	cleanupTween(ws, "swing_angle")

	-- Check if current target is still valid (alive + in range)
	local targetValid = false
	if attacker.currentTarget then
		for _, comp in ipairs(attacker.currentTarget.components or {}) do
			if comp.type == "destructible" and comp.hp > 0 then
				local dx = attacker.currentTarget.x - ax
				local dy = attacker.currentTarget.y - ay
				if math.sqrt(dx * dx + dy * dy) <= range then
					targetValid = true
				end
				break
			end
		end
		if not targetValid and weaponFollow then
			weaponFollow:recall()
			attacker.currentTarget = nil
		end
	end

	-- Pick a new random target if none
	if not attacker.currentTarget then
		local candidates = {}
		for _, entry in ipairs(allObjects) do
			local sprite = entry.instance
			if sprite then
				for _, comp in ipairs(sprite.components or {}) do
					if comp.type == "destructible" and comp.hp > 0 then
						local dx = sprite.x - ax
						local dy = sprite.y - ay
						if math.sqrt(dx * dx + dy * dy) <= range then
							table.insert(candidates, sprite)
						end
						break
					end
				end
			end
		end
		if #candidates > 0 then
			local chosen = candidates[love.math.random(1, #candidates)]
			if weaponFollow then
				weaponFollow:deployTo(chosen, swing.offsetX, swing.offsetY)
			end
			attacker.currentTarget = chosen
		end
	end

	if not attacker.currentTarget or attacker.cooldownTimer > 0 then
		return
	end

	attacker.cooldownTimer = cooldown

	local dir = attacker.sprite.flipX and -1 or 1
	local rawEase = TweenModule.Easing[swing.curve] or TweenModule.Easing.Sine
	local easeFunc = swingCurve(rawEase)
	local angleTween = TweenModule.Tween.new("swing_angle", swing.angleFrom, swing.angleTo * dir, swing.duration, easeFunc)
	angleTween._smoothness = swing.smoothness
	ws.tweens.swing_angle = angleTween
	angleTween:start()

	for _, comp in ipairs(attacker.currentTarget.components or {}) do
		if comp.type == "destructible" and comp.hp > 0 and comp.takeDamage then
			comp:takeDamage(damage)
			attacker.currentTarget:emit(Events.PROP_HIT)
			break
		end
	end
end

return AttackSystem
