return {
	extends = "Content.Assets.Sprites.UI.Cards._Base",
	object = "card",
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
			text = { key = "card.speedy" },
		},

		{
			component = "text",
			id = "description",
			text = { key = "modifier.buffTempo", params = { n = 1 } },
		},
	},
}