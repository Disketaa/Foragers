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
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {
				prop_hit = {
					"Content/Assets/Sounds/Steps/Events/WoodHit.ogg",
				},
				prop_broken = {
					"Content/Assets/Sounds/Steps/Events/WoodBreak.ogg",
				},
			},
		},
		{
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "scale_x", from = 0.8, to = 1, duration = 1.5, curve = "BackOut" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.6, curve = "BackOut" },
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
