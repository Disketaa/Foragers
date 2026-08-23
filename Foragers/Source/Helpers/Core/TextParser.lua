-- Universal entry used by ValueParser for every `text` key, so any text-based
-- component (Label, TextEmitter, Counter label, ...) localizes for free.
--
-- Field forms accepted:
--   "@card.durability"              -> I18n key lookup (no params)
--   { key = "card.bonus", params = { n = 2 } } -> key lookup + interpolation
--   "1" / "literal" / 42            -> returned unchanged (literal / dynamic)
local I18n = require("Source.Helpers.Core.I18n")

local TextParser = {}

local KEY_PREFIX = "@"

---@param field string|table|number|nil
---@return string|number|table|nil
function TextParser.resolve(field)
	if type(field) == "table" and field.key ~= nil then
		return I18n.t(tostring(field.key), field.params)
	end
	if type(field) == "string" and field:sub(1, #KEY_PREFIX) == KEY_PREFIX then
		return I18n.t(field:sub(#KEY_PREFIX + 1))
	end
	return field
end

return TextParser
