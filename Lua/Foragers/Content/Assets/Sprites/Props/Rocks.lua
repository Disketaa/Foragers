return {
	extends = "Content.Assets.Sprites.Props._Props",
	frameWidth = 8,
	frameHeight = 8,
	pivotX = 0.5,
	components = {
		{
			component = "spritesheet",
			columns = 3,
		},

		{
			component = "sound",
			tags = {
				prop_hit = {
					"Content/Assets/Sounds/Steps/Events/RockHit.ogg",
				},
				prop_broken = {
					"Content/Assets/Sounds/Steps/Events/RockBreak.ogg",
				},
			},
		},
	},
}
