return {
	fullscreen = true,
	maxFps = 180,
	gamepadDeadzone = 0.5,
	mouseSlowdownRadius = 15,
	keybinds = {
		up = {
			keyboard = { "w", "up" },
			gamepad = {
				buttons = { "dpup" },
				axes = { { "lefty", -1 }, { "righty", -1 } },
			},
		},
		down = {
			keyboard = { "s", "down" },
			gamepad = {
				buttons = { "dpdown" },
				axes = { { "lefty", 1 }, { "righty", 1 } },
			},
		},
		left = {
			keyboard = { "a", "left" },
			gamepad = {
				buttons = { "dpleft" },
				axes = { { "leftx", -1 }, { "rightx", -1 } },
			},
		},
		right = {
			keyboard = { "d", "right" },
			gamepad = {
				buttons = { "dpright" },
				axes = { { "leftx", 1 }, { "rightx", 1 } },
			},
		},
		moveMouse = {
			mouse = { 1 },
		},
		restart = {
			keyboard = { "r" },
		},
		toggleDebug = {
			keyboard = { "f1" },
		},
		toggleGizmo = {
			keyboard = { "f2" },
		},
		toggleProfiler = {
			keyboard = { "f3" },
		},
		toggleFullscreen = {
			keyboard = { "f11" },
		},
	},
}
