local utils = require("gtd.utils")
local client = require("obsidian").get_client()
local log = require("plenary.log"):new()
log.level = "debug"

---@class CustomModule
local M = {}

local find_note = function(note_id)
  local notes = client:find_notes(
    note_id,
    { notes = {
      load_contents = true,
      collect_anchor_links = true,
      collect_blocks = true,
    } }
  )
  if notes == nil or #notes == 0 then
    return nil
  end
  return notes[1]
end

local find_or_create_note = function(log_note_id)
  local note = find_note(log_note_id)
  if note == nil then
    vim.print("Logs note not found - creating a new note")
    note = client:create_note({
      id = log_note_id,
      title = "logs",
      dir = "Logs",
      template = "Tasks Logs Template.md",
    })
    note = find_note(log_note_id)
  end
  return note
end

local find_task_last_line = function(task_id, anchor_links)
  local max = 0
  local log_id_prefix = task_id .. "#log-record-"
  for key, _ in pairs(anchor_links) do
    if string.sub(key, 1, #log_id_prefix) == log_id_prefix then
      local numstr = string.match(key, "(%d)$")
      local num = tonumber(numstr)
      if num and num > max then
        max = num
      end
    end
  end
  local task_last_line = 0
  if max == 0 then
    task_last_line = anchor_links[task_id].line + 4 -- 3 for task record size
  else
    task_last_line = anchor_links[log_id_prefix .. max].line + 2
  end
  return task_last_line, max
end

-- Creates a note information on a different file. The file will be created if not already exists.
-- The file will be named the same as the current buf filename and located under notes directory, a subfolder of the current file directory
-- which will also be created if not already exists.
-- @param note string: The note informatio to be stored in the file
M.set_create_log = function(info, d_note_id)
  local current_note_id
  if d_note_id == nil then
    local current_note = client:current_note()
    if not current_note then
      vim.print("Current buf is not a note")
      return
    end
    current_note_id = current_note.id
  else
    current_note_id = d_note_id
  end

  local log_note_id = "log-" .. current_note_id
  local note = find_or_create_note(log_note_id)
  if note == nil then
    vim.print("Note cannot be created")
    return nil
  end

  note:save({
    update_content = function(content)
      local task_id = "#task-" .. string.lower(info.task_id)
      local new_section = {}
      local new_task = false
      if note.anchor_links == nil or note.anchor_links[task_id] == nil then
        new_task = true
        new_section = {
          "",
          "# Task " .. info.task_id,
          "TASK: " .. info.title,
          "SOURCE: [[" .. current_note_id .. "]]",
          "LOG:",
        }
      end

      local line_num
      local log_index = 0
      if new_task then
        line_num = #note.contents
      else
        line_num, log_index = find_task_last_line(task_id, note.anchor_links)
      end

      vim.list_extend(new_section, {
        --"### Log record " .. (log_index + 1),
        --"LOG   : " .. info.log,
        --"ACTION: " .. info.action,
        "[[" .. os.date("%Y-%m-%d") .. "]] | " .. info.action .. " | " .. info.log,
      })
      local inject_position = line_num - note.frontmatter_end_line
      return utils.list_inject(content, new_section, inject_position + 1)
    end,
  })
end

M.log_pos = function(task)
  local current_note_id
  local d_note_id
  if d_note_id == nil then
    local current_note = client:current_note()
    if not current_note then
      vim.print("Current buf is not a note")
      return
    end
    current_note_id = current_note.id
  else
    current_note_id = d_note_id
  end

  local log_note_id = "log-" .. current_note_id
  local note = find_note(log_note_id)
  if note == nil then
    vim.print("No nodes found for this task")
    return nil
  end

  local task_id = "#task-" .. string.lower(task.task_id)
  if note.anchor_links == nil or note.anchor_links[task_id] == nil then
    vim.print("Can't find task logs in log file")
  end
  return find_task_last_line(task_id, note.anchor_links)
end

M.set_create_log({
  task_id = "1234-ABCE",
  title = "test",
  log = "log information",
  action = "log action",
}, "testlog")
return M
