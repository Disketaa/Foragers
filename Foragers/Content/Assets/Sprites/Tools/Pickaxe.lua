return {
	frameWidth = 10,
	frameHeight = 10,
	pivotX = "center",
	pivotY = "bottom",
	layer = 0,
	sortOffsetY = 8,
	components = {
		{
			component = "shadow",
			width = 9,
			height = 3,
			offsetX = 1,
			offsetY = 4,
		},

		{
			component = "follow",
			offsetX = 6,
			offsetY = -3,
			smoothnessX = 0.5,
			smoothnessY = 0.5,
			leanAngle = -45,
			leanThreshold = 0.1,
			leanSmoothness = 0.5,
		},

		{
			component = "weapon",
			damage = 5,
			range = 20,
			cooldown = 0.5,
			swing = {
				angleFrom = 0,
				angleTo = -75,
				duration = 0.15,
				offsetX = -8,
				offsetY = -4,
				curve = "OutSine",
				smoothness = 0.5,
			},
		},

		{
			component = "shake",
			magnitude = 1,
			decay = true,
			duration = 0.2,
		},

		{
			component = "tween",
			tags = {
				prop_hit = { { target = "brightness", from = 1, to = 0.5, duration = 0.3, curve = "OutCubic" } },
			},
		},

		{
			component = "particle_emitter",
			angle = "0..360",
			count = "3..5",
			spawnOn = { prop_hit = true },
			particle = "Content/Assets/Sprites/Particles/Spark",
			layer = "below",
		},

		{
			component = "particle_emitter",
			spawnOn = { swing = true },
			particle = "Content/Assets/Sprites/Particles/Swing",
			inheritFlip = true,
			layer = "below",
		},

		{
			component = "silhouette",
			color = { 0.36, 0.44, 0.55, 0.75 },
		},

		{
			component = "shader",
			shaders = { "Brightness" },
		},
	},
}
