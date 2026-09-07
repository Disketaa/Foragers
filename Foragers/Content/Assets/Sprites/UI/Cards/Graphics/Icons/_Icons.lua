return {
	frameWidth = 16,
	frameHeight = 16,
	pivotX = "center",
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "shader",
			shaders = { "Palette" },
		},

		{
			component = "palette",
			scheme = "tier",
		},
	},
}