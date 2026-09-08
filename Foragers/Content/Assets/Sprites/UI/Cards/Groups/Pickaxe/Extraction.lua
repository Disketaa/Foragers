local I18n = require("Source.Helpers.Core.I18n")
local amount = 1

return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "rockCrystalBonus", amount = amount },
	rarity = "common",
	components = {
		{
			component = "image",
			id = "background",
			image = "Content/Assets/Sprites/UI/Cards/Graphics/Backgrounds/Cavern",
		},

		{
			component = "text",
			id = "title",
			text = { key = "card.extraction" },
		},

		{
			component = "text",
			id = "description",
			text = I18n.withAmount("modifier.buffCrystalsFromRocks", amount),
		},
	},
}