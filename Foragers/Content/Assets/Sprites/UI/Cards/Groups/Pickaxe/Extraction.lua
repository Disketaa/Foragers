return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "rockCrystalBonus", amount = 20 },
	rarity = "common",
	components = {
		{
			component = "text",
			id = "title",
			text = { key = "card.extraction" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffCrystalsFromRocks", params = { n = 1 } },
		},
	},
}