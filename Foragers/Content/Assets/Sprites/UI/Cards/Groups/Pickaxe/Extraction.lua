return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "rockCrystalBonus", baseAmount = 1 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Backgrounds/Cavern",
		},

		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Crystals",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.extraction" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffCrystalsFromRocks" },
		},
	},
}