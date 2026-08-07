return {
	frameWidth = 16,
	frameHeight = 16,
	pivotX = "center",
	pivotY = 12,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 8, speed = 12, loop = false },
			},
		},

		{
			component = "shake",
			magnitude = 3,
			decay = true,
			duration = 0.4,
		},
	},
}
