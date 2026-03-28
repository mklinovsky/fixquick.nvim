local M = {}

---@param text string Raw build/lint output.
---@return table[] List of { path: string, line: number, col: number?, message: string? }
function M.parse(text)
	local results = {}
	local seen = {}
	local lines = vim.split(text, "\n")
	local current_file = nil

	for _, line in ipairs(lines) do
		-- Eslint format: standalone file path followed by indented errors
		local file_match = line:match("^(/[^%s]+%.[%w]+)$") or line:match("^(%S+[/\\]%S+%.[%w]+)$")
		if file_match and not file_match:match("^@") then
			current_file = file_match
			goto continue
		end

		-- Indented error line: "  36:1  error  Some message  rule-name"
		if current_file then
			local lnum, col, msg = line:match("^%s+(%d+):(%d+)%s+%w+%s+(.+)")
			if lnum then
				local key = current_file .. ":" .. lnum .. ":" .. col
				if not seen[key] then
					seen[key] = true
					table.insert(results, {
						path = current_file,
						line = tonumber(lnum),
						col = tonumber(col),
						message = vim.trim(msg),
					})
				end
				goto continue
			end
		end

		-- Fallback: "path:line:col" on a single line (tsc, gcc, etc.)
		for path, lnum, col in line:gmatch("([^:%s]+):(%d+):(%d+)") do
			if not path:match("^@") and path:match("%.[%w]+$") then
				local key = path .. ":" .. lnum .. ":" .. col
				if not seen[key] then
					seen[key] = true
					local msg = line:match(path .. ":%d+:%d+[:%s]*(.+)")
					table.insert(results, {
						path = path,
						line = tonumber(lnum),
						col = tonumber(col),
						message = msg and vim.trim(msg) or nil,
					})
				end
			end
		end

		if not line:match("^%s+%d+:%d+") and not line:match("^%s*$") then
			current_file = nil
		end

		::continue::
	end

	return results
end

---@param text string Raw text potentially containing ANSI escape codes.
---@return string Cleaned text.
function M.strip_ansi(text)
	return text:gsub("\27%[[%d;]*m", "")
end

return M
