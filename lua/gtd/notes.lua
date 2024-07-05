local log = require("plenary.log"):new()
log.level = "debug"

local Calendar = require("orgmode.objects.calendar")
local Date = require("orgmode.objects.date")
local util = require("obsidian.util")
local client = require("obsidian").get_client()

---@class CustomModule
local M = {}

M.fly_task = function()
  local note_name = util.input("A new task name")
  if not note_name or note_name == "" then
    return
  end
  local note = client:create_note({
    title = note_name,
    id = note_name,
    template = "Fly Task Template",
  })
  client:open_note(note, {
    sync = true,
    line = 5,
  })
  -- vim.api.nvim_command("normal! Go")
end

M.meeting_note = function()
  local date = os.date("%Y-%m-%d")
  local note_name = util.input("Meeting name") .. " - " .. date
  if not note_name or note_name == "" then
    return
  end
  local note = client:create_note({
    title = note_name,
    id = note_name,
    template = "Meeting Template",
  })
  client:open_note(note, {
    sync = true,
    line = 5,
  })
  -- vim.api.nvim_command("normal! Go")
end

M.project_note = function()
  local note_name = util.input("Project name")
  if not note_name or note_name == "" then
    return
  end
  local note = client:create_note({
    title = note_name,
    id = note_name,
    template = "Project Template",
  })
  client:open_note(note, {
    sync = true,
    line = 5,
  })
end

return M
