return {
	extends = "Content.Assets.Sprites.Props._HostedVegetables",
	components = {
		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/Snail", amount = 1 },
			},
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Events/ShellHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/ShellBreak.ogg" },
			},
		},

		{
			component = "silhouette",
			mode = "silhouette",
			color = { 0.69, 0.54, 0.47, 0.75 },
		},
	},
}