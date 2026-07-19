return {
	pivotY = 0.75,
	sortOffsetY = 2,
	layer = 0,
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
					{ target = "angle", from = "-45|45", to = 0, duration = 0.5, curve = "OutBack" },
					{ target = "scale_x", from = 2, to = 1, duration = 0.25, curve = "OutBack" },
					{ target = "scale_y", from = 0, to = 1, duration = 0.4, curve = "OutBack" },
				},
				prop_hit = {
					{ target = "brightness", from = 1, to = 0.5, duration = 0.2, curve = "InBack" },
					{ target = "scale_x", from = 0.5, to = 1, duration = 0.9, curve = "OutBack" },
					{ target = "scale_y", from = 1.5, to = 1, duration = 0.4, curve = "OutBack" },
				},
			},
		},

		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/SmallExplosion.lua",
			spawnOn = { prop_broken = true },
			offsetY = -2,
			layer = "above",
		},

		{
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {
				prop_spawned = {
					sounds = { "Content/Assets/Sounds/Steps/Events/Pop.ogg" },
					volume = 0.4,
					pitchRandomness = 0.3,
				},
			},
		},

		{
			component = "shader",
			shaders = { "Brightness" },
		},
	},
}
