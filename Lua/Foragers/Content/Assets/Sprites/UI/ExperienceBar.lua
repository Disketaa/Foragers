return {
	frameWidth = 23,
	frameHeight = 23,
	pivotX = 0.5,
	pivotY = 0.5,
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
			label = {
				font = "Content.Assets.Sprites.UI.Fonts.Tinylorder",
				charSpacing = -4,
				color = { 0.95, 0.68, 0.87 },
				offsetX = 1,
				offsetY = -1,
			},
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
