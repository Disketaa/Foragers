return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "damage", amount = 2 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "icon",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Geode",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.extraction" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffDamage", params = { n = 2 } },
		},
	},
}