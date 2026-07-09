return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
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
				{ target = "x",       from = 0, to = "-8...8", duration = "0.33...0.66", curve = "OutBack" },
				{ target = "y",       from = 0, to = "-8...8", duration = "0.33...0.66", curve = "OutBack" },
				{ target = "scale_x", from = 0, to = 1,        duration = 1.5,           curve = "OutBack" },
				{ target = "scale_y", from = 2, to = 1,        duration = "0.75...1.25", curve = "OutBack" },
			},
		},
	},
}
