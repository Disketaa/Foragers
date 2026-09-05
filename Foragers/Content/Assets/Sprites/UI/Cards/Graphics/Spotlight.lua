return {
	object = "spotlight",
	frameWidth = 160,
	frameHeight = 160,
	pivotX = "center",
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 48, speed = 32, loop = true },
			},
		},

		{
			component = "tween",
			tags = {
				show = {
					{ target = "scaleX", from = 1.25, to = 1, duration = 0.5, curve = "OutCubic" },
					{ target = "scaleY", from = 1.25, to = 1, duration = 0.5, curve = "OutCubic" },
				},

				hide = {
					{ target = "scaleX", from = 1, to = 0, duration = 0.5, curve = "OutCubic" },
					{ target = "scaleY", from = 1, to = 0, duration = 0.5, curve = "OutCubic" },
				},
			},
		},
	},
}