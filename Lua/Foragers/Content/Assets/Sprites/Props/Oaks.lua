return {
	frameWidth = 24,
	frameHeight = 32,
	pivotX = 0.5,
	pivotY = 0.9,
	sortOffsetY = 3,
	layer = 0,
	components = {
		{
			component = "destructible",
			hp = 7,
		},
		{
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "scale_x", from = 0.8, to = 1, duration = 0.9, curve = "BackOut" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.4, curve = "BackOut" },
				},
			},
		},
		{
			component = "collision",
			mode = "solid",
			collisionWidth = 6,
			collisionHeight = 6,
			offsetX = 0,
			offsetY = 0,
			visible = false,
		},
	},
}
