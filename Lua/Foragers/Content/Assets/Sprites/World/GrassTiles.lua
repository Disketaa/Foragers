return {
	object = "grass_tile",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	pivotY = 0.5,
	components = {
		{
			component = "tile",
			spriteSheet = "Content/Assets/Sprites/World/GrassTiles.png",
			columns = 4,
			rows = 6,
			tileMap = { 0, 12, 1, 13, 4, 8, 5, 9, 3, 15, 2, 14, 7, 11, 6, 10 },
			variants = {
				[10] = { 10, 16, 17, 17, 18, 18, 19, 19, 19, 19, 20, 21, 22, 23 },
			},
		},
		{
			component = "collision",
			mode = "solid",
			collisionWidth = 8,
			collisionHeight = 8,
			offsetX = 0,
			offsetY = 0,
			visible = false,
		},
	},
}
