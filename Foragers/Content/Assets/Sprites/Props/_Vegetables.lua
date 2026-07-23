return {
	extends = "Content.Assets.Sprites.Props.__Props",
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..6" },
			},
		},

		{
			component = "shadow",
			width = 12,
			height = 6,
			offsetX = 2,
			offsetY = 1,
		},

		{
			component = "collision",
			mode = "slowdown",
			slowdown = 0.5,
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
				prop_touch = { "Content/Assets/Sounds/Events/VegetableHit.ogg" },
				prop_hit = { "Content/Assets/Sounds/Events/VegetableHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/VegetableBreak.ogg" },
			},
		},
	},
}
