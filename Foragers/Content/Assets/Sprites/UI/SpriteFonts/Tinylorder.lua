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
			charSpacing = 1,
			spacing = {
				{ 5, "Mmwм" },
				{ 3, "т>" },
				{ 2, "+.-"},
				{ 1, "li" },
				{ 1, " " },
			},
			autoTrim = true,
		},
	},
}
