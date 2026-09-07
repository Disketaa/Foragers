return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "movementSpeed", amount = 10 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "icon",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/AttackSpeed",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.furious" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffTempo", params = { n = 1 } },
		},
	},
}