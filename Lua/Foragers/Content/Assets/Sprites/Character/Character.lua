return {
	tag = "Player",
	components = {

		{
			type = "AnimatableSprite",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			frameWidth = 16,
			frameHeight = 16,
			animations = {
				{ name = "Idle", frames = 4, speed = 4, loop = true },
				{ name = "Run", frames = 4, speed = 8, loop = true },
				{ name = "Swim", frames = 4, speed = 6, loop = true },
				{ name = "Death", frames = 4, speed = 5, loop = false },
			},
		},

		{
			type = "Controllable",
			movementSpeed = 64,
		},
	},
}
