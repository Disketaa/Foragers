return {
	frameWidth = 24,
	frameHeight = 32,
	pivotX = 0.5,
	pivotY = 0.95,
	sortOffsetY = 3,
	layer = 0,
	components = {
		{
			component = "destructible",
			hp = 7,
			replaceWith = "Content/Assets/Sprites/Props/OakStumps",
		},
		{
			component = "particle_emitter",
			particle = "Content/Assets/Sprites/Particles/SmallExplosion.lua",
			burstOn = { prop_broken = true },
			offsetY = -10,
			layer = "above",
		},
		{
			component = "sound",
			volume = 0.7,
			pitchRandomness = 0.15,
			tags = {
				prop_hit = {
					"Content/Assets/Sounds/Steps/Events/WoodHit.ogg",
				},
				prop_broken = {
					"Content/Assets/Sounds/Steps/Events/WoodBreak.ogg",
				},
			},
		},
		{
			component = "tween",
			tags = {
				prop_hit = {
					{ target = "scale_x", from = 0.8, to = 1, duration = 1.5, curve = "BackOut" },
					{ target = "scale_y", from = 1.1, to = 1, duration = 0.6, curve = "BackOut" },
				},
			},
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
			component = "proximity_fade",
			radius = 15,
			fadeAlpha = 0.5,
			smoothness = 0.25,
		},
		{
			component = "shader",
			shaderName = "Brightness",
		},
	},
}
