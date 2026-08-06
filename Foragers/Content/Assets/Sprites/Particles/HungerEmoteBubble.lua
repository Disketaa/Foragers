return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 2,
	pivotY = 6,
	components = {
		{
			component = "spritesheet",
		},
		{
			component = "tween",
			tweens = {
				{ target = "scale_x", from = 0, to = 1, duration = 0.4, curve = "OutBack" },
				{ target = "scale_y", from = 2, to = 1, duration = 0.4, curve = "OutBack" },
			},
			tags = {
				hide = {
					{ target = "scale_x", from = 1, to = 0, duration = 0.3, curve = "InCubic" },
					{ target = "scale_y", from = 1, to = 0, duration = 0.3, curve = "InCubic" },
				},
			},
		},
	},
}
