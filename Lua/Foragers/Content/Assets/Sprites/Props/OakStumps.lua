return {
	extends = "Content.Assets.Sprites.Props._Props",
	components = {
		{
			component = "drop",
			sprite = "Content/Assets/Sprites/Drops/Crystal",
			amount = "1...3",
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Steps/Events/WoodHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Steps/Events/WoodBreak.ogg" },
			},
		},
	},
}
