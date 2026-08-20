return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
		{
			component = "pickup",
			xp = 1,
		},

		{
			component = "particle_emitter",
			moving = true,
			interval = 0.1,
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
			component = "emissive",
		},
	},
}
