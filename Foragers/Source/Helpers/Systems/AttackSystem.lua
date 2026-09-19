local TweenModule = require("Source.Sprite.Components.Tween")
local Events = require("Source.Helpers.Core.Events")

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

local function getWeaponData(weaponSprite, playerSprite)
	local weapon = weaponSprite and weaponSprite:findComponent("weapon")
	local ps = playerSprite and playerSprite:findComponent("player_stats")
	local range, cooldown, damage, attackSpeed
	if ps then
		range = ps:getAttackRange()
		cooldown = ps:getCooldown()
		damage = ps:getDamage()
		attackSpeed = ps:getAttackSpeed()
	end
	local swing = weapon and weapon.swing
	return range, cooldown, damage, swing, attackSpeed
end

local function getWeaponFollow(ws)
	return ws and ws:findComponent("follow")
end

local function cleanupTween(ws, key)
	if ws and ws.tweens and ws.tweens[key] and ws.tweens[key]:isFinished() then
		ws.tweens[key] = nil
	end
end

local AttackSystem = {}

-- Reference attack speed (attacks/sec) the weapon smoothness values were tuned
-- against. Default PlayerStats.attackSpeed = 20 resolves to 2 APS, so that is
-- the baseline: speedScale = current APS / 2.
local REFERENCE_ATTACK_SPEED = 2

local function computeScales(attackSpeed)
	local speedScale = 1
	if attackSpeed and attackSpeed > 0 then
		speedScale = attackSpeed / REFERENCE_ATTACK_SPEED
	end
	local travelScale = speedScale > 1 and speedScale * speedScale or 1
	return speedScale, travelScale
end

local function tickCooldown(atk, dt)
	if atk.cooldownTimer > 0 then
		atk.cooldownTimer = atk.cooldownTimer - dt
	end
end

local function revalidateTarget(atk, ws, ax, ay, rangeSq, weaponFollow, travelScale)
	if not atk.currentTarget then
		return false
	end
	local dc = atk.currentTarget:findComponent("destructible", function(c) return c.hp > 0 and not c.guarded end)
	if dc then
		local dx = atk.currentTarget.x - ax
		local dy = atk.currentTarget.y - ay
		if dx * dx + dy * dy <= rangeSq then
			return true
		end
	end
	if weaponFollow then
		local committed = atk._arrived and atk.cooldownTimer > 0
		if not committed and not (ws and ws.tweens and ws.tweens.swingAngle) then
			weaponFollow:recall(weaponFollow.smoothnessX / travelScale)
			atk.currentTarget = nil
			atk.damageTimer = nil
		end
	end
	return false
end

local function acquireTarget(atk, ws, allObjects, ax, ay, rangeSq, weaponFollow, swing, travelScale)
	local candidates = {}
	for _, entry in ipairs(allObjects) do
		local sprite = entry.instance
		if sprite and sprite:findComponent("destructible", function(c) return c.hp > 0 and not c.guarded end) then
			local dx = sprite.x - ax
			local dy = sprite.y - ay
			if dx * dx + dy * dy <= rangeSq then
				table.insert(candidates, sprite)
			end
		end
	end
	if #candidates == 0 then
		return
	end
	local chosen = candidates[love.math.random(1, #candidates)]
	local deployDir = (atk.sprite.x < chosen.x) and 1 or -1
	if weaponFollow then
		weaponFollow:deployTo(chosen, swing.offsetX, swing.offsetY, swing.smoothness / travelScale, deployDir)
	end
	atk.currentTarget = chosen
	atk._deployDir = deployDir
	atk._arrived = false
	if ws then
		local hx, hy = chosen.hostParent and chosen.hostParent.x or chosen.x, chosen.hostParent and chosen.hostParent.y or chosen.y
		ws._lastHitX = hx
		ws._lastHitY = hy
		chosen._lastHitX = hx
		chosen._lastHitY = hy
		chosen:emit(Events.TARGET_SELECTED)
	end
end

local function checkArrival(atk, ws, swing)
	local dir = atk._deployDir or ((ws.x < atk.currentTarget.x) and -1 or 1)
	local destX = atk.currentTarget.x + dir * swing.offsetX
	local destY = atk.currentTarget.y + swing.offsetY
	if math.abs(ws.x - destX) <= 2 and math.abs(ws.y - destY) <= 2 then
		atk._arrived = true
		return true
	end
	return false
end

local function resolveDamage(atk, ws, damage, dt)
	if not atk.damageTimer then
		return
	end
	atk.damageTimer = atk.damageTimer - dt
	if atk.damageTimer > 0 then
		return
	end
	atk.damageTimer = nil
	if not atk.currentTarget then
		return
	end
	local dc = atk.currentTarget:findComponent("destructible", function(c) return c.hp > 0 and c.takeDamage and not c.guarded end)
	if dc then
		dc:takeDamage(damage)
		if dc.hp <= 0 and ws then
			ws:emit(Events.PROP_BROKEN)
		end
		atk.currentTarget:emit(Events.PROP_HIT, damage)
		if ws then
			local hx, hy =
				atk.currentTarget.hostParent and atk.currentTarget.hostParent.x or atk.currentTarget.x,
				atk.currentTarget.hostParent and atk.currentTarget.hostParent.y or atk.currentTarget.y
			ws._lastHitX = hx
			ws._lastHitY = hy
			ws:emit(Events.PROP_HIT)
		end
		if atk.sprite then
			atk.sprite:emit(Events.PROP_HIT, damage)
		end
	end
end

local function startSwing(atk, ws, swing, cooldown, speedScale)
	atk.cooldownTimer = cooldown
	atk.damageTimer = swing.duration / speedScale

	local dir = -atk._deployDir
	local rawEase = TweenModule.Easing[swing.curve] or TweenModule.Easing.OutSine
	local easeFunc = swingCurve(rawEase)
	local angleTween = TweenModule.Tween.new("swingAngle", swing.angleFrom * dir, swing.angleTo * dir, swing.duration / speedScale, easeFunc)
	angleTween._smoothness = swing.smoothness
	ws.tweens.swingAngle = angleTween
	angleTween:start()
	ws:emit(Events.FLIPPED, atk._deployDir == -1)
	ws._lastHitX = nil
	ws._lastHitY = nil
	ws:emit(Events.SWING)
end

function AttackSystem.registerAttacker(sprite, weaponSprite)
	attacker = {
		sprite = sprite,
		weaponSprite = weaponSprite,
		cooldownTimer = 0,
		currentTarget = nil,
		_arrived = false,
	}
end

--- Drop the registered attacker (e.g. player death) so no further swings or
--- damage resolve. Idempotent.
function AttackSystem.clearAttacker()
	attacker = nil
end

function AttackSystem.update(dt, allObjects)
	if not attacker or not attacker.sprite then
		return
	end

	local ws = attacker.weaponSprite
	local range, cooldown, damage, swing, attackSpeed = getWeaponData(ws, attacker.sprite)
	local speedScale, travelScale = computeScales(attackSpeed)
	local rangeSq = range * range
	local weaponFollow = getWeaponFollow(ws)
	local ax, ay = attacker.sprite.x, attacker.sprite.y

	tickCooldown(attacker, dt)

	cleanupTween(ws, "swingAngle")

	if attacker.currentTarget and not revalidateTarget(attacker, ws, ax, ay, rangeSq, weaponFollow, travelScale) then
		attacker.currentTarget = nil
		attacker.damageTimer = nil
		attacker._arrived = false
	end
	if not attacker.currentTarget then
		acquireTarget(attacker, ws, allObjects, ax, ay, rangeSq, weaponFollow, swing, travelScale)
	end

	if attacker.currentTarget and not attacker._arrived then
		if not checkArrival(attacker, ws, swing) then
			return
		end
	end

	resolveDamage(attacker, ws, damage, dt)

	if not attacker.currentTarget or attacker.cooldownTimer > 0 or attacker.damageTimer then
		return
	end
	startSwing(attacker, ws, swing, cooldown, speedScale)
end

return AttackSystem