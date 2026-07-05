return {
	object = "tool",
	frameWidth = 10,
	frameHeight = 10,
	pivotX = 0.5,
	pivotY = 1,
	components = {
		{
			component = "tween",
			tweens = {
				{ target = "y", from = -2, to = 2, duration = 1.0, curve = "Sine", loop = true, pingPong = true },
			},
		},
		{
			component = "follow",
			image = "Content/Assets/Sprites/Tools/Pickaxe.png",
			offsetX = 6,
			offsetY = -3,
			smoothness = 0.5,
		},
	},
}
