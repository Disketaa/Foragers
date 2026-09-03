return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "damage", amount = 2 },
	components = {
		{
			component = "image",
			id = "frame",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Frames/Purple",
		},

		{
			component = "image",
			id = "icon",
			image = "Content/Assets/Sprites/UI/Weapons/Pickaxe",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.durability" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffDamage", params = { n = 2 } },
		},
	},
}
