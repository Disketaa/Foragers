return {
	extends = "Content.Assets.Sprites.Props._Trees",
	components = {
		{
			component = "destructible",
			hp = 9,
			replaceWith = "Content/Assets/Sprites/Props/BirchStump",
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/MediumCrystal", amount = "0|1|1" },
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1..3" },
			},
		},
	},
}
