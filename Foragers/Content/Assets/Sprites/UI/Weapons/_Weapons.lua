return {
	object = "weapon",
	frameWidth = 16,
	frameHeight = 24,
	pivotX = "center",
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "tween",
			tags = {
				chosen = {
					{ target = "scale_x", from = 0.85, to = 1, duration = 0.2, curve = "OutCubic" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.3, curve = "OutCubic" },
					{ target = "brightness", from = 1, to = 0.5, duration = 0.5, curve = "OutCubic" },
				},
			},
		},

		{
			component = "ui",
			offsetX = 4,
			offsetY = 4,
			horizontalAlign = "top",
			verticalAlign = "top",
		},

		{
			component = "image",
			id = "emblem",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Emblems",
			scale = 1,
			offsetX = 0,
			offsetY = 6,
		},

		{
			component = "text",
			id = "level",
			charSpacing = 0,
			font = "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
			offsetX = -1,
			offsetY = 5,
			tierColors = {
				{ 0.90, 0.54, 0.21 },
				{ 0.52, 0.77, 0.60 },
				{ 1, 0.94, 0.53 },
				{ 0.81, 1, 0.91 },
				{ 1, 1, 1 },
			},
			dropshadowColor = { 0, 0, 0, 0.33 },
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "shader",
			shaders = { "Brightness", "Palette" },
		},

		{
			component = "tier",
			level = 3,
		},
	},
}