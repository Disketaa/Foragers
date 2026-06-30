return {
	tag = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = 0.5,
	pivotY = 0.75,
	components = {
		{
			component = "Animatable",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			animations = {
				{ name = "idle", frames = 4, speed = 4, loop = true },
				{ name = "run", frames = 4, speed = 8, loop = true },
				{ name = "swim", frames = 4, speed = 6, loop = true },
				{ name = "death", frames = 4, speed = 5, loop = false },
			},
		},
		{
			component = "Controllable",
			movementSpeed = 64,
			mouseControl = {
				slowdownRadius = 30,
			},
		},
	},
}
