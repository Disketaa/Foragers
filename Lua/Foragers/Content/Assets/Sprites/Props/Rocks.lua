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
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {
				prop_hit = {
					"Content/Assets/Sounds/Steps/Events/RockHit.ogg",
				},
				prop_broken = {
					"Content/Assets/Sounds/Steps/Events/RockBreak.ogg",
				},
			},
		},
		{
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "scale_x", from = 0.5, to = 1, duration = 0.9, curve = "BackOut" },
					{ target = "scale_y", from = 1.5, to = 1, duration = 0.4, curve = "BackOut" },
				},
			},
		},
		{
			component = "spritesheet",
			spriteSheet = "Content/Assets/Sprites/Props/Rocks.png",
			columns = 3,
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
