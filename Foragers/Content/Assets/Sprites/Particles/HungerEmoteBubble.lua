return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = -4,
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
		},

		{
			component = "tween",
			tweens = {
				{ target = "scale_x", from = 0, to = 1, duration = 0.4, curve = "OutBack" },
				{ target = "scale_y", from = 2, to = 1, duration = 0.6, curve = "OutBack" },
				{ target = "angle", from = -45, to = 0, duration = 0.5, curve = "OutBack" },
			},

			tags = {
				hide = {
					{ target = "scale_x", from = 1, to = 0.5, duration = 0.75, curve = "InOutBack" },
					{ target = "scale_y", from = 1, to = 0, duration = 0.75, curve = "InOutBack" },
				},
			},
		},
	},
}
