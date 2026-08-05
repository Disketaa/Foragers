return {
	width = 20,
	height = 20,
	tileSize = 8,
	backgroundColor = { 0.25, 0.74, 0.9 },
	borderTileOffset = 8,
	noise = { seed = -1, scale = 0.15, detail = 0.3, density = 0.8 },
	props = {
		coverage = 0.25,
		spawnInterval = 3,
		vegetables = { density = 0.025, pseudoRandomChance = 0.01 },
		items = {
			{ data = "Content.Assets.Sprites.Props.OakTree", weight = 2 },
			{ data = "Content.Assets.Sprites.Props.BirchTree", weight = 2 },
			{ data = "Content.Assets.Sprites.Props.Rocks", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.Turnip", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.Carrot", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.OakStump", weight = 5 },
			{ data = "Content.Assets.Sprites.Props.BirchStump", weight = 5 },
			{ data = "Content.Assets.Sprites.Props.OakBush", weight = 5 },
			{ data = "Content.Assets.Sprites.Props.BirchBush", weight = 5 },
		},
	},
}
