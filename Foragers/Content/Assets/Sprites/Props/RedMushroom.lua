return {
	extends = "Content.Assets.Sprites.Props._HostedVegetables",
	components = {
		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/RedMushroom", amount = 1 },
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
			color = { 0.72, 0.19, 0.11, 0.75 },
		},
	},
}