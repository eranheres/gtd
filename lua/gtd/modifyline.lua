local task_line = require("gtd.taskline")
local log = require("plenary.log"):new()
local client = require("obsidian").get_client()
local ui = require("gtd.ui")
log.level = "debug"

---@class CustomModule
local M = {}

local replace_current_line = function(line)
  local current_line = vim.api.nvim_get_current_line()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(current_buf, current_line_num - 1, current_line_num, false, { line })
end

M.update_task_line = function(fields, line)
  local current_line = line or vim.api.nvim_get_current_line()
  local task = task_line.from_string(current_line)
  if not task_line.is_valid(task) then
    vim.print("This line is not a valid task line for modification")
    return
  end
  task = task_line.update_fields(task, fields)
  if line then
    return task_line.to_string(task)
  else
    replace_current_line(task_line.to_string(task))
    return task
  end
end

-- Creates a note information on a different file. The file will be created if not already exists.
-- The file will be named the same as the current buf filename and located under notes directory, a subfolder of the current file directory
-- which will also be created if not already exists.
-- @param note string: The note informatio to be stored in the file
M.set_create_note_info = function(info)
  -- TODO use client:current_note
  local current_note = client:current_note()
  if not current_note then
    vim.print("Current buf is not a note")
    return
  end
  local new_note_id = "notes-" .. current_note.id

  local notes = client:find_notes(
    new_note_id,
    { notes = {
      load_contents = true,
      collect_anchor_links = true,
      collect_blocks = true,
    } }
  )
  if #notes == 0 then
    vim.print("Note not found")
    client:create_note({
      id = new_note_id,
      title = "notes",
      dir = "notes",
      template = "Tasks Notes Template.md",
    })
    return
  end

  local new_section = {
    "",
    "# TASK:" .. info.title,
    "CREATED: " .. info.created,
    "UPDATED: [[" .. os.date("%Y-%m-%d") .. "]]",
    "STATUS: " .. info.status,
    "TASK NOTE: [[" .. current_note.id .. "]]",
    "NOTE: " .. info.note,
  }
  local note = notes[1]
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

--
-- Set a task as done
-- @param line string: The task line to be marked as done (optional)
-- @return nil
M.complete_task = function(info, line)
  local completion_date = os.date("%Y-%m-%d")
  local updated_fields = { status = "x", note = completion_date }
  local task = M.update_task_line(updated_fields, line)
  local opts = {}
  ui.input_prompt("📝 Completion note", "note", function()
    M.set_create_note_info({
      title = task.text,
      created = "Created date",
      status = "Completed",
      note = opts.note,
    })
  end, opts)
end

return M
