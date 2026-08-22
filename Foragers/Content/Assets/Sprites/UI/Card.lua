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
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/RayLightsOverlay",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
		},

		{
			component = "image",
			image = "Content/Assets/Sprites/UI/Images/BronzePickaxe",
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
			dropshadowColor = { 0, 0, 0, 0.25 },
			dropshadow = true,
			text = "Sturdy",
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
