return {
	extends = "Content.Assets.Sprites.UI.Cards._Base",
	object = "card",
	group = "pickaxe",
	modifier = { stat = "damage", amount = 2 },
	components = {
		{
			component = "image",
			id = "frame",
			image = "Content/Assets/Sprites/UI/Cards/Frames/Purple",
		},

		{
			component = "image",
			id = "icon",
			image = "Content/Assets/Sprites/UI/Cards/Icons/BronzePickaxe",
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
