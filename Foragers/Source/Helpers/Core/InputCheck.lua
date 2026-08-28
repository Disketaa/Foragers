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

return InputCheck