return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "attackRange", baseAmount = -1 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Shrink",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.contraction" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.debuffAttackRange" },
		},
	},
}