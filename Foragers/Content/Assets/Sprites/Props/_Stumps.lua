return {
	extends = "Content.Assets.Sprites.Props.__Props",
	components = {
		{
			component = "shadow",
			width = 12,
			height = 6,
		},

		{
			component = "collision",
			mode = "solid",
			collisionWidth = 6,
			collisionHeight = 6,
			offsetX = 0,
			offsetY = 0,
			visible = false,
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
				prop_hit = { "Content/Assets/Sounds/Events/WoodHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/WoodBreak.ogg" },
			},
		},

		{
			component = "shader",
			shaders = { "Brightness", "Silhouette" },
		},
	},
}
