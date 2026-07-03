return {
	object = "grass_tile",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	pivotY = 0.5,
	components = {
		{
			component = "tileable",
			spriteSheet = "Content/Assets/Sprites/World/GrassTiles.png",
			columns = 4,
			rows = 6,
			tileMap = { 0, 12, 1, 13, 4, 8, 5, 9, 3, 15, 2, 14, 7, 11, 6, 10 },
			variants = {
				[10] = { 10, 16, 17, 17, 18, 18, 19, 19, 19, 19, 20, 21, 22, 23 },
			},
		},
		{
			component = "collidable",
			mode = "collision",
			collisionWidth = 8,
			collisionHeight = 8,
			offsetX = -4,
			offsetY = -4,
			visible = true,
			object = "grass_tile",
		},
	},
}
