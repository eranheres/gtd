local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local config = require("telescope.config").values

local log = require("plenary.log"):new()

log.level = "info"

---@class CustomModule
local M = {}

---@return string
local function detect_date_in_string(str)
	local pattern = "%d%d%d%d%-%d%d%-%d%d"
	local match = string.match(str, pattern)
	return match
end

M.date_format = "YYYY-MM-DD"
M.search_task = function(opts)
	pickers
		.new(opts, {
			prompt_title = "Find Files",
			finder = finders.new_async_job({
				command_generator = function(prompt)
					-- rg --no-heading --color=never -zPU --json '(?m)^- \[ \] .*(\n[ \t]+.*)*'
					local cmd = {
						"rg",
						"--json",
						"--no-heading",
						"--color=never",
						"-z", -- Output null-separated results
						"-U", -- Allow searching across multiple lines
						"-P", -- Use Perl-compatible regex
						"(?m)^- \\[ \\] .*(\n[ \t]+.*)*",
					}
					return cmd
				end,
				entry_maker = function(entry)
					local parsed = vim.json.decode(entry)
					if parsed and parsed.type == "match" and detect_date_in_string(parsed.data.lines.text) then
						local txt = vim.split(parsed.data.lines.text, "\n")
						return {
							value = parsed,
							display = txt[1],
							ordinal = "yyy",
						}
					end
				end,
			}),
			previewer = previewers.new_buffer_previewer({
				title = "Tasks",
				define_preview = function(self, entry)
					--local rich_text = "```markdown\n" .. entry.value.data.lines.text .. "\n```"
					local rich_text = entry.value.data.lines.text
					local txt = vim.split(rich_text, "\n")
					--vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, { entry.txt[1] })
					log.debug(txt)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, txt)
					utils.highlighter(self.state.bufnr, "markdown")
				end,
			}),
			sorter = config.generic_sorter(),
		})
		:find()
end
return M
