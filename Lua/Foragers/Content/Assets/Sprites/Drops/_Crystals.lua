return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.6,
	pivotY = 0.5,
	layer = 3,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = 6, loop = true },
			},
		},

		{
			component = "tween",
			tweens = {
				{ target = "brightness", from = 1, to = 0.5,      duration = "0.3...0.6",   curve = "InOutCubic", loop = true, pingPong = true },
				{ target = "x",          from = 0, to = "-8...8", duration = "0.4...0.5",   curve = "OutCubic" },
				{ target = "y",          from = 0, to = "-8...8", duration = "0.4...0.5",   curve = "OutCubic" },
				{ target = "scale_x",    from = 0, to = 1,        duration = 1.5,           curve = "OutBack" },
				{ target = "scale_y",    from = 2, to = 1,        duration = "0.75...1.25", curve = "OutBack" },
			},
		},

		{
			component = "shader",
			shaderName = "Brightness",
		},
	},
}
