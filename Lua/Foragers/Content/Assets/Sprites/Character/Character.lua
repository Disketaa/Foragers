return {
	object = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = 0.5,
	pivotY = 0.75,
	components = {
		{
			component = "controllable",
			movementSpeed = 50,
			swimmingSpeed = 30,
			keyboardControl = { keys = { up = "w", down = "s", left = "a", right = "d" } },
			mouseControl = { slowdownRadius = 15 },
		},
		{
			component = "collidable",
			mode = "solid_and_detect",
			collisionWidth = 4,
			collisionHeight = 4,
			offsetX = 0,
			offsetY = -2,
			visible = false,
		},
		{
			component = "animatable",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			tags = { idle = "idle", moving = "run", swimming = "swim" },
			animations = {
				idle = { row = 1, frames = 4, speed = 4, loop = true },
				run = { row = 2, frames = 4, speed = 8, loop = true },
				swim = { row = 3, frames = 4, speed = 4, loop = true },
				death = { row = 4, frames = 4, speed = 5, loop = false },
			},
		},
		{
			component = "tweenable",
			tags = {
				flip = {
					{ target = "scale_x", from = 0.75, to = 1.0, duration = 0.3, curve = "BackOut" },
					{ target = "scale_y", from = 1.25, to = 1.0, duration = 0.3, curve = "BackOut" },
				},
				splash = {
					{ target = "scale_x", from = 1.25, to = 1.0, duration = 0.75, curve = "BackOut" },
					{ target = "scale_y", from = 0.75, to = 1.0, duration = 0.5, curve = "BackOut" },
				},
			},
		},
	},
}
