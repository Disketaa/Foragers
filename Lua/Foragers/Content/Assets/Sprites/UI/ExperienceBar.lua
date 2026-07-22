return {
	frameWidth = 23,
	frameHeight = 23,
	pivotX = 0,
	pivotY = 0,
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 40,
		},

		{
			component = "counter",
			mode = "progress",
			field = "experience",
			sourceType = "player_stats",
			smoothness = 0.3,
			curve = "InOutCubic",
		},

		{
			component = "ui",
			horizontal = "center",
			vertical = "top",
			offsetX = 0,
			offsetY = 0,
		},
	},
}
