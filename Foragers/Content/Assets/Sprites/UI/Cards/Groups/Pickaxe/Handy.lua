return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "movementSpeed", amount = 10 },
	rarity = "common",
	components = {
		{
			component = "text",
			id = "title",
			text = { key = "card.handy" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffAttackSpeed" },
		},
	},
}