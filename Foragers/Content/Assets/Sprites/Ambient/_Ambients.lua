return {
	object = "ambient",
	frameWidth = 3,
	frameHeight = 3,
	pivotX = "center",
	pivotY = "center",
	layer = 3,
	components = {
		{
			component = "shadow",
			width = 3,
			height = 1,
			offsetX = 1,
			offsetY = 8,
		},

		{
			component = "ambient",
			despawnOnNight = true,
			duration = 2,
			fadeOutDuration = 0.5,
			wanderingSpeed = 10,
			interval = "1.5..3",
		},
	},
}