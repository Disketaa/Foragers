return {
	extends = "Content.Assets.Sprites.Props._HostedVegetables",
	frameWidth = 10,
	frameHeight = 10,
	components = {
		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/Berries", amount = "1..3" },
			},
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Events/VegetableHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/VegetableBreak.ogg" },
			},
		},

		{
			component = "silhouette",
			mode = "silhouette",
			color = { 0.54, 0.63, 0.96, 0.75 },
		},
	},
}