return {
	frameWidth = 64,
	frameHeight = 104,
	pivotX = "center",
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "hover",
			type = "hand",
		},

		{
			component = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/CardBackgrounds/Cavern",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			parallax = -0.5,
			layer = "below",
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/RayLightsOverlay",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			layer = "below",
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/CopperLabel",
			scale = 1,
			offsetX = 0,
			offsetY = 1,
			parallax = 0.25,
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/Icons/BronzePickaxe",
			scale = 1,
			offsetX = 0,
			offsetY = -17,
			bob = 1,
			parallax = -1,
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = -40,
			dropshadowColor = { 0.56, 0.32, 0.73, 1 },
			text = "Прочность",
			maxWidth = 40,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			offsetX = 1,
			offsetY = 0,
			color = { 0.93, 0.7, 0.61 },
			dropshadowColor = { 0, 0, 0, 0.25 },
			text = "1",
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = 16,
			color = { 0.41, 0.35, 0.34 },
			dropshadowColor = { 0.09, 0.08, 0.08, 1 },
			text = "+2 урон",
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = 25,
			color = { 0.41, 0.35, 0.34 },
			dropshadowColor = { 0.09, 0.08, 0.08, 1 },
			text = "+1 темп",
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "shader",
			shaders = {
				{ CursorSkew = { u_amount = 0.1, u_radius = 300 } },
			},
		},
	},
}
