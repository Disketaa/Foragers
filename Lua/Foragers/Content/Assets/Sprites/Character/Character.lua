return {
	object = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = 0.5,
	pivotY = 0.75,
	sortOffsetY = 2,
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 4,
			rows = 4,
			tags = { idle = "idle", moving = "run", swimming = "swim" },
			animations = {
				idle = { row = 1, frames = 4, speed = 4, loop = true },
				run = { row = 2, frames = 4, speed = 8, loop = true },
				swim = { row = 3, frames = 4, speed = 4, loop = true },
				death = { row = 4, frames = 4, speed = 5, loop = false },
			},
		},

		{
			component = "collision",
			mode = "solid_and_detect",
			collisionWidth = 2,
			collisionHeight = 2,
			offsetX = 0,
			offsetY = -2,
			visible = false,
		},

		{
			component = "control",
			movementSpeed = 50,
			swimmingSpeed = 30,
			keyboardControl = { keys = { up = "w", down = "s", left = "a", right = "d" } },
			mouseControl = { slowdownRadius = 15 },
		},

		{
			component = "tween",
			tags = {
				flip = {
					{ target = "scale_x", from = 0.75, to = 1.0, duration = 0.3, curve = "OutBack" },
					{ target = "scale_y", from = 1.25, to = 1.0, duration = 0.3, curve = "OutBack" },
				},
				splash = {
					{ target = "scale_x", from = 1.25, to = 1.0, duration = 0.75, curve = "OutBack" },
					{ target = "scale_y", from = 0.75, to = 1.0, duration = 0.5,  curve = "OutBack" },
				},
			},
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Dust.lua",
			stepInterval = 2,
			offsetX = 0,
			offsetY = 0,
			inheritFlip = true,
			layer = "below",
			spawnOn = { moving = true },
		},

		{
			component = "sound",
			volume = 0.5,
			pitch = 1.0,
			pitchRandomness = 0.15,
			stepInterval = 2,
			tags = {
				moving = {
					"Content/Assets/Sounds/Steps/Grass1.ogg",
					"Content/Assets/Sounds/Steps/Grass2.ogg",
					"Content/Assets/Sounds/Steps/Grass3.ogg",
					"Content/Assets/Sounds/Steps/Grass4.ogg",
				},
				swimming = {
					"Content/Assets/Sounds/Steps/Water1.ogg",
					"Content/Assets/Sounds/Steps/Water2.ogg",
					"Content/Assets/Sounds/Steps/Water3.ogg",
				},
				water_in = { "Content/Assets/Sounds/Steps/Events/WaterIn.ogg" },
				water_out = { "Content/Assets/Sounds/Steps/Events/WaterOut.ogg" },
			},
		},
	},
}
