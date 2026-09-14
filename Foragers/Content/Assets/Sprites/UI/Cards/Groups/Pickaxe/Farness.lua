return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "attackRange", baseAmount = 1 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Enlarge",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.farness" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffAttackRange" },
		},
	},
}