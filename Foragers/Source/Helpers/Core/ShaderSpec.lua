local ShaderSpec = {}

--- Normalize a shader entry to a spec table.
--- Accepts: string name, table with .name, or compact table { Name = params }.
---@param entry string|table
---@return table|nil spec
function ShaderSpec.parse(entry)
	if type(entry) == "string" then
		return { name = entry }
	elseif entry.name ~= nil then
		return entry
	end
	local name, params = next(entry)
	if not name then
		return nil
	end
	local spec = { name = name }
	if type(params) == "table" then
		for k, v in pairs(params) do
			spec[k] = v
		end
	end
	return spec
end

return ShaderSpec