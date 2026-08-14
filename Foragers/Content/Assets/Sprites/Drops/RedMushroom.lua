return {
	extends = "Content.Assets.Sprites.Drops._Foods",
	components = {
		{
			component = "particle_emitter",
			moving = true,
			interval = 0.2,
			particle = "Content/Assets/Sprites/Particles/RedMushrooms",
			layer = "below",
		},

		{
			component = "silhouette",
			color = { 0.72, 0.19, 0.11, 0.75 },
		},
	},
}
