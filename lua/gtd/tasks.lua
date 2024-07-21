local task_line = require("gtd.taskline")
local utils = require("gtd.utils")
local tasklog = require("gtd.logs")
local log = require("plenary.log"):new()
local ui = require("gtd.ui")
local Menu = require("nui.menu")
log.level = "debug"

---@class CustomModule
local M = {}

local replace_current_line = function(line)
  local current_buf = vim.api.nvim_get_current_buf()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(current_buf, current_line_num - 1, current_line_num, false, { line })
end

M.task_in_current_line = function()
  local current_line = vim.api.nvim_get_current_line()
  local task = task_line.from_string(current_line)
  if task_line.is_valid(task) then
    return task
  end
  return nil
end

M.update_task_line = function(fields)
  local task = M.task_in_current_line()
  if task == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  task = task_line.update_fields(task, fields)
  replace_current_line(task_line.to_string(task))
  return task
end

local priorities = {
  Menu.item("Urgent (A)", { value = "A" }),
  Menu.item("High (B)", { value = "B" }),
  Menu.item("Normal (C)", { value = "C" }),
  Menu.item("Low (D)", { value = "D" }), -- default value
}

local yesno = {
  Menu.item("Yes", { value = true }),
  Menu.item("No", { value = false }),
}

M.new_task = function()
  local opts = { task_id = utils.guid() }
  ui.input_prompt("📝 Task Line", "text", "", function()
    if opts.text == nil then
      return
    end
    ui.date_picker("📅 Due Date", "due_date", function()
      if opts.due_date == nil then
        return
      end
      ui.options_picker("⏫ Task Priority", "priority", priorities, function()
        opts.status = " "
        if opts.priority == nil then
          return
        end
        opts.created_date = os.date("%Y-%m-%d")
        local str = task_line.to_string(opts)
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line_nr = cursor[1]
        vim.api.nvim_buf_set_lines(bufnr, line_nr, line_nr, false, { str })
        tasklog.set_create_log({
          task_id = opts.task_id,
          title = opts.text,
          action = "Created",
          log = "Priority to (" .. opts.priority .. ") and due date to (" .. opts.due_date .. ")",
        })
      end, opts)
    end, opts)
  end, opts)
end

M.new_quick_task = function()
  local current_line = vim.api.nvim_get_current_line()
  if #current_line > 0 then
    vim.api.nvim_command("normal! $o")
  end
  local task = {
    text = "",
    status = " ",
    created_date = os.date("%Y-%m-%d"),
    task_id = utils.guid(),
  }
  tasklog.set_create_log({
    task_id = task.task_id,
    title = "Quick task",
    action = "Completed",
    log = "Created quick task",
  })
  local text = task_line.to_string(task)
  vim.api.nvim_put({ text }, "c", true, true)
  vim.api.nvim_command("normal! 14h")
  vim.api.nvim_command("startinsert")
end

--
-- Set a task as done
-- @param line string: The task line to be marked as done (optional)
-- @return nil
M.complete_task = function()
  local task = M.task_in_current_line()
  if task == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  if task.status == "x" then
    vim.print("Task already completed")
    return
  end
  if task.status == "r" then
    M.complete_repeated_task()
    return
  end
  local completion_date = os.date("%Y-%m-%d")
  local updated_fields = { status = "x", note = completion_date }
  local opts = {}
  ui.input_prompt(" 📝 Completion note ", "note", "", function()
    if opts.note == nil then
      return
    end
    task = M.update_task_line(updated_fields)
    tasklog.set_create_log({
      task_id = task.task_id,
      title = task.text,
      action = "Completed",
      log = opts.note or "",
    })
  end, opts)
end

M.complete_repeated_task = function()
  local task = M.task_in_current_line()
  if task == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local completion_date = os.date("%Y-%m-%d")
  local due_date = task_line.next_due_date(task)
  local updated_fields = { note = completion_date, due_date = due_date }
  local opts = {}
  ui.input_prompt(" 📝 Repeated completion note ", "note", "", function()
    if opts.note == nil then
      return
    end
    task = M.update_task_line(updated_fields)
    tasklog.set_create_log({
      task_id = task.task_id,
      title = task.text,
      action = "Repeat completed",
      log = opts.note or "",
    })
  end, opts)
end

M.assigne_task = function()
  local ctask = M.task_in_current_line()
  if ctask == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local date = os.date("%Y-%m-%d")
  local opts = { status = ">" }
  ui.input_prompt(" 🤵 Assignee ", "assignee", "", function()
    if opts.assignee == nil then
      return
    end
    ui.date_picker(" 📅 On Date ", "due_date", function()
      if opts.due_date == nil then
        return
      end
      local task = M.update_task_line(opts)
      tasklog.set_create_log({
        task_id = task.task_id,
        title = task.text,
        action = "Assigned",
        log = "Assigned to [" .. opts.assignee .. "] on the [" .. date .. "]",
      })
    end, opts)
  end, opts)
end

M.set_due_date = function()
  local ctask = M.task_in_current_line()
  if ctask == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local date = os.date("%Y-%m-%d")
  local opts = {}
  ui.date_picker("📅 Due Date", "due_date", function()
    if opts.due_date == nil then
      return
    end
    ui.input_prompt(" 📝 Reason ", "note", "", function()
      local reason = ""
      if opts.note ~= nil then
        reason = " | Reason: " .. opts.note
      end
      local task = M.update_task_line(opts)
      tasklog.set_create_log({
        task_id = task.task_id,
        title = task.text,
        action = "Set due date",
        log = "New date:[" .. task.due_date .. "]" .. reason,
      })
    end, opts)
  end, opts)
end

M.set_priority = function()
  local ctask = M.task_in_current_line()
  if ctask == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local opts = {}
  ui.options_picker(" ⏫ Task Priority ", "priority", priorities, function()
    if opts.priority == nil then
      return
    end
    local task = M.update_task_line(opts)
    tasklog.set_create_log({
      task_id = task.task_id,
      title = task.text,
      action = "Set task priority",
      log = "Set priority to (" .. opts.priority .. ")",
    })
  end, opts)
end

M.set_text = function()
  local current_task = M.task_in_current_line()
  if current_task == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local opts = {}
  ui.input_prompt(" 📝 Task description ", "text", current_task.text, function()
    if opts.text == nil then
      return
    end
    local task = M.update_task_line(opts)
    tasklog.set_create_log({
      task_id = task.task_id,
      title = task.text,
      action = "Modified task",
      log = "Modified to: " .. opts.text,
    })
  end, opts)
end

M.add_log = function()
  local task = M.task_in_current_line()
  if task == nil then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  local opts = {}
  ui.input_prompt(" 📝 Log text ", "text", "", function()
    if opts.text == nil then
      return
    end
    tasklog.set_create_log({
      task_id = task.task_id,
      title = task.text,
      action = "Manual log",
      log = "manual log:" .. opts.text,
    })
  end, opts)
end

M.color_due = function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Clear previous highlights in the namespace
  local namespace_name = "overduetask"
  local namespace = vim.api.nvim_get_namespaces()[namespace_name]
  if namespace == nil then
    namespace = vim.api.nvim_create_namespace(namespace_name)
  end
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  -- Get the lines in the buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  vim.cmd([[highlight overduetask ctermbg=red guibg=#fca683]])
  -- Iterate over each line to find matches
  for lnum, line in ipairs(lines) do
    local task = task_line.from_string(line)
    if
      task
      and task_line.is_valid(task)
      and (task.status == " " or task.status == "r" or task.status == ">")
      and task.due_date
      and task.due_date <= os.date("%Y-%m-%d")
    then
      vim.api.nvim_buf_add_highlight(bufnr, namespace, "overduetask", lnum - 1, 0, -1)
    else
    end
  end
end

return M
