return {
	frameWidth = 8,
	frameHeight = 8,
	pivotX = "center",
	pivotY = "center",
	components = {
		{
			component = "spritesheet",
			columns = 16,
		},

		{
			component = "spritefont",
			chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя1234567890!\"#$%&'()*+,-./:;<=>",
			charSpacing = -3,
			spacing = {
				{ 9, "Mmwм" },
				{ 7, "т>" },
				{ 6, "+"},
				{ 5, ".li-" },
				{ 5, " " },
			},
			autoTrim = true,
		},
	},
}
