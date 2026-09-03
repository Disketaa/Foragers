return {
	frameWidth = 64,
	frameHeight = 104,
	pivotX = "center",
	pivotY = "center",
	maxLevel = 20,
	components = {
		{
			component = "spritesheet",
			columns = 1,
		},

		{
			component = "tween",
			tags = {
				show = {
					{ target = "y", from = 0, to = 2, duration = "1..2", curve = "InOutCubic", loop = true, pingPong = true },
					{ target = "scale_x", from = 0, to = 1, duration = 0.1, curve = "OutBack" },
					{ target = "scale_y", from = 2, to = 1, duration = 0.3, curve = "OutBack" },
					{ target = "rim_strength", set = 0 },
					{ target = "brightness", from = 0, to = 0.35, duration = 0.3, curve = "OutCubic" },
				},

				hide = {
					{ target = "y", from = 0, to = "10..30", duration = 1, curve = "InOutCubic" },
					{ target = "burn", from = 0, to = 1, duration = 1, curve = "InOutCubic" },
					{ target = "brightness", from = 0.5, to = 0, duration = 1, curve = "InOutCubic" },
				},

				select = {
					{ target = "y", set = 0 },
					{ target = "scale_x", from = 1, to = 1.25, duration = 0.7, curve = "OutBack" },
					{ target = "scale_y", from = 1, to = 1.25, duration = 0.6, curve = "OutBack" },
					{ target = "rim_angle", from = 0, to = 360, duration = 120, curve = "Linear", loop = true },
					{ target = "rim_strength", from = 0, to = 0.4, duration = 0.3, curve = "Linear" },
					{ target = "brightness", from = 0.35, to = 0.5, duration = 0.3, curve = "OutBack" },
				},

				unselect = {
					{ target = "y", from = 0, to = 2, duration = "1..2", curve = "InOutCubic", loop = true, pingPong = true },
					{ target = "scale_x", from = 1.25, to = 1, duration = 0.1, curve = "OutBack" },
					{ target = "scale_y", from = 1.25, to = 1, duration = 0.2, curve = "OutBack" },
					{ target = "brightness", from = 0.5, to = 0.35, duration = 0.3, curve = "OutBack" },
				},

				chosen = {
					{ target = "scale_x", from = 1.25, to = 1.4, duration = 1, curve = "OutCubic" },
					{ target = "scale_y", from = 1.25, to = 1.4, duration = 1, curve = "OutCubic" },
					{ target = "burn", from = 0, to = 1, duration = 1, wait = 1, curve = "OutCubic" },
					{ target = "brightness", from = 0.5, to = 0, duration = 0.5, wait = 1, curve = "OutCubic" },
				},
			},
		},

		{
			component = "sound",
			volume = 0.4,
			pitchRandomness = 0.15,
			tags = {
				card_shuffle = { "Content/Assets/Sounds/Events/CardShuffle.ogg" },
				card_select = {
					"Content/Assets/Sounds/Events/Card1.ogg",
					"Content/Assets/Sounds/Events/Card2.ogg",
					"Content/Assets/Sounds/Events/Card3.ogg",
				},

				card_hide = {
					sounds = { "Content/Assets/Sounds/Events/CardWhoosh.ogg" },
					volume = 0.7,
				},
				card_choose = {},
			},
		},

		{
			component = "hover",
			id = "hover",
			type = "hand",
		},

		{
			component = "ui",
			id = "ui",
			offsetX = 0,
			offsetY = 0,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "image",
			id = "frame",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Frames/Black",
			scale = 1,
			offsetX = 0,
			offsetY = 0,
		},

		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Backgrounds/Cavern",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			parallax = -0.5,
			layer = "below",
		},

		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Overlays/Rays",
			scale = 1,
			offsetX = 0,
			offsetY = -16,
			layer = "below",
		},

		{
			component = "image",
			id = "emblem",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Emblems",
			scale = 1,
			offsetX = 0,
			offsetY = 1,
		},

		{
			component = "image",
			id = "icon",
			offsetX = 0,
			offsetY = -17,
			bob = 1,
			parallax = -1,
		},

		{
			component = "text",
			id = "title",
			offsetX = 0,
			offsetY = -40,
			dropshadowColor = { 0.56, 0.32, 0.73, 1 },
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			id = "level",
			charSpacing = 0,
			offsetX = -1,
			offsetY = 0,
			tierColors = {
				{ 0.90, 0.54, 0.21 },
				{ 0.52, 0.77, 0.60 },
				{ 1, 0.94, 0.53 },
				{ 0.81, 1, 0.91 },
				{ 1, 1, 1 },
			},
			dropshadowColor = { 0, 0, 0, 0.33 },
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "text",
			id = "description",
			offsetY = 16,
			color = { 0.41, 0.35, 0.34 },
			dropshadowColor = { 0.09, 0.08, 0.08, 1 },
			maxWidth = 46,
			horizontalAlign = "center",
			verticalAlign = "center",
		},

		{
			component = "shader",
			id = "skew",
			shaders = {
				"Brightness",
				{ Skew = { u_amount = 0.1 } },
				{ Rimlight = { u_coneWidth = 4, u_inner = 0.4, u_outer = 1, u_threshold = 0.25, u_rim_strength = 0 } },
				"Burn",
			},
		},
	},
}
