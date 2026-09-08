return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "attackSpeed", amount = 1 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Strip",
		},

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