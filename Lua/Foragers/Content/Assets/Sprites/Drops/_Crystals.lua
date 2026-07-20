return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.6,
	pivotY = 0.5,
	layer = 3,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4...8", loop = true },
			},
		},

		{
			component = "follow",
			followRadius = 25,
			followDelay = 0.5,
			smoothness = "0.25...0.3",
		},

		{
			component = "tween",
			tweens = {
				{ target = "brightness", from = 1, to = 0.5, duration = 0.66, curve = "InOutCubic" },
				{ target = "x", from = 0, to = "-8...8", duration = "0.4...0.5", curve = "OutCubic" },
				{ target = "y", from = 0, to = "-8...8", duration = "0.4...0.5", curve = "OutCubic" },
				{ target = "scale_x", from = 0, to = 1, duration = 1.5, curve = "OutBack" },
				{ target = "scale_y", from = 2, to = 1, duration = "0.75...1.25", curve = "OutBack" },
			},
			tags = {
				arrived = {
					destroyOnComplete = true,
					{ target = "brightness", from = 0.5, to = 1, duration = 0.3, curve = "OutCubic" },
					{ target = "scale_x", from = 1, to = 0, duration = 0.3, curve = "InOutCubic" },
					{ target = "scale_y", from = 1, to = 2, duration = 0.3, curve = "InOutCubic" },
				},
			},
		},

		{
			component = "sound",
			volume = 0.3,
			pitchRandomness = 0.4,
			tags = {
				arrived = { "Content/Assets/Sounds/Steps/Events/CrystalPling.ogg" },
			},
		},

		{
			component = "shader",
			shaderName = "Brightness",
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/CrystalSpark",
			interval = 0.2,
			layer = "below",
		},
	},
}
