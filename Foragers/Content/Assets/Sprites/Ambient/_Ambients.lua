return {
	object = "ambient",
	frameWidth = 3,
	frameHeight = 3,
	pivotX = "center",
	pivotY = "center",
	layer = 3,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "12..20", loop = true },
			},
		},

		{
			component = "shadow",
			width = 3,
			height = 1,
			offsetX = 1,
			offsetY = 8,
		},

		{
			component = "ambient",
			mode = "day",
			duration = "5..20",
			fadeInDuration = 2,
			fadeOutDuration = 0.5,
			wanderingSpeed = 5,
			changeDirectionInterval = "3..6",
		},
	},
}