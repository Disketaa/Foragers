return {
	extends = "Content.Assets.Sprites.Drops._Foods",
	components = {
		{
			component = "pickup",
			satiety = 20,
		},

		{
			component = "particle_emitter",
			moving = true,
			interval = 0.2,
			particle = "Content/Assets/Sprites/Particles/BrownMushrooms",
			layer = "below",
		},

		{
			component = "silhouette",
			color = { 0.7, 0.45, 0.21, 0.75 },
		},
	},
}