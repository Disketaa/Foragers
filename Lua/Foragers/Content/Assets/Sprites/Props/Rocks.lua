return {
	extends = "Content.Assets.Sprites.Props._Props",
	components = {
		{
			component = "spritesheet",
			columns = 3,
		},

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
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "2...4" },
			},
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Steps/Events/RockHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Steps/Events/RockBreak.ogg" },
			},
		},
	},
}
