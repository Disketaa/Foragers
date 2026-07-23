return {
	frameWidth = 19,
	frameHeight = 20,
	pivotX = 0.5,
	pivotY = 0.5,
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 40,
		},

		{
			component = "tween",
			tags = {
				counter_tick = {
					{ target = "scale_x", from = 1.05, to = 1, duration = 0.5, curve = "OutBack" },
					{ target = "scale_y", from = 1.05, to = 1, duration = 0.5, curve = "OutBack" },
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
			horizontal = "center",
			vertical = "top",
			offsetX = 0,
			offsetY = 4,
		},

		{
			component = "counter",
			mode = "progress",
			field = "experience",
			sourceType = "player_stats",
			smoothness = 0.3,
			curve = "OutCubic",
			label = {
				font = "Content.Assets.Sprites.UI.Fonts.Tinylorder",
				charSpacing = -4,
				color = { 0.95, 0.68, 0.87 },
				offsetX = 1,
				offsetY = -1,
			},
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.47, 0.39, 0.77 }, u_additive = 1 } },
			},
		},
	},
}
