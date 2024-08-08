local log = require("plenary.log"):new()
local client = require("obsidian").get_client()
local Note = require("obsidian").Note

log.level = "info"

---@class Obsidian
local M = {}

-- 
M.get_project_icon = function(path)
  local note = Note.from_file(path)
  if not note then
    vim.print("Current buf is not a note")
    return
  end
	local frontmatter = note:frontmatter()
  local icon = frontmatter.project_icon
  return icon
end

M.get_project_name = function(path)
  local note = Note.from_file(path)
  if not note then
    vim.print("Current buf is not a note")
    return
  end
	local frontmatter = note:frontmatter()
  local icon = frontmatter.project
  return icon
end

return M
