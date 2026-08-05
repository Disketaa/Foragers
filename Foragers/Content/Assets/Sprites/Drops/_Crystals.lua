return {
	extends = "Content.Assets.Sprites.Drops.__Drops",
	components = {
		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/CrystalSpark",
			layer = "below",
			interval = 0.1,
			moving = true,
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
			component = "pickup",
			xp = 1,
		},
	},
}
