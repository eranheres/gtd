local log = require("plenary.log"):new()

local task_line = require("gtd.taskline")
local utils = require("gtd.utils")
local gtd_obs = require("gtd.obsidian")

log.level = "info"

---@class CustomModule
local M = {}

---@return string
local function detect_date_in_string(str)
  local pattern = "%d%d%d%d%-%d%d%-%d%d"
  local match = string.match(str, pattern)
  return match
end

M.date_format = "YYYY-MM-DD"
local command = { "rg", "--json", "--maxdepth", "1", "debug", "." }
M.search_command = {
  -- rg --no-heading --color=never -zPU --json '(?m)^- \[ \] .*(\n[ \t]+.*)*'
  "rg",
  "--json",
  "--no-heading",
  -- "--maxdepth 1",
  "-z", -- Output null-separated results
  --"-P", -- Use Perl-compatible regex
  "^- \\[ |>|r\\].*",
  ".",
}

--- M.search_command = { "cat", "gtd.lua" }
local function safe_json_decode(json_string)
  local status, result = pcall(vim.json.decode, json_string)
  if status then
    return result
  else
    return nil -- or you can return an empty table or any other default value
  end
end

local rg_json_to_tasks = function(lines)
  return utils.map(lines, function(line)
    log.debug("Parsing line:", line)
    local parsed = safe_json_decode(line)
    if not parsed then
      log.debug("Failed to parse line:", line)
      return
    end
    --log.debug(parsed)
    if parsed and parsed.type == "match" and detect_date_in_string(parsed.data.lines.text) then
      local txt = parsed.data.lines.text
      log.debug("Parsed:", txt)
      local task = task_line.from_string(txt)
      if task_line.is_valid(task) then
        task.path = parsed.data.path.text
        task.line = parsed.data.line_number
        return task
      else
        log.debug("Failed to parse task:", txt)
        return
      end
    end
  end)
end

M.search_async = function(opts, callback)
  utils.execute_job(M.search_command, opts, function(code, signal, dump)
    local entries = vim.split(dump, "\n")
    local tasks = rg_json_to_tasks(entries)
    callback(tasks)
  end)
end

M.search_sync = function(opts, callback)
  local done = false
  local entries = {}
  M.search_async(opts, function(res)
    entries = res
    done = true
  end)
  -- Coroutine to wait for process to finish
  local co = coroutine.create(function()
    while not done do
      vim.wait(10)
    end
  end)
  coroutine.resume(co)

  return entries
end

-- M.search()

return M
