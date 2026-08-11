return {
	extends = "Content.Assets.Sprites.Drops._Foods",
	components = {
		{
			component = "pickup",
			satiety = 15,
		},

		{
			component = "particle_emitter",
			moving = true,
			interval = 0.2,
			particle = "Content/Assets/Sprites/Particles/Shells",
			layer = "below",
		},

		{
			component = "silhouette",
			color = { 0.69, 0.54, 0.47, 0.75 },
		},
	},
}