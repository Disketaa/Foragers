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
			offsetY = 12,
		},

		{
			component = "ambient",
			duration = "10..20",
			fadeInDuration = 1,
			fadeOutDuration = 1,
			wanderingSpeed = 2,
			changeDirectionInterval = "5..15",
		},
	},
}