return {
	object = "rock",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	pivotY = 0.75,
	components = {
		{
			component = "tile",
			spriteSheet = "Content/Assets/Sprites/Props/Rocks.png",
			columns = 3,
			rows = 1,
			tileMap = { 0, 1, 2 },
			variants = {
				[0] = { 0, 1, 2 },
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
