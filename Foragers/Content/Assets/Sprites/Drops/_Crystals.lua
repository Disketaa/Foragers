return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
		{
			component = "particle_emitter",
			interval = 0.1,
			moving = true,
			particle = "Content/Assets/Sprites/Particles/CrystalSpark",
			layer = "below",
		},

		{
			component = "sound",
			volume = 0.3,
			pitchRandomness = 0.4,
			tags = {
				arrived = { "Content/Assets/Sounds/Events/CrystalPling.ogg" },
			},
		},

		{
			component = "silhouette",
			color = { 0.83, 0.5, 0.73, 0.75 },
		},

		{
			component = "pickup",
			xp = 1,
		},
	},
}
