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
			component = "shader",
			shaders = { "Brightness", "Palette" },
		},

		{
			component = "palette",
			scheme = "rarity",
		},
	},
}