return {
	pivotY = 6,
	layer = 0,
	sortOffsetY = 2,
	components = {
		{
			component = "spritesheet",
		},

		{
			component = "destructible",
			hp = 15,
		},

		{
			component = "tween",
			tags = {
				prop_spawned = {
					{ target = "scale_x", from = 2, to = 1, duration = 0.25, curve = "OutBack" },
					{ target = "scale_y", from = 0, to = 1, duration = 0.4, curve = "OutBack" },
					{ target = "angle", from = "-45|45", to = 0, duration = 0.5, curve = "OutBack" },
				},

				prop_hit = {
					{ target = "scale_x", from = 0.5, to = 1, duration = 0.9, curve = "OutBack" },
					{ target = "scale_y", from = 1.5, to = 1, duration = 0.4, curve = "OutBack" },
					{ target = "brightness", from = 1, to = 0.5, duration = 0.2, curve = "InBack" },
				},
				target_selected = { { target = "tint_mix", from = 0.5, to = 0, duration = 0.5, curve = "OutCubic" } },
			},
		},

		{
			component = "particle_emitter",
			offsetY = -2,
			spawnOn = { prop_broken = true },
			particle = "Content/Assets/Sprites/Particles/SmallExplosion.lua",
			layer = "above",
		},

		{
			component = "particle_emitter",
			spawnOn = { target_selected = true },
			particle = "Content/Assets/Sprites/Particles/Crosshair",
			layer = "below",
		},

		{
			component = "text_emitter",
			event = "prop_hit",
			font = "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
			offsetX = 0,
			offsetY = "-6..-8",
			moveX = "-10..10",
			moveY = -50,
			gravity = 200,
			color = { 1, 0.91, 0.89 },
			duration = 0.8,
			destroy = "scale",
			destroyCurve = "InCubic",
		},

		{
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {
				prop_spawned = {
					sounds = { "Content/Assets/Sounds/Events/Pop.ogg" },
					volume = 0.4,
					pitchRandomness = 0.3,
				},
			},
		},

		{
			component = "silhouette",
			mode = "mask",
		},

		{
			component = "shader",
			shaders = {
				"Brightness",
				{ Tint = { u_tint_color = { 0.76, 0.94, 0.16 }, u_additive = 1 } },
			},
		},
	},
}
