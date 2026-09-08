local I18n = require("Source.Helpers.Core.I18n")
local amount = 1

return {
	extends = "Content.Assets.Sprites.UI.Cards.Groups.Pickaxe._Pickaxe",
	modifier = { stat = "movementSpeed", amount = amount },
	rarity = "common",
	components = {
		{
			component = "text",
			id = "title",
			text = { key = "card.handy" },
		},

		{
			component = "text",
			id = "description",
			text = I18n.withAmount("modifier.buffAttackSpeed", amount),
		},
	},
}