return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "damage", amount = 1 },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "overlay",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Icons/Sharp",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.sharpness" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffDamage" },
		},
	},
}