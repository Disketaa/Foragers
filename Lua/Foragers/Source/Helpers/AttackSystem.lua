local TweenModule = require("Source.Sprite.Components.Tween")

local attacker = nil

local function swingEase(t)
	return (1 - math.cos(t * math.pi)) / 2
end

local function getWeaponStats(sprite)
	for _, comp in ipairs(sprite and sprite.components or {}) do
		if comp.type == "weapon" then
			return comp.range, comp.cooldown, comp.damage
		end
	end
	return 20, 0.5, 1
end

local AttackSystem = {}

function AttackSystem.registerAttacker(sprite, weaponSprite)
	attacker = {
		sprite = sprite,
		weaponSprite = weaponSprite,
		cooldownTimer = 0,
		_swingDuration = 0.15,
	}
end

function AttackSystem.update(dt, allObjects)
	if not attacker then
		return
	end

	local range, cooldown, damage = getWeaponStats(attacker.weaponSprite)

	if attacker.cooldownTimer > 0 then
		attacker.cooldownTimer = attacker.cooldownTimer - dt
	end

	local ws = attacker.weaponSprite
	if ws and ws.tweens and ws.tweens.swing_angle and ws.tweens.swing_angle:isFinished() then
		ws.tweens.swing_angle = nil
	end

	if attacker.cooldownTimer > 0 then
		return
	end

	local ax, ay = attacker.sprite.x, attacker.sprite.y
	local nearest = nil
	local nearestDist = range

	for _, entry in ipairs(allObjects) do
		local sprite = entry.instance
		if sprite then
			for _, comp in ipairs(sprite.components or {}) do
				if comp.type == "destructible" and comp.hp > 0 then
					local dx = sprite.x - ax
					local dy = sprite.y - ay
					local dist = math.sqrt(dx * dx + dy * dy)
					if dist <= nearestDist then
						nearest = sprite
						nearestDist = dist
					end
					break
				end
			end
		end
	end

	if not nearest then
		return
	end

	attacker.cooldownTimer = cooldown

	if ws then
		local swingTween = TweenModule.Tween.new("swing_angle", -30, 30, attacker._swingDuration, swingEase)
		ws.tweens.swing_angle = swingTween
		swingTween:start()
	end

	for _, comp in ipairs(nearest.components or {}) do
		if comp.type == "destructible" and comp.takeDamage then
			comp:takeDamage(damage)
			break
		end
	end
end

return AttackSystem
