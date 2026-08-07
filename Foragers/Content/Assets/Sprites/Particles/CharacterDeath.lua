return {
	frameWidth = 16,
	frameHeight = 16,
	pivotX = "center",
	pivotY = 12,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 8, speed = 8, loop = false },
			},
		},

		{
			component = "shake",
			magnitude = 2,
			decay = true,
			duration = 0.2,
		},
	},
}
