return {
	object = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = "center",
	pivotY = 12,
	sortOffsetY = 0,
	layer = 0,
	components = {
		{
			component = "player_stats",
			movementSpeed = 50,
			swimmingSpeed = 30,
			level = 1,
			experience = 0,
			xpCurve = { base = 10, growth = 1.35 },
			maxSatiety = 100,
			satiety = 100,
			satietyDrain = { run = 0.5, swim = 0.75, idle = 0.1, float = 0.1 },
			lowSatietyPercent = 33,
			lowSatietyZoom = 2,
			critChance = 0,
			critMult = 1.5,
		},

		{
			component = "spritesheet",
			columns = 4,
			rows = 5,
			animations = {
				idle = { row = 1, frames = 4, speed = 4, loop = true },
				run = { row = 2, frames = 4, speed = 8, loop = true },
				float = { row = 3, frames = 4, speed = 4, loop = true },
				swim = { row = 4, frames = 4, speed = 4, loop = true },
				death = { row = 5, frames = 4, speed = 5, loop = false },
			},
		},

		{
			component = "shadow",
			width = 12,
			height = 4,
			offsetX = 2,
			offsetY = 0,
		},

		{
			component = "control",
		},

		{
			component = "collision",
			mode = "solid_and_detect",
			collisionWidth = 2,
			collisionHeight = 2,
			offsetX = 0,
			offsetY = -2,
		},

		{
			component = "scroll_to",
			chunkSize = 64,
			smoothness = 10,
		},

		{
			component = "tween",
			tags = {
				flip = {
					{ target = "scale_x", from = 0.75, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "scale_y", from = 1.25, to = 1, duration = 0.3, curve = "OutBack" },
				},

				splash = {
					{ target = "scale_x", from = 1.25, to = 1, duration = 0.75, curve = "OutBack" },
					{ target = "scale_y", from = 0.75, to = 1, duration = 0.5, curve = "OutBack" },
				},
				pickup = { { target = "tint_mix", from = 0.5, to = 0, duration = 0.5, curve = "OutCubic" } },
			},
		},

		{
			component = "particle_emitter",
			offsetX = 0,
			offsetY = 0,
			stepInterval = 2,
			spawnOn = { run = true },
			particle = "Content/Assets/Sprites/Particles/Dust.lua",
			inheritFlip = true,
			layer = "below",
		},

		{
			component = "text_emitter",
			event = "pickup",
			offsetX = -5,
			moveX = "-15|15",
			offsetY = -3,
			moveY = -30,
			destroyCurve = "InCubic",
			color = { 0.6, 1, 0.6 },
			gravity = 130,
			duration = 0.7,
			destroy = "scale",
		},

		{
			component = "sound",
			stepInterval = 2,
			volume = 0.5,
			pitch = 1,
			pitchRandomness = 0.15,
			tags = {
				run = {
					"Content/Assets/Sounds/Steps/Grass1.ogg",
					"Content/Assets/Sounds/Steps/Grass2.ogg",
					"Content/Assets/Sounds/Steps/Grass3.ogg",
					"Content/Assets/Sounds/Steps/Grass4.ogg",
				},

				swim = {
					"Content/Assets/Sounds/Steps/Water1.ogg",
					"Content/Assets/Sounds/Steps/Water2.ogg",
					"Content/Assets/Sounds/Steps/Water3.ogg",
				},
				water_in = { "Content/Assets/Sounds/Events/WaterIn.ogg" },
				water_out = { "Content/Assets/Sounds/Events/WaterOut.ogg" },
			},
		},

		{
			component = "silhouette",
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.8, 0.5, 0.7 }, u_additive = 1 } },
			},
		},
	},
}
