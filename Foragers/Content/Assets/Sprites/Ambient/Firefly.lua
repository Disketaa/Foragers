return {
	extends = "Content.Assets.Sprites.Ambient._Ambients",
	frameWidth = 1,
	frameHeight = 1,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..8", loop = true },
			},
		},

		{
			component = "ambient",
			wanderingSpeed = 0.5,
		},

		{
			component = "emissive",
		},
	},
}