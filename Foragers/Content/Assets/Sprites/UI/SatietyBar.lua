return {
	frameWidth = 15,
	frameHeight = 15,
	pivotX = 0.5,
	pivotY = 0.5,
	layer = 0,
	components = {
		{
			component = "spritesheet",
			columns = 37,
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
			component = "ui",
			horizontal = "center",
			vertical = "top",
			offsetX = -19,
			offsetY = 6,
		},

		{
			component = "counter",
			mode = "fraction",
			field = "satiety",
			maxField = "maxSatiety",
			sourceType = "player_stats",
			smoothness = 0.3,
			curve = "OutCubic",
			icon = {
				sprite = "Content.Assets.Sprites.UI.Icons.Satiety",
			},
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.94, 0.39, 0.12 }, u_additive = 1 } },
			},
		},
	},
}
