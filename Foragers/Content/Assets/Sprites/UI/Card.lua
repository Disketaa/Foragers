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
			component = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontal = "center",
			vertical = "center",
		},

		{
			component = "text",
			offsetX = 0,
			offsetY = -39,
			text = "Sturdy",
			hAlign = "center",
			vAlign = "center",
		},

		{
			component = "shader",
			shaders = {
				{ CursorSkew = { u_amount = 0.1, u_radius = 300 } },
			},
		},
	},
}
