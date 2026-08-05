return {
	frameWidth = 15,
	frameHeight = 15,
	pivotX = "center",
	pivotY = "center",
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
					{ target = "scale_x", from = 1.025, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "scale_y", from = 1.025, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "tint_mix", from = 0.3, to = 0, duration = 0.3, curve = "OutCubic" },
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
			sourceType = "player_stats",
			field = "satiety",
			maxField = "maxSatiety",
			curve = "OutCubic",
			smoothness = 0.3,
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
