return {
	pivotY = 0.75,
	sortOffsetY = 2,
	layer = 0,
	components = {
		{
			component = "shader",
			shaderName = "Brightness",
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/SmallExplosion.lua",
			burstOn = { prop_broken = true },
			offsetY = -2,
			layer = "above",
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
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "brightness", from = 1, to = 0.5, duration = 0.2, curve = "InBack" },
					{ target = "scale_x",    from = 0.5, to = 1,   duration = 0.9, curve = "OutBack" },
					{ target = "scale_y",    from = 1.5, to = 1,   duration = 0.4, curve = "OutBack" },
				},
			},
		},

		{
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {},
		},

		{
			component = "spritesheet",
		},

		{
			component = "destructible",
			hp = 3,
		},
	},
}
