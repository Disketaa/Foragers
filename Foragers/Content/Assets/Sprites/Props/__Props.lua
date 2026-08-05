return {
	pivotY = 6,
	layer = 0,
	sortOffsetY = 2,
	components = {
		{
			component = "spritesheet",
		},

		{
			component = "collision",
			mode = "solid",
			collisionWidth = 6,
			collisionHeight = 6,
			offsetX = 0,
			offsetY = 0,
			visible = false,
		},

		{
			component = "destructible",
			hp = 3,
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
			},
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/SmallExplosion.lua",
			offsetY = -2,
			layer = "above",
			spawnOn = { prop_broken = true },
		},

		{
			component = "text_emitter",
			event = "prop_hit",
			font = "Content.Assets.Sprites.UI.Fonts.Tinylorder",
			color = { 1, 0.91, 0.89 },
			offsetX = 0,
			offsetY = "-6..-8",
			moveX = "-10|10",
			moveY = -50,
			gravity = 200,
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
			shaders = { "Brightness" },
		},
	},
}
