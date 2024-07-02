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
    line = 5
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
    line = 5
	})
	-- vim.api.nvim_command("normal! Go")
end

local task_lines = function(ops)
	return {
		"---",
		"  - [ ] " .. ops["task"],
		"    DUE DATE: [[" .. ops["due"] .. "]]",
		"    CREATED: [[" .. Date.today():to_string() .. "]]",
	}
end

local insert_lines_at_cursor = function(lines)
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_nr = cursor[1]
	vim.api.nvim_buf_set_lines(bufnr, line_nr, line_nr, false, lines)
end

M.new_task = function()
	local note_name = util.input("󱞁 Task description")
	if not note_name or note_name == "" then
		return
	end
	Calendar.new({ Date.today(), title = "Due date" }):open():next(function(new_date)
		if not new_date then
			log.debug("New date is null")
		end
		log.debug("New date:", new_date:to_string())
		local lines = task_lines({ task = note_name, due = new_date:to_string() })
		insert_lines_at_cursor(lines)
		return nil
	end)
end


return M
