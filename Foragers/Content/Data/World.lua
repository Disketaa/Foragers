return {
	seed = -1,
	width = 15,
	height = 15,
	tileSize = 8,
	backgroundColor = { 0.15, 0.625, 0.8 },
	borderTileOffset = 8,
	noise = { scale = 0.15, detail = 0.3, density = 0.8 },
	dayCycle = {
		dayLengthSec = 300,
		sunriseHour = 6,
		sunsetHour = 18,
		smoothness = 0.15,
		shadow = { maxLen = 4, stretchPx = 8, stretchWindow = 0.125, stretchPower = 4, timeShiftPerPx = 0.01, worldCenterX = 0 },
	},

	ambient = {
		density = 0.1,
		day = {
			spawnInterval = 6,
			spawnTime = "7>17",
			types = { "Content/Assets/Sprites/Ambient/BirdwingButterfly", "Content/Assets/Sprites/Ambient/MonarchButterfly", "Content/Assets/Sprites/Ambient/MorphoButterfly" },
		},

		night = {
			spawnInterval = 4,
			spawnTime = "19>5",
			types = { "Content/Assets/Sprites/Ambient/Firefly" },
		},
	},

	props = {
		coverage = 0.33,
		spawnInterval = 3,
		vegetables = { density = 0.025, pseudoRandomChance = 0.075 },
		items = {
			{ data = "Content.Assets.Sprites.Props.BirchTree", weight = 1 },
			{ data = "Content.Assets.Sprites.Props.OakTree", weight = 1 },
			{ data = "Content.Assets.Sprites.Props.Berries", weight = 3, host = "bush", offsetY = -3, inheritFrame = true },
			{ data = "Content.Assets.Sprites.Props.Snail", weight = 3, host = "rock", offsetY = -5 },
			{ data = "Content.Assets.Sprites.Props.RedMushroom", weight = 3, host = "oakStump", offsetY = -6 },
			{ data = "Content.Assets.Sprites.Props.BrownMushroom", weight = 3, host = "birchStump", offsetY = -5 },
			{ data = "Content.Assets.Sprites.Props.Rocks", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.Turnip", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.Carrot", weight = 4 },
			{ data = "Content.Assets.Sprites.Props.Bush", weight = 5 },
			{ data = "Content.Assets.Sprites.Props.OakStump", weight = 5 },
			{ data = "Content.Assets.Sprites.Props.BirchStump", weight = 5 },
		},
	},
}
