return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "movementSpeed", amount = 10 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "icon",
			image = "Content/Assets/Sprites/UI/Weapons/Pickaxe",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.speedy" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffTempo", params = { n = 1 } },
		},
	},
}