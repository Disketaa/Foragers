return {
	extends = "Content.Assets.Sprites.Ambient._Ambients",
	frameWidth = 1,
	frameHeight = 1,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "8..12", loop = true },
			},
		},

		{
			component = "ambient",
			despawnOnDay = true,
			despawnOnNight = false,
			duration = 15,
			fadeOutDuration = 1.5,
			wanderingSpeed = 8,
			interval = "2..4",
		},
	},
}