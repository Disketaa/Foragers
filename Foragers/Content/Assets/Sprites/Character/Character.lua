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
			critChance = 0,
			critMult = 1.5,
			level = 1,
			experience = 0,
			xpCurve = { base = 10, growth = 1.35 },
			satiety = 100,
			maxSatiety = 100,
			satietyDrain = { run = 0.5, swim = 0.75, idle = 0.1, float = 0.1 },
			movementSpeed = 50,
			swimmingSpeed = 30,
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
			visible = false,
		},

		{
			component = "scroll_to",
			smoothness = 10,
			chunkSize = 64,
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
			particle = "Content/Assets/Sprites/Particles/Dust.lua",
			stepInterval = 2,
			offsetX = 0,
			offsetY = 0,
			inheritFlip = true,
			layer = "below",
			spawnOn = { run = true },
		},

		{
			component = "text_emitter",
			event = "pickup",
			color = { 0.6, 1, 0.6 },
			moveX = "-15|15",
			moveY = -30,
			gravity = 130,
			duration = 0.7,
			offsetX = -5,
			offsetY = -3,
			destroy = "scale",
			destroyCurve = "InCubic",
		},

		{
			component = "sound",
			volume = 0.5,
			pitch = 1,
			pitchRandomness = 0.15,
			stepInterval = 2,
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
