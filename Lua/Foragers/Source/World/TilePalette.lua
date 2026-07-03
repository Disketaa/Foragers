local TilePalette = {}

function TilePalette.resolve(mask, tileMap)
	return tileMap[mask + 1]
end

function TilePalette.resolveVariant(tileIndex, variants, seed)
	local options = variants[tileIndex]
	if not options or #options == 0 then
		return tileIndex
	end
	return options[(seed % #options) + 1]
end

return TilePalette
