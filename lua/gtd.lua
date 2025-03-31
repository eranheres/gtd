---
local log = require("plenary.log"):new()
log.level = "debug"
---


---@class Config
---@field opt string Your config option
---@field use_snacks boolean Use Snacks picker for task display (default: true)
local config = {
  use_snacks = true,
}
---
---@class MyModule
local M = {}


-- Function to show tasks using Snacks picker
M.show_tasks = function()
  local picker = require("gtd.picker")
  picker.show_tasks()
end

-- Alias for show_tasks to make it more intuitive
M.tasks = M.show_tasks

---
---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  
  -- Check if Snacks is available
  local has_snacks = package.loaded["snacks"] ~= nil
  
  if not has_snacks then
    log.error("Snacks.nvim is not available. Please install it first.")
  end
end

return M
