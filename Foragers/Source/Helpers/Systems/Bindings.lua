local Bindings = {}

--- `binding` is an Options keybind table ({keyboard, mouse, gamepad={buttons}});
--- `inputType` is "keyboard" | "mouse" | "gamepad".
function Bindings.matches(binding, inputType, value)
	if not binding then
		return false
	end
	local list
	if inputType == "keyboard" then
		list = binding.keyboard
	elseif inputType == "mouse" then
		list = binding.mouse
	elseif inputType == "gamepad" then
		list = binding.gamepad and binding.gamepad.buttons
	end
	if list then
		for _, v in ipairs(list) do
			if v == value then
				return true
			end
		end
	end
	return false
end

return Bindings