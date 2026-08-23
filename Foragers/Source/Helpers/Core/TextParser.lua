-- Universal entry used by ValueParser for every `text` key, so any text-based
-- component (Label, TextEmitter, Counter label, ...) localizes for free.
--
-- Field forms accepted:
--   { key = "card.durability" }                  -> I18n key lookup (no params)
--   { key = "modifier.buffDamage", params = { n = 2 } } -> key lookup + interpolation
--   "1" / "literal" / 42                         -> returned unchanged (literal / dynamic)
-- A translatable value is ALWAYS a table (so params/plural/gender extend it
-- later with zero migration); literal strings never collide with a key marker.
local I18n = require("Source.Helpers.Core.I18n")

local TextParser = {}

---@param field string|table|number|nil
---@return string|number|table|nil
function TextParser.resolve(field)
	if type(field) == "table" and field.key ~= nil then
		return I18n.t(tostring(field.key), field.params)
	end
	return field
end

return TextParser
