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
	local range, cooldown, damage, attackSpeed, baseAttackSpeed
	if ps then
		range = ps:getRange()
		cooldown = ps:getCooldown()
		damage = ps:getDamage()
		attackSpeed = ps:getAttackSpeed()
		baseAttackSpeed = ps:getBaseAttackSpeed()
	end
	local swing = weapon and weapon.swing
	return range, cooldown, damage, swing, attackSpeed, baseAttackSpeed
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
	local range, cooldown, damage, swing, attackSpeed, baseAttackSpeed = getWeaponData(ws, attacker.sprite)
	-- Higher attack speed => faster tool travel + swing, so the cooldown actually
	-- pays off instead of being eaten by fixed follow/swing timing. Reference is
	-- level-1 attack speed, so level 1 keeps its current feel (speedScale == 1).
	local speedScale = 1
	if baseAttackSpeed and baseAttackSpeed > 0 and attackSpeed and attackSpeed > 0 then
		speedScale = attackSpeed / baseAttackSpeed
	end
	local rangeSq = range * range
	local weaponFollow = getWeaponFollow(ws)
	local ax, ay = attacker.sprite.x, attacker.sprite.y

	if attacker.cooldownTimer > 0 then
		attacker.cooldownTimer = attacker.cooldownTimer - dt
	end

	cleanupTween(ws, "swingAngle")

	local targetValid = false
	if attacker.currentTarget then
		local dc = attacker.currentTarget:findComponent("destructible", function(c) return c.hp > 0 and not c.guarded end)
		if dc then
			local dx = attacker.currentTarget.x - ax
			local dy = attacker.currentTarget.y - ay
			if dx * dx + dy * dy <= rangeSq then
				targetValid = true
			end
		end
		if not targetValid and weaponFollow then
			local committed = attacker._arrived and attacker.cooldownTimer > 0
			if not committed and not (ws and ws.tweens and ws.tweens.swingAngle) then
				weaponFollow:recall(weaponFollow.smoothnessX / speedScale)
				attacker.currentTarget = nil
				attacker.damageTimer = nil
			end
		end
	end

	if not attacker.currentTarget then
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
		if #candidates > 0 then
			local chosen = candidates[love.math.random(1, #candidates)]
			-- Deploy to far side of target: away from character, not from weapon
			local deployDir = (attacker.sprite.x < chosen.x) and 1 or -1
			if weaponFollow then
				weaponFollow:deployTo(chosen, swing.offsetX, swing.offsetY, swing.smoothness / speedScale, deployDir)
			end
			attacker.currentTarget = chosen
			attacker._deployDir = deployDir
			attacker._arrived = false
			if ws then
				-- Crosshair targets the host (stone) position, not the overlay
				-- child's offset position (snail sits offsetY above the stone).
				local hx, hy = chosen.hostParent and chosen.hostParent.x or chosen.x, chosen.hostParent and chosen.hostParent.y or chosen.y
				ws._lastHitX = hx
				ws._lastHitY = hy
				-- Redirect the targeted object's own crosshair to the host position
				-- so overlay children (berries, snail) show it on the parent, not
				-- their offset. Supports future multi-prop / splash targeting.
				chosen._lastHitX = hx
				chosen._lastHitY = hy
				chosen:emit(Events.TARGET_SELECTED)
			end
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
				local dc = attacker.currentTarget:findComponent("destructible", function(c) return c.hp > 0 and c.takeDamage and not c.guarded end)
				if dc then
					dc:takeDamage(damage)
					if dc.hp <= 0 and ws then
						ws:emit(Events.PROP_BROKEN)
					end
					attacker.currentTarget:emit(Events.PROP_HIT, damage)
					if ws then
						local hx, hy =
							attacker.currentTarget.hostParent and attacker.currentTarget.hostParent.x or attacker.currentTarget.x,
							attacker.currentTarget.hostParent and attacker.currentTarget.hostParent.y or attacker.currentTarget.y
						ws._lastHitX = hx
						ws._lastHitY = hy
						ws:emit(Events.PROP_HIT)
					end
					if attacker.sprite then
						attacker.sprite:emit(Events.PROP_HIT, damage)
					end
				end
			end
		end
	end

	if not attacker.currentTarget or attacker.cooldownTimer > 0 or attacker.damageTimer then
		return
	end

	attacker.cooldownTimer = cooldown
	attacker.damageTimer = swing.duration / speedScale

	-- Swing toward target: opposite of deploy direction
	local dir = -attacker._deployDir
	local rawEase = TweenModule.Easing[swing.curve] or TweenModule.Easing.OutSine
	local easeFunc = swingCurve(rawEase)
	local angleTween = TweenModule.Tween.new("swingAngle", swing.angleFrom * dir, swing.angleTo * dir, swing.duration / speedScale, easeFunc)
	angleTween._smoothness = swing.smoothness
	ws.tweens.swingAngle = angleTween
	angleTween:start()
	ws:emit(Events.FLIPPED, attacker._deployDir == -1)
	ws._lastHitX = nil
	ws._lastHitY = nil
	ws:emit(Events.SWING)
end

return AttackSystem