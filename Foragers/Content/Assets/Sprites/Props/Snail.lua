return {
	extends = "Content.Assets.Sprites.Props.__Props",
	object = "vegetable",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = "center",
	pivotY = "center",
	layer = 0,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "6..8" },
			},
		},

		{
			component = "destructible",
			hp = 15,
		},

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