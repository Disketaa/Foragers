return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	pivotY = 0.75,
	sortOffsetY = 2,
	layer = 0,
	components = {
		{
			component = "destructible",
			hp = 3,
		},
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
					{ target = "angle", from = "-15 | 15", to = 0, duration = 2.5, curve = "BackOut" },
				},
			},
		},
		{
			component = "sound",
			volume = 0.7,
			tags = {
				bush_touch = {
					"Content/Assets/Sounds/Steps/Events/BushHit.ogg",
				},
			},
		},
	},
}
