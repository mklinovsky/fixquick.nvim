local parser = require("fixquick.parser")

local M = {}

---@class FixquickConfig
---@field commands boolean Create user commands (default: true)
---@field open_qf boolean Auto-open quickfix window (default: true)

---@type FixquickConfig
local defaults = {
	commands = true,
	open_qf = true,
}

---@type FixquickConfig
M.config = {}

---@param findings table[] Parsed error locations from parser.parse
---@param opts? { title?: string }
function M.populate(findings, opts)
	opts = opts or {}

	if not findings or #findings == 0 then
		vim.notify("fixquick: no error locations found", vim.log.levels.WARN)
		return
	end

	local qf_list = {}
	for _, item in ipairs(findings) do
		table.insert(qf_list, {
			filename = item.path,
			lnum = item.line,
			col = item.col or 0,
			text = item.message or "Error",
		})
	end

	vim.fn.setqflist(qf_list, "r")
	if opts.title then
		vim.fn.setqflist({}, "a", { title = opts.title })
	end

	if M.config.open_qf then
		vim.cmd("copen")
	end

	vim.notify("fixquick: " .. #qf_list .. " items", vim.log.levels.INFO)
end

--- Parse text and populate quickfix.
---@param text string Raw build/lint output.
---@param opts? { title?: string }
function M.parse_and_populate(text, opts)
	local clean = parser.strip_ansi(text)
	local findings = parser.parse(clean)
	M.populate(findings, opts)
end

--- Run a shell command asynchronously, parse output, populate quickfix.
---@param cmd string Shell command to run.
---@param opts? { title?: string }
function M.run(cmd, opts)
	opts = opts or {}
	local output_lines = {}

	vim.notify("fixquick: running " .. cmd, vim.log.levels.INFO)

	vim.fn.jobstart(cmd .. " 2>&1", {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.list_extend(output_lines, data)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local raw = table.concat(output_lines, "\n")
				M.parse_and_populate(raw, { title = opts.title or cmd })
				if exit_code == 0 then
					vim.notify("fixquick: command succeeded", vim.log.levels.INFO)
				else
					vim.notify("fixquick: command failed (exit " .. exit_code .. ")", vim.log.levels.WARN)
				end
			end)
		end,
	})
end

local function create_commands()
	vim.api.nvim_create_user_command("FixQuick", function()
		local clipboard = vim.fn.getreg("+")
		M.parse_and_populate(clipboard, { title = "clipboard" })
	end, {
		desc = "Parse clipboard content for errors and populate quickfix",
	})

	vim.api.nvim_create_user_command("FixQuickBuffer", function()
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local content = table.concat(lines, "\n")
		M.parse_and_populate(content, { title = "buffer" })
	end, {
		desc = "Parse current buffer for errors and populate quickfix",
	})

	vim.api.nvim_create_user_command("FixQuickRun", function(cmd_opts)
		local cmd = cmd_opts.args
		if cmd == "" then
			cmd = vim.fn.input("Command: ")
		end
		if cmd == "" then
			return
		end
		M.run(cmd)
	end, {
		nargs = "?",
		desc = "Run a shell command and parse output into quickfix",
	})
end

---@param opts? FixquickConfig
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts or {})

	if M.config.commands then
		create_commands()
	end
end

return M
