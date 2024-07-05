local Menu = require("nui.menu")
local ui = require("gtd.ui")
local log = require("plenary.log"):new()
local task_line = require("gtd.taskline")
log.level = "debug"

---@class CustomModule
local M = {}

local function done_function(task)
  log.debug("done_function", task)
  task.status = " "
  task.created_date = os.date("%Y-%m-%d")
  local str = task_line.to_string(task)
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

M.nnew_task = function()
  ui.input_prompt("📝 Task Line", "text", function()
    ui.date_picker("📅 Due Date", "due_date", function()
      ui.options_picker("⏫ Task Priority", "priority", priorities, function()
        done_function(opts)
      end, opts)
    end, opts)
  end, opts)
end

M.nnew_quick_task = function()
  local current_line = vim.api.nvim_get_current_line()
  if #current_line > 0 then
    vim.api.nvim_command("normal! $o")
  end
  local task = {
    text = "",
    status = " ",
    created_date = os.date("%Y-%m-%d"),
  }
  local text = task_line.to_string(task)
  vim.api.nvim_put({ text }, "c", true, true)
  vim.api.nvim_command("normal! 22h")
  vim.api.nvim_command("startinsert")
end

return M
