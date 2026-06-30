return {
	tag = "player",
	components = {

		{
			type = "AnimatableSprite",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			frameWidth = 16,
			frameHeight = 16,
			pivotX = 0.5,
			pivotY = 1.0,
			animations = {
				{ name = "idle", frames = 4, speed = 4, loop = true },
				{ name = "run", frames = 4, speed = 8, loop = true },
				{ name = "swim", frames = 4, speed = 6, loop = true },
				{ name = "death", frames = 4, speed = 5, loop = false },
			},
		},

		{
			type = "Controllable",
			movementSpeed = 64,
		},
	},
}
