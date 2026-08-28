local Options = require("Source.Helpers.Systems.Options")

local InputCheck = {}

function InputCheck.keyboardDown(kbKeys)
	return not not (#kbKeys > 0 and love.keyboard.isDown(unpack(kbKeys)))
end

function InputCheck.gamepadButtonDown(joystick, btnKeys)
	return not not (#btnKeys > 0 and joystick:isGamepadDown(unpack(btnKeys)))
end

function InputCheck.gamepadAxisActive(joystick, axes, deadzone)
	for _, entry in ipairs(axes) do
		local axis, sign = entry[1], entry[2]
		local v = joystick:getGamepadAxis(axis)
		if sign > 0 and v > deadzone then return true end
		if sign < 0 and v < -deadzone then return true end
	end
	return false
end

function InputCheck.isDirectionActive(binding)
	if binding.keyboard and InputCheck.keyboardDown(binding.keyboard) then
		return true
	end
	local gp = binding.gamepad
	if gp then
		for _, j in ipairs(love.joystick.getJoysticks()) do
			if j:isGamepad() then
				if gp.buttons and InputCheck.gamepadButtonDown(j, gp.buttons) then return true end
				if gp.axes and InputCheck.gamepadAxisActive(j, gp.axes, Options.gamepadDeadzone) then return true end
			end
		end
	end
	return false
end

return InputCheck