return {
	extends = "Content.Assets.Sprites.Props._Props",
	components = {
		{
			component = "shadow",
			width = 12,
			height = 6,
			offsetX = 2,
			offsetY = 1,
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1..3" },
			},
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
