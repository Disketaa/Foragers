return {
	extends = "Content.Assets.Sprites.Props.__Props",
	object = "vegetable",
	frameWidth = 10,
	frameHeight = 10,
	pivotX = "center",
	pivotY = "center",
	layer = 1,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..6" },
			},
		},

		{
			component = "destructible",
			hp = 10,
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/Berries", amount = "1..3" },
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

		{
			component = "silhouette",
			mode = "silhouette",
			color = { 0.54, 0.63, 0.96, 0.75 },
		},
	},
}