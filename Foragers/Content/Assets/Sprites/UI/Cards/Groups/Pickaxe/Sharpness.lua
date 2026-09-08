local I18n = require("Source.Helpers.Core.I18n")
local amount = 2

return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "damage", amount = amount },
	rarity = "common",
	components = {
		{
			component = "text",
			id = "title",
			text = { key = "card.sharpness" },
		},

		{
			component = "text",
			id = "description",
			text = I18n.withAmount("modifier.buffDamage", amount),
		},
	},
}