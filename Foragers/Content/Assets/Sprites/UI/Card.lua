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
				{ target = "iconBobY", from = -1, to = 1, duration = 2, curve = "InOutSine", loop = true, pingPong = true },
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
			component = "icon",
			image = "Content/Assets/Sprites/UI/RayLightsOverlay",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			parallax = 2,
		},

		{
			component = "icon",
			image = "Content/Assets/Sprites/UI/Icons/BronzePickaxe",
			scale = 1,
			offsetX = 0,
			offsetY = -17,
			bob = 1,
			parallax = 1,
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = -39,
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
