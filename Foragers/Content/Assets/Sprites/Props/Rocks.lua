return {
	extends = "Content.Assets.Sprites.Props.__Props",
	host = "rock",
	components = {
		{
			component = "spritesheet",
			columns = 3,
		},

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
			component = "destructible",
			hp = 20,
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1..4" },
			},
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Events/RockHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/RockBreak.ogg" },
			},
		},

		{
			component = "shader",
			shaders = { "Brightness", "Silhouette" },
		},
	},
}
