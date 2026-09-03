return {
	extends = "Content.Assets.Sprites.UI.Cards._Base",
	object = "card",
	group = "pickaxe",
	components = {
		{
			component = "sound",
			volume = 0.7,
			tags = {
				card_choose = { "Content/Assets/Sounds/Events/Tool.ogg" },
			},
		},

		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Backgrounds/Cavern",
		},
	},
}
