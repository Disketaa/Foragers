return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
		{
			component = "follow",
			followRadius = 25,
			followDelay = 0.5,
			accelerate = 5,
			smoothness = "0.25..0.3",
			rotate = true,
		},

		{
			component = "particle_emitter",
			moving = true,
			interval = 0.2,
			particle = "Content/Assets/Sprites/Particles/Leaves",
			layer = "below",
		},

		{
			component = "sound",
			volume = 0.9,
			pitchRandomness = 0.4,
			tags = {
				arrived = { "Content/Assets/Sounds/Events/Eat.ogg" },
			},
		},

		{
			component = "pickup",
			satiety = 15,
		},
	},
}
