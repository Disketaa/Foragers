return {
	extends = "Content.Assets.Sprites.Props.__Props",
	object = "vegetable",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = "center",
	pivotY = "center",
	layer = 0,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "6..8" },
			},
		},

		{
			component = "destructible",
			hp = 15,
		},

		{
			component = "silhouette",
			mode = "silhouette",
		},
	},
}