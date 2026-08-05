return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = "center",
	pivotY = "center",
	layer = 0,
	sortOffsetY = 4,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..8", loop = true },
			},
		},

		{
			component = "follow",
			followRadius = 25,
			followDelay = 0.5,
			offsetY = -3,
			accelerate = "5",
			smoothness = "0.25..0.3",
		},

		{
			component = "tween",
			tweens = {
				{ target = "x", from = 0, to = "-8..8", duration = "0.4..0.5", curve = "OutCubic" },
				{ target = "y", from = 0, to = "-8..8", duration = "0.4..0.5", curve = "OutCubic" },
				{ target = "scale_x", from = 0, to = 1, duration = 1.5, curve = "OutBack" },
				{ target = "scale_y", from = 2, to = 1, duration = "0.75..1.25", curve = "OutBack" },
				{ target = "brightness", from = 1, to = 0.5, duration = 0.66, curve = "InOutCubic" },
			},
			tags = {
				arrived = {
					destroyOnComplete = true,
					{ target = "scale_x", from = 1, to = 0, duration = 0.3, curve = "InBack" },
					{ target = "scale_y", from = 1, to = 0.5, duration = 0.3, curve = "InBack" },
					{ target = "angle", from = 0, to = 0, duration = 0.3 },
					{ target = "brightness", from = 0.5, to = 1, duration = 0.3, curve = "OutCubic" },
				},
			},
		},

		{
			component = "silhouette",
		},

		{
			component = "shader",
			shaders = { "Brightness" },
		},
	},
}
