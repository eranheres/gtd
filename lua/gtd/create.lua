local log = require("plenary.log"):new()
log.level = "debug"

---@class CustomModule
local M = {}

local client = require("obsidian").get_client()
local util = require("obsidian.util")
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
    line = 5
	})
	-- vim.api.nvim_command("normal! Go")
end
return M
