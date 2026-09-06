local Rarity = {
	common = {
		colors = {
			{ 0.54, 0.76, 0.76 },
			{ 0.36, 0.6, 0.47 },
			{ 0.39, 0.52, 0.54 },
			{ 0.27, 0.32, 0.33 },
		},
	},

	uncommon = {
		colors = {
			{ 0.3, 0.8, 0.3 },
			{ 0.2, 0.6, 0.2 },
			{ 0.15, 0.5, 0.15 },
			{ 0.1, 0.4, 0.1 },
		},
	},

	rare = {
		colors = {
			{ 0.3, 0.5, 0.9 },
			{ 0.2, 0.35, 0.7 },
			{ 0.15, 0.25, 0.55 },
			{ 0.1, 0.2, 0.4 },
		},
	},

	legendary = {
		colors = {
			{ 0.9, 0.6, 0.1 },
			{ 0.7, 0.4, 0.05 },
			{ 0.55, 0.3, 0.02 },
			{ 0.4, 0.2, 0.01 },
		},
	},
}

function Rarity.rarityNameForLevel(level)
	if level >= 4 then return "legendary"
	elseif level >= 3 then return "rare"
	elseif level >= 2 then return "uncommon"
	else return "common"
	end
end

return Rarity