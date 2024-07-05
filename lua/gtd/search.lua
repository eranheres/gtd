local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local config = require("telescope.config").values

local log = require("plenary.log"):new()

local gtd_utils = require("gtd.utils")
local task_line = require("gtd.taskline")

log.level = "debug"

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
    .new({}, {
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
            -- "-U", -- Allow searching across multiple lines
            "-P", -- Use Perl-compatible regex
            "^- \\[ \\].*due:\\[",
          }
          return cmd
        end,
        entry_maker = function(entry)
          local parsed = vim.json.decode(entry)
          if parsed and parsed.type == "match" and detect_date_in_string(parsed.data.lines.text) then
            local txt = parsed.data.lines.text
            txt = txt:sub(1, -2)
            local task = task_line.from_string(txt)
            if not task_line.is_valid(task) then
              return
            end
            log.debug(task.due_date)
            if task.due_date > os.date("%Y-%m-%d") then
              return
            end
            return {
              value = parsed,
              display = txt,
              ordinal = parsed.data.lines.text,
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
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          log.debug("Selected", selection)
          log.debug("Path", selection.value.data.path.text)
          actions.close(prompt_bufnr)
          vim.api.nvim_command("edit " .. selection.value.data.path.text)
          vim.api.nvim_win_set_cursor(0, { selection.value.data.line_number, 0 })
        end)

        -- Custom action on C-s
        map("n", "<leader>", function()
          local selection = action_state.get_selected_entry()
          log.info("C-s pressed on selection:", selection)
          -- Define your custom action here
          -- For example, print the selected entry
          print("Selected entry: ", vim.inspect(selection))
          gtd_utils.toggle_checkbox(selection.value.data.path.text, selection.value.data.line_number)
          --actions.close(prompt_bufnr)
        end)

        return true
      end,
    })
    :find()
end
M.search_task()
return M
