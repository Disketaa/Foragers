return {
	frameWidth = 4,
	frameHeight = 4,
	pivotX = 0,
	pivotY = 0,
	components = {
		{
			component = "tween",
			tags = {
				show = {
					{ target = "scale_x", from = 0, to = 1, duration = 0.12, curve = "OutBack" },
					{ target = "scale_y", from = 0, to = 1, duration = 0.12, curve = "OutBack" },
				},

				hide = {
					{ target = "scale_x", from = 1, to = 0, duration = 0.35, curve = "InQuad" },
					{ target = "scale_y", from = 1, to = 0, duration = 0.35, curve = "InQuad" },
				},
			},
		},

		{
			component = "cursor",
			moveThreshold = 1.5,
			hideDelay = 5.5,
		},
	},
}
