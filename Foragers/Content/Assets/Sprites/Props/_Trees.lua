return {
	extends = "Content.Assets.Sprites.Props.__Props",
	frameWidth = 24,
	frameHeight = 32,
	pivotX = 0.5,
	pivotY = 0.95,
	sortOffsetY = 3,
	components = {
		{
			component = "spritesheet",
			animations = {
				{ row = 1, frames = 4, speed = "4..6" },
			},
		},

		{
			component = "shadow",
			width = 24,
			height = 6,
			offsetX = 4,
			offsetY = 1,
		},

		{
			component = "destructible",
			hp = 7,
			replaceWith = "Content/Assets/Sprites/Props/OakStump",
		},

		{
			component = "drop",
			drops = {
				{ sprite = "Content/Assets/Sprites/Drops/MediumCrystal", amount = "0|1" },
				{ sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1..3" },
			},
		},

		{
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "brightness", from = 1, to = 0.5, duration = 0.2, curve = "InBack" },
					{ target = "scale_x", from = 0.8, to = 1, duration = 1.5, curve = "OutBack" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.6, curve = "OutBack" },
				},
			},
		},

		{
			component = "particle_emitter",
			offsetY = -10,
		},

		{
			component = "sound",
			tags = {
				prop_hit = { "Content/Assets/Sounds/Events/WoodHit.ogg" },
				prop_broken = { "Content/Assets/Sounds/Events/WoodBreak.ogg" },
			},
		},
	},
}
