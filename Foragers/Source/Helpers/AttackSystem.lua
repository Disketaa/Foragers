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
		_arrived = false,
	}
end

function AttackSystem.update(dt, allObjects)
	if not attacker or not attacker.sprite then
		return
	end

	local ws = attacker.weaponSprite
	local range, cooldown, damage, swing = getWeaponData(ws)
	local rangeSq = range * range
	local weaponFollow = getWeaponFollow(ws)
	local ax, ay = attacker.sprite.x, attacker.sprite.y

	if attacker.cooldownTimer > 0 then
		attacker.cooldownTimer = attacker.cooldownTimer - dt
	end

	cleanupTween(ws, "swing_angle")

	local targetValid = false
	if attacker.currentTarget then
		for _, comp in ipairs(attacker.currentTarget.components or {}) do
			if comp.type == "destructible" and comp.hp > 0 then
				local dx = attacker.currentTarget.x - ax
				local dy = attacker.currentTarget.y - ay
				if dx * dx + dy * dy <= rangeSq then
					targetValid = true
				end
				break
			end
		end
		if not targetValid and weaponFollow then
			local committed = attacker._arrived and attacker.cooldownTimer > 0
			if not committed and not (ws and ws.tweens and ws.tweens.swing_angle) then
				weaponFollow:recall()
				attacker.currentTarget = nil
				attacker.damageTimer = nil
			end
		end
	end

	if not attacker.currentTarget then
		local candidates = {}
		for _, entry in ipairs(allObjects) do
			local sprite = entry.instance
			if sprite then
				for _, comp in ipairs(sprite.components or {}) do
					if comp.type == "destructible" and comp.hp > 0 then
						local dx = sprite.x - ax
						local dy = sprite.y - ay
						if dx * dx + dy * dy <= rangeSq then
							table.insert(candidates, sprite)
						end
						break
					end
				end
			end
		end
		if #candidates > 0 then
			local chosen = candidates[love.math.random(1, #candidates)]
			-- Deploy to far side of target: away from character, not from weapon
			local deployDir = (attacker.sprite.x < chosen.x) and 1 or -1
			if weaponFollow then
				weaponFollow:deployTo(chosen, swing.offsetX, swing.offsetY, swing.smoothness, deployDir)
			end
			attacker.currentTarget = chosen
			attacker._deployDir = deployDir
			attacker._arrived = false
		end
	end

	-- Flight phase: wait until weapon is close to target before attacking
	if attacker.currentTarget and not attacker._arrived then
		local dir = attacker._deployDir or ((ws.x < attacker.currentTarget.x) and -1 or 1)
		local destX = attacker.currentTarget.x + dir * swing.offsetX
		local destY = attacker.currentTarget.y + swing.offsetY
		if math.abs(ws.x - destX) <= 2 and math.abs(ws.y - destY) <= 2 then
			attacker._arrived = true
		else
			return
		end
	end

	if attacker.damageTimer then
		attacker.damageTimer = attacker.damageTimer - dt
		if attacker.damageTimer <= 0 then
			attacker.damageTimer = nil
			if attacker.currentTarget then
				for _, comp in ipairs(attacker.currentTarget.components or {}) do
					if comp.type == "destructible" and comp.hp > 0 and comp.takeDamage then
						comp:takeDamage(damage)
						if comp.hp <= 0 and ws then
							ws:emit(Events.PROP_BROKEN)
						end
						attacker.currentTarget:emit(Events.PROP_HIT, damage)
						if ws then
							ws._lastHitX = attacker.currentTarget.x
							ws._lastHitY = attacker.currentTarget.y
							ws:emit(Events.PROP_HIT)
						end
						break
					end
				end
			end
		end
	end

	if not attacker.currentTarget or attacker.cooldownTimer > 0 or attacker.damageTimer then
		return
	end

	attacker.cooldownTimer = cooldown
	attacker.damageTimer = swing.duration

	-- Swing toward target: opposite of deploy direction
	local dir = -attacker._deployDir
	local rawEase = TweenModule.Easing[swing.curve] or TweenModule.Easing.OutSine
	local easeFunc = swingCurve(rawEase)
	local angleTween =
		TweenModule.Tween.new("swing_angle", swing.angleFrom * dir, swing.angleTo * dir, swing.duration, easeFunc)
	angleTween._smoothness = swing.smoothness
	ws.tweens.swing_angle = angleTween
	angleTween:start()
	ws:emit(Events.FLIPPED, attacker._deployDir == -1)
	ws._lastHitX = nil
	ws._lastHitY = nil
	ws:emit(Events.SWING)
end

return AttackSystem
