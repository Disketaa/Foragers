return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
		{
			component = "follow",
			followRadius = 25,
			followDelay = 0.5,
			smoothness = "0.25..0.3",
			accelerate = 5,
			rotate = true,
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/Leaves",
			interval = 0.2,
			moving = true,
			layer = "below",
		},

		{
			component = "sound",
			volume = 0.9,
			pitchRandomness = 0.4,
			tags = {
				arrived = { "Content/Assets/Sounds/Steps/Events/Eat.ogg" },
			},
		},

		{
			component = "pickup",
			satiety = 15,
		},
	},
}
