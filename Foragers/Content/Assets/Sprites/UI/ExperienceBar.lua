return {
	frameWidth = 22,
	frameHeight = 22,
	pivotX = "center",
	pivotY = "center",
	layer = 1,
	components = {
		{
			component = "spritesheet",
			columns = 14,
		},

		{
			component = "tween",
			tags = {
				counter_tick = {
					{ target = "scale_x", from = 0.9, to = 1, duration = 0.2, curve = "OutCubic" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.4, curve = "OutCubic" },
					{ target = "tint_mix", from = 0.4, to = 0, duration = 0.3, curve = "OutCubic" },
				},
			},
		},

		{
			component = "sound",
			tags = {
				level_up = { "Content/Assets/Sounds/Events/LevelUp.ogg" },
			},
		},

		{
			component = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "top",
		},

		{
			component = "counter",
			mode = "progress",
			field = "experience",
			sourceType = "player_stats",
			label = {
				font = "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
				charSpacing = -4,
				color = { 0.56, 0.32, 0.73 },
				offsetX = 1,
				offsetY = 0,
			},
			smoothness = 0.3,
			curve = "OutCubic",
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.47, 0.39, 0.77 }, u_additive = 1 } },
			},
		},
	},
}
