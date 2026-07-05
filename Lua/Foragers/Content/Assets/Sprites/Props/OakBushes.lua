return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	pivotY = 0.75,
	sortOffsetY = 2,
	layer = 0,
	components = {
		{
			component = "collision",
			mode = "slowdown",
			slowdown = 0.5,
			collisionWidth = 6,
			collisionHeight = 6,
			offsetX = 0,
			offsetY = 0,
			visible = false,
		},
		{
			component = "tween",
			tags = {
				bush_touch = {
					{ target = "scale_x", from = 0.75, to = 1.0, duration = 0.5, curve = "BackOut" },
					{ target = "scale_y", from = 1.25, to = 1.0, duration = 1.4, curve = "BackOut" },
					{ target = "angle", from = "-15 | 15", to = 0, duration = 0.7, curve = "BackOut" },
				},
			},
		},
	},
}
