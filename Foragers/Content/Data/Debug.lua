return {
	debug = true,

	gizmo = {
		enabled = true,

		collisions = {
			enabled = true,
			exclude = { "tiles" },
			decor = "cross",
			priority = 2,
			color = { 0.6, 0.25, 0.25, 1 },
		},
		boundaries = {
			enabled = true,
			exclude = { "tiles" },
			decor = "dashed",
			thickness = 2,
			backgroundColor = { 0.2, 0.6, 1, 0.35 },
			color = { 0.2, 0.6, 1, 0.7 },
		},
		pivots = {
			enabled = true,
			exclude = { "tiles" },
			priority = 3,
			color = { 0.7, 0, 0, 1 },
			size = 1,
		},
	},

	hud = {
		enabled = true,
		size = 4,
		padding = 2,
		gap = 0,
		updateSpeed = 30,
		backgroundColor = { 0, 0, 0, 0.2 },
		labelColor = { 0.8, 0.8, 1, 1 },
		color = { 1, 1, 1, 1 },
		font = {
			label = "Content/Assets/Fonts/AzeretMonoMedium.ttf",
			value = "Content/Assets/Fonts/AzeretMonoSemiBold.ttf",
		},

		fps = true,
		fpsGraph = {
			enabled = true,
			fpsTarget = 180,
			gap = 2,
			width = 25,
			height = 4,
			thickness = 0.5,
			goodColor = { 0, 1, 0, 1 },
			badColor = { 1, 0, 0, 1 },
		},
		objectCount = true,
	},
}
