return {
	extends = "Content.Assets.Sprites.Props.__Props",
	host = "bush",
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..6" },
			},
		},

		{
			component = "shadow",
			width = 8,
			height = 6,
			offsetY = 1,
		},

		{
			component = "collision",
			mode = "slowdown",
			slowdown = 0.5,
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1|2" },
			},
		},

		{
			component = "tween",
			tags = {
				prop_touch = { { target = "angle", from = "-15|15", to = 0, duration = 2.5, curve = "OutBack" } },
			},
		},

		{
			component = "sound",
			tags = {
				prop_touch = {
					sounds = { "Content/Assets/Sounds/Events/BushTouch1.ogg", "Content/Assets/Sounds/Events/BushTouch2.ogg" },
					volume = 0.75,
					pitch = 1.5,
					pitchRandomness = 0.25,
				},
				prop_hit = { "Content/Assets/Sounds/Events/BushHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/BushBreak.ogg" },
			},
		},

		{
			component = "shader",
			shaders = { "Brightness", "Silhouette" },
		},
	},
}
