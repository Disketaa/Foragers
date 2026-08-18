return {
	object = "player",
	frameWidth = 16,
	frameHeight = 16,
	pivotX = "center",
	pivotY = 12,
	layer = 0,
	sortOffsetY = 0,
	components = {
		{
			component = "spritesheet",
			columns = 5,
			rows = 5,
			animations = {
				idle = { row = 1, frames = 4, speed = 4, loop = true },
				run = { row = 2, frames = 4, speed = 8, loop = true },
				float = { row = 3, frames = 4, speed = 4, loop = true },
				swim = { row = 4, frames = 4, speed = 4, loop = true },
				death = { row = 5, frames = 5, speed = 10, duration = { 12, 1, 1, 1, 1 }, loop = false }
			},
		},

		{
			component = "player_stats",
			movementSpeed = { base = 50, gain = 1 },
			swimmingSpeed = { base = 30, gain = 0.5 },
			level = 1,
			maxLevel = 99,
			experience = 0,
			xpCurve = { base = 10, growth = 1.15 },
			satiety = 100,
			maxSatiety = { base = 100, gain = 2 },
			satietyDrain = { run = 0.25, swim = 0.5, idle = 0.05, float = 0.25 },
			lowSatietyPercent = 50,
			lowSatietyWarnings = 4,
			lowSatietyZoom = 2,
			lowSatietyMaskRadius = 24,
			damage = { base = 5, gain = 0.5 },
			range = { base = 20, gain = 0.25 },
			critChance = 0,
			critMult = 1.5,
			attackSpeed = { base = 2, gain = 0.1 },
		},

		{
			component = "shadow",
			width = 12,
			height = 4,
		},

		{
			component = "control",
		},

		{
			component = "collision",
			mode = "solid_and_detect",
			collisionWidth = 2,
			collisionHeight = 2,
			offsetX = 0,
			offsetY = -2,
		},

		{
			component = "scroll_to",
			chunkSize = 16,
			smoothness = 6,
		},

		{
			component = "shake",
			magnitude = 3,
			decay = true,
			duration = 0.6,
			triggerOn = { "death" },
		},

		{
			component = "tween",
			tags = {
				flip = {
					{ target = "scale_x", from = 0.75, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "scale_y", from = 1.25, to = 1, duration = 0.3, curve = "OutBack" },
				},

				splash = {
					{ target = "scale_x", from = 1.25, to = 1, duration = 0.75, curve = "OutBack" },
					{ target = "scale_y", from = 0.75, to = 1, duration = 0.5, curve = "OutBack" },
				},
				pickup = { { target = "tint_mix", from = 0.5, to = 0, duration = 0.5, curve = "OutCubic" } },
			},
		},

		{
			component = "particle_emitter",
			offsetX = 0,
			offsetY = 0,
			stepInterval = 2,
			spawnOn = { run = true },
			particle = "Content/Assets/Sprites/Particles/Dust.lua",
			inheritFlip = true,
			layer = "below",
		},

		{
			component = "text_emitter",
			event = "pickup",
			offsetX = -5,
			offsetY = -3,
			moveX = "-15|15",
			moveY = -30,
			gravity = 130,
			color = { 0.6, 1, 0.6 },
			duration = 0.7,
			destroy = "scale",
			destroyCurve = "InCubic",
		},

		{
			component = "emote",
			object = "Content/Assets/Sprites/Particles/HungerEmoteBubble.lua",
			event = "low_satiety",
			offsetX = 0,
			offsetY = -7,
			duration = 0.4,
		},

		{
			component = "sound",
			volume = 0.5,
			pitch = 1,
			pitchRandomness = 0.15,
			tags = {
				run = {
					sounds = { "Content/Assets/Sounds/Steps/Grass1.ogg", "Content/Assets/Sounds/Steps/Grass2.ogg", "Content/Assets/Sounds/Steps/Grass3.ogg", "Content/Assets/Sounds/Steps/Grass4.ogg", },
					stepInterval = 2,
				},

				swim = {
					sounds = { "Content/Assets/Sounds/Steps/Water1.ogg", "Content/Assets/Sounds/Steps/Water2.ogg", "Content/Assets/Sounds/Steps/Water3.ogg", },
					stepInterval = 2,
				},
				water_in = { "Content/Assets/Sounds/Events/WaterIn.ogg" },
				water_out = { "Content/Assets/Sounds/Events/WaterOut.ogg" },
				hunger = {
					"Content/Assets/Sounds/Events/Hunger1.ogg",
					"Content/Assets/Sounds/Events/Hunger2.ogg",
					"Content/Assets/Sounds/Events/Hunger3.ogg",
				},

				death = {
					sounds = { "Content/Assets/Sounds/Events/Death.ogg" },
					pitchRandomness = 0,
				},
			},
		},

		{
			component = "silhouette",
		},

		{
			component = "shader",
			shaders = {
				{ Tint = { u_tint_color = { 0.8, 0.5, 0.7 }, u_additive = 1 } },
			},
		},
	},
}
