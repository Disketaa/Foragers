return {
	frameWidth = 10,
	frameHeight = 10,
	pivotX = 0.5,
	pivotY = 1,
	sortOffsetY = 8,
	layer = 0,
	components = {
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
			range = 20,
			cooldown = 0.5,
			damage = 1,
			swing = {
				angleFrom = 0,
				angleTo = -90,
				duration = 0.1,
				offsetX = -8,
				offsetY = -4,
				curve = "OutSine",
				smoothness = 0.35,
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
			tweens = {
				{ target = "y", from = -1, to = 1, duration = 1.0, curve = "OutSine", loop = true, pingPong = true },
			},
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Spark",
			burstOn = { prop_hit = true },
			count = "3...5",
			angle = "0...360",
			layer = "below",
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Swing",
			burstOn = { swing = true },
			inheritFlip = true,
			layer = "below",
		},
	},
}
