return {
	frameWidth = 10,
	frameHeight = 10,
	pivotX = 0.5,
	pivotY = 1,
	sortOffsetY = 8,
	layer = 0,
	components = {
		{
			component = "tween",
			tweens = {
				{ target = "y", from = -1, to = 1, duration = 1.0, curve = "Sine", loop = true, pingPong = true },
			},
		},
		{
			component = "follow",
			offsetX = 6,
			offsetY = -3,
			smoothnessX = 0.5,
			smoothnessY = 0.2,
			leanAngle = -45,
			leanThreshold = 0.1,
		},
		{
			component = "weapon",
			range = 20,
			cooldown = 0.5,
			damage = 1,
			swing = {
				angleFrom = 0,
				angleTo = 90,
				duration = 0.1,
				offsetX = -8,
				offsetY = -4,
				curve = "Sine",
				smoothness = 0.5,
			},
		},
	},
}
