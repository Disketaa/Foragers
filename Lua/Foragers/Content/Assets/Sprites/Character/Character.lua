return {
	object = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = 0.5,
	pivotY = 0.75,
	components = {
		{
			component = "animatable",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			tags = { idle = "idle", moving = "run" },
			animations = {
				idle = { frames = 4, speed = 4, loop = true },
				run = { frames = 4, speed = 8, loop = true },
				swim = { frames = 4, speed = 6, loop = true },
				death = { frames = 4, speed = 5, loop = false },
			},
		},
		{
			component = "tweenable",
			tweens = {
				{ target = "scale_x", from = 0.75, to = 1.0, duration = 0.3, curve = "BackOut" },
				{ target = "scale_y", from = 1.25, to = 1.0, duration = 0.3, curve = "BackOut" },
			},
		},
		{
			component = "controllable",
			movementSpeed = 64,
			keyboardControl = { keys = { up = "w", down = "s", left = "a", right = "d" } },
			mouseControl = { slowdownRadius = 30 },
		},
	},
}
