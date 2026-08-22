return {
	frameWidth = 4,
	frameHeight = 4,
	pivotX = 0,
	pivotY = 0,
	components = {
		{
			component = "tween",
			tags = {
				show = { { target = "alpha", from = 0, to = 1, duration = 0.2, curve = "OutCubic" } },
				hide = { { target = "alpha", from = 1, to = 0, duration = 0.2, curve = "OutCubic" } },
			},
		},

		{
			component = "cursor",
			type = "arrow",
			moveThreshold = 0.5,
			hideDelay = 3,
		},
	},
}
