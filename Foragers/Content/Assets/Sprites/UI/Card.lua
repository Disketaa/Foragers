return {
	frameWidth = 64,
	frameHeight = 104,
	pivotX = "center",
	pivotY = "center",
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "tween",
			tweens = {
				{ target = "imageBobY", from = -1, to = 1, duration = 2, curve = "InOutSine", loop = true, pingPong = true },
			},
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
			offsetX = 1,
			offsetY = 0,
			color = { 0.93, 0.7, 0.61 },
			dropshadowColor = { 0, 0, 0, 0.25 },
			dropshadow = true,
			text = "1",
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = -40,
			dropshadowColor = { 0, 0, 0, 0.25 },
			dropshadow = true,
			text = "Привет",
			maxWidth = 40,
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
