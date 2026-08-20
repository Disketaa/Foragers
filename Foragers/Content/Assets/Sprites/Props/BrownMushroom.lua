return {
	extends = "Content.Assets.Sprites.Props._HostedVegetables",
	components = {
		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/BrownMushroom", amount = 1 },
			},
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Events/VegetableHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/VegetableHit.ogg" },
			},
		},

		{
			component = "silhouette",
			mode = "silhouette",
			color = { 0.7, 0.45, 0.21, 0.75 },
		},
	},
}