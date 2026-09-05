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
				{ target = "scaleX", set = 0 },
				{ target = "scaleY", set = 0 },
			},

			tags = {
				loading_in = {
					{ target = "scaleX", from = 0, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "scaleY", from = 0, to = 1, duration = 0.3, curve = "OutBack" },
				},

				loading_out = {
					{ target = "scaleX", from = 1, to = 0, duration = 0.2, curve = "InBack" },
					{ target = "scaleY", from = 1, to = 0, duration = 0.2, curve = "InBack" },
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