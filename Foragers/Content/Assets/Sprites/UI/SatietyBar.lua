return {
	frameWidth = 26,
	frameHeight = 18,
	pivotX = "center",
	pivotY = "center",
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 12,
		},

		{
			component = "tween",
			tags = {
				counter_tick = {
					{ target = "scale_x", from = 0.95, to = 1, duration = 0.1, curve = "OutCubic" },
					{ target = "scale_y", from = 1.05, to = 1, duration = 0.2, curve = "OutCubic" },
					{ target = "tint_mix", from = 0.1, to = 0, duration = 0.3, curve = "OutCubic" },
				},
			},
		},

		{
			component = "ui",
			offsetX = -19,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "top",
		},

		{
			component = "counter",
			mode = "fraction",
			field = "satiety",
			maxField = "maxSatiety",
			sourceType = "player_stats",
			smoothness = 0.3,
			curve = "OutCubic",
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.94, 0.39, 0.12 }, u_additive = 1 } },
			},
		},
	},
}