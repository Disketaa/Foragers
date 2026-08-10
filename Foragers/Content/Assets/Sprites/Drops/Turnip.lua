return {
	extends = "Content.Assets.Sprites.Drops._Foods",
	components = {
		{
			component = "shadow",
			width = 8,
			height = 4,
			offsetX = 1,
			offsetY = 4,
		},

		{
			component = "pickup",
			satiety = 50,
		},

		{
			component = "silhouette",
			color = { 0.83, 0.5, 0.73, 0.75 },
		},
	},
}
