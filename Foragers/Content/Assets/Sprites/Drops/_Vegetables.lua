return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
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
	},
}
