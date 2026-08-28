return {
	fullscreen = true,
	vsync = true,
	maxFps = 180,
	gamepadDeadzone = 0.5,
	mouseSlowdownRadius = 15,
	restartHoldDuration = 0.25,
	language = "English",
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
			mouse = { 5 },
			gamepad = {
				buttons = { "rightshoulder" },
			},
		},

		confirm = {
			keyboard = { "space" },
			gamepad = {
				buttons = { "a" },
			},
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

		toggleChat = {
			keyboard = { "return" },
		},

		toggleFullscreen = {
			keyboard = { "f11" },
		},
	},
}
