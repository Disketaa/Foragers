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
			smoothnessY = 0.2,
			leanAngle = 45,
			leanThreshold = 0.1,
		},

		{
			component = "weapon",
			damage = 1,
			cooldown = 0.5,
			range = 20,
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
			duration = 0.2,
			decay = true,
		},

		{
			component = "tween",
			tags = {
				prop_hit = { { target = "brightness", from = 1, to = 0.5, duration = 0.3, curve = "OutCubic" } },
			},
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Spark",
			angle = "0..360",
			layer = "below",
			count = "3..5",
			spawnOn = { prop_hit = true },
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Swing",
			layer = "below",
			inheritFlip = true,
			spawnOn = { swing = true },
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Crosshair",
			layer = "below",
			spawnOn = { target_selected = true },
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
