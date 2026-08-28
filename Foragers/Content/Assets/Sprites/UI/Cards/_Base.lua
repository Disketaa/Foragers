return {
	frameWidth = 64,
	frameHeight = 104,
	pivotX = "center",
	pivotY = "center",
	maxLevel = 20,
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "tween",
			tags = {
				show = {
					{ target = "scale_x", from = 0, to = 1, duration = 0.2, curve = "OutBack" },
					{ target = "scale_y", from = 2, to = 1, duration = 0.3, curve = "OutBack" },
				},
				hide = { { target = "scale_x", from = 1, to = 0, duration = 0.2, curve = "OutCubic" } },
				select = {
					{ target = "scale_x", from = 1.1, to = 1, duration = 0.7, curve = "OutCubic" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.6, curve = "OutBack" },
					{ target = "brightness", from = 0.35, to = 0.5, duration = 0.3, curve = "OutBack" },
				},

				unselect = {
					{ target = "scale_x", from = 1.1, to = 1, duration = 0.9, curve = "OutCubic" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.7, curve = "OutBack" },
					{ target = "brightness", from = 0.5, to = 0.35, duration = 0.3, curve = "OutBack" },
				},
			},
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
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Frames/Black",
			scale = 1,
			offsetX = 0,
			offsetY = 0,
		},

		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Backgrounds/Cavern",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			parallax = -0.5,
			layer = "below",
		},

		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Overlays/Rays",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			layer = "below",
		},

		{
			component = "image",
			id = "emblem",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Emblems",
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
			charSpacing = 0,
			offsetX = -1,
			offsetY = 0,
			tierColors = {
				{ 0.90, 0.54, 0.21 },
				{ 0.52, 0.77, 0.60 },
				{ 1, 0.94, 0.53 },
				{ 0.81, 1, 0.91 },
				{ 1, 1, 1 },
			},
			dropshadowColor = { 0, 0, 0, 0.33 },
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
				"Brightness",
				{ Skew = { u_amount = 0.1 } },
			},
		},
	},
}
