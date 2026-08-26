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
			image = "Content/Assets/Sprites/UI/Cards/Overlays/Rays",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			layer = "below",
		},

		{
			component = "image",
			id = "label",
			image = "Content/Assets/Sprites/UI/Cards/Emblems/Copper",
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
			component = "text",
			id = "level",
			offsetX = 0,
			offsetY = 0,
			color = { 0.93, 0.7, 0.61 },
			dropshadowColor = { 0, 0, 0, 0.25 },
			text = "1",
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			id = "description",
			offsetY = 16,
			color = { 0.41, 0.35, 0.34 },
			dropshadowColor = { 0.09, 0.08, 0.08, 1 },
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
