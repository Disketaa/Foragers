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
			id = "hover",
			type = "hand",
		},

		{
			component = "ui",
			id = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "image",
			id = "frame",
			image = "Content/Assets/Sprites/UI/Cards/Frames/Black",
			scale = 1,
			offsetX = 0,
			offsetY = 0,
			layer = "below",
		},

		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Backgrounds/Cavern",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			parallax = -0.5,
			layer = "below",
		},

		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/RayLightsOverlay",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			layer = "below",
		},

		{
			component = "image",
			id = "label",
			image = "Content/Assets/Sprites/UI/CopperLabel",
			scale = 1,
			offsetX = 0,
			offsetY = 1,
			parallax = 0.25,
		},

		{
			component = "image",
			id = "icon",
			offsetX = 0,
			offsetY = -17,
			bob = 1,
			parallax = -1,
		},

		{
			component = "text",
			id = "title",
			offsetX = 0,
			offsetY = -40,
			dropshadowColor = { 0.56, 0.32, 0.73, 1 },
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "shader",
			id = "skew",
			shaders = {
				{ CursorSkew = { u_amount = 0.1, u_radius = 300 } },
			},
		},
	},
}
