local task_line = require("gtd.taskline")
local log = require("plenary.log"):new()
local client = require("obsidian").get_client()
local ui = require("gtd.ui")
local Menu = require("nui.menu")
log.level = "debug"

---@class CustomModule
local M = {}

local replace_current_line = function(line)
  local current_line = vim.api.nvim_get_current_line()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(current_buf, current_line_num - 1, current_line_num, false, { line })
end

M.is_current_line_valid = function()
  local current_line = vim.api.nvim_get_current_line()
  local task = task_line.from_string(current_line)
  return task_line.is_valid(task)
end

M.update_task_line = function(fields)
  local current_line = vim.api.nvim_get_current_line()
  local task = task_line.from_string(current_line)
  if not task_line.is_valid(task) then
    vim.print("This line is not a valid task line for modification")
    return {}
  end
  task = task_line.update_fields(task, fields)
  replace_current_line(task_line.to_string(task))
  return task
end

-- Creates a note information on a different file. The file will be created if not already exists.
-- The file will be named the same as the current buf filename and located under notes directory, a subfolder of the current file directory
-- which will also be created if not already exists.
-- @param note string: The note informatio to be stored in the file
M.set_create_log = function(info)
  -- TODO use client:current_note
  local current_note = client:current_note()
  if not current_note then
    vim.print("Current buf is not a note")
    return
  end
  local new_note_id = "log-" .. current_note.id

  local notes = client:find_notes(
    new_note_id,
    { notes = {
      load_contents = true,
      collect_anchor_links = true,
      collect_blocks = true,
    } }
  )
  local note
  if #notes == 0 then
    log.info("Note not found - creating new note")
    note = client:create_note({
      id = new_note_id,
      title = "notes",
      dir = "Logs",
      template = "Tasks Logs Template.md",
    })
  end

  local new_section = {
    "",
    "# TASK: " .. info.title,
    "LOG   : " .. info.log,
    "ACTION: " .. info.action,
    "DATE  : [[" .. os.date("%Y-%m-%d") .. "]]",
    "SOURCE: [[" .. current_note.id .. "]]",
  }
  note = notes[1]
  if note == nil then
    vim.print("Note not found")
    return
  end

  vim.list_extend(note.contents, new_section)
  note:save({
    update_content = function(content)
      vim.list_extend(content, new_section)
      return content
    end,
  })
end

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
  local opts = {}
  ui.input_prompt("📝 Task Line", "text", function()
    ui.date_picker("📅 Due Date", "due_date", function()
      ui.options_picker("⏫ Task Priority", "priority", priorities, function()
        opts.status = " "
        opts.created_date = os.date("%Y-%m-%d")
        local str = task_line.to_string(opts)
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line_nr = cursor[1]
        vim.api.nvim_buf_set_lines(bufnr, line_nr, line_nr, false, { str })
        M.set_create_log({
          title = opts.text,
          action = "Created",
          log = "Spriority to ("..opts.priority..") and due date to ("..opts.priority..")",
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
  }
  local text = task_line.to_string(task)
  vim.api.nvim_put({ text }, "c", true, true)
  vim.api.nvim_command("normal! 22h")
  vim.api.nvim_command("startinsert")
end

--
-- Set a task as done
-- @param line string: The task line to be marked as done (optional)
-- @return nil
M.complete_task = function()
  local current_line = vim.api.nvim_get_current_line()
  local task = task_line.from_string(current_line)
  if not task_line.is_valid(task) then
    vim.print("This line is not a valid task line for modification")
    return
  end
  if task.status == "r" then
    M.complete_repeated_task()
    return
  end
  local completion_date = os.date("%Y-%m-%d")
  local updated_fields = { status = "x", note = completion_date }
  task = M.update_task_line(updated_fields)
  local opts = {}
  ui.input_prompt(" 📝 Completion note ", "note", function()
    M.set_create_log({
      title = task.text,
      action = "Completed",
      log = opts.note or "",
    })
  end, opts)
end

M.complete_repeated_task = function()
  local line = vim.api.nvim_get_current_line()
  local task = task_line.from_string(line)
  if not task_line.is_schedule_valid(task) then
    vim.print("Task line is not a valid repeated task")
    return
  end
  local completion_date = os.date("%Y-%m-%d")
  local due_date = task_line.next_due_date(task)
  local updated_fields = { note = completion_date, due_date = due_date }
  task = M.update_task_line(updated_fields)
  local opts = {}
  ui.input_prompt(" 📝 Repeated completion note ", "note", function()
    M.set_create_log({
      title = task.text,
      action = "Repeat completed",
      log = opts.note or "",
    })
  end, opts)
end

M.assigne_task = function()
  if not M.is_current_line_valid() then
    vim.print("Line is not a valid task line")
    return
  end
  local date = os.date("%Y-%m-%d")
  local opts = { status = ">" }
  ui.input_prompt("🤵 Assignee ", "assignee", function()
    ui.date_picker("📅 Followup Date", "followup_date", function()
      local task = M.update_task_line(opts)
      M.set_create_log({
        title = task.text,
        action = "Assigned",
        log = "Assigned to [" .. opts.assignee .. "] on the [" .. date .. "]",
      })
    end, opts)
  end, opts)
end

M.set_due_date = function()
  if not M.is_current_line_valid() then
    vim.print("Line is not a valid task line")
    return
  end
  local date = os.date("%Y-%m-%d")
  local opts = {}
  ui.date_picker("📅 Due Date", "due_date", function()
    local task = M.update_task_line(opts)
    M.set_create_log({
      title = task.text,
      action = "Set due date",
      log = "Set due date to [" .. date .. "]",
    })
  end, opts)
end

M.set_priority = function()
  if not M.is_current_line_valid() then
    vim.print("Line is not a valid task line")
    return
  end
  local date = os.date("%Y-%m-%d")
  local opts = {}
  ui.options_picker("⏫ Task Priority", "priority", priorities, function()
    local task = M.update_task_line(opts)
    M.set_create_log({
      title = task.text,
      action = "Set task priority",
      log = "Set priority to (" .. opts.priority .. ")",
    })
  end, opts)
end

return M
