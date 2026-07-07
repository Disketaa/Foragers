return {
	extends = "Content.Assets.Sprites.Props._Props",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	components = {
		{
			component = "collision",
			mode = "slowdown",
			slowdown = 0.5,
		},

		{
			component = "tween",
			tags = {
				bush_touch = { { target = "angle", from = "-15 | 15", to = 0, duration = 2.5, curve = "OutBack" } },
			},
		},

		{
			component = "sound",
			tags = {
				bush_touch = { "Content/Assets/Sounds/Steps/Events/BushHit.ogg" },
				prop_hit = { "Content/Assets/Sounds/Steps/Events/BushHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Steps/Events/BushBreak.ogg" },
			},
		},
	},
}
