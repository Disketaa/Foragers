return {
	debug = true,

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

	hud = {
		enabled = true,
		size = 5,
		padding = 3,
		fps = true,
		fpsGraph = true,
		objectCount = true,
		fpsTarget = 180,
		backgroundColor = { 0, 0, 0, 0.3 },
		labelColor = { 0.65, 0.65, 0.9, 1 },
		color = { 1, 1, 1, 1 },
		graphColor = { 0, 1, 0, 1 },
		graphDropColor = { 1, 0, 0, 1 },
	},
}
