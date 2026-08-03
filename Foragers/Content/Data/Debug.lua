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
		color = { 1, 0, 0, 0.5 },
		size = 1,
	},
}
