local Menu = require("nui.menu")
local ui = require("gtd.ui")
local log = require("plenary.log"):new()
log.level = "debug"

---@class CustomModule
local M = {}

local function done_function(opts)
  log.debug("done_function", opts)
  local task = TaskLine:new()
  task.status = " "
  task.text = opts.text
  task.due_date = opts.due
  task.priority = opts.priority
  task.assignee = opts.assignee
  local str = task:to_string({
    status = true,
    text = true,
    due_date = true,
    priority = true,
    assignee = true,
  })
  log.debug("Task string", str)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  vim.api.nvim_buf_set_lines(bufnr, line_nr, line_nr, false, { str })
end

local opts = {}
local priorities = {
  Menu.item("Urgent (A)", { value = "A" }),
  Menu.item("High (B)", { value = "B" }),
  Menu.item("Normal (C)", { value = "C" }),
  Menu.item("Low (C)", { value = "D" }), -- default value
}

local yesno = {
  Menu.item("Yes", { value = true }),
  Menu.item("No", { value = false }),
}

M.new_task = function()
  ui.input_prompt("📝 Task Line", "text", function()
    ui.date_picker("📅 Due Date", "due", function()
      ui.options_picker("⏫ Task Priority", "priority", priorities, function()
        ui.input_prompt("🤵 Assignee", "assignee", function()
          done_function(opts)
        end, opts)
      end, opts)
    end, opts)
  end, opts)
end

return M
