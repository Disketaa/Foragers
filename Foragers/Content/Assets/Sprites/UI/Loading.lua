return {
	object = "loading",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 3,
	pivotY = 3,
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 16,
		},

		{
			component = "tween",
			tweens = {
				{ target = "scale_x", set = 0 },
				{ target = "scale_y", set = 0 },
			},

			tags = {
				loading_in = {
					{ target = "scale_x", from = 0, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "scale_y", from = 0, to = 1, duration = 0.3, curve = "OutBack" },
				},

				loading_out = {
					{ target = "scale_x", from = 1, to = 0, duration = 0.2, curve = "InBack" },
					{ target = "scale_y", from = 1, to = 0, duration = 0.2, curve = "InBack" },
				},
			},
		},

		{
			component = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "center",
		},
	},
}
