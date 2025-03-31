---
local log = require("plenary.log"):new()
log.level = "debug"
---


---@class Config
---@field opt string Your config option
---@field use_neotree boolean Use Neo-tree for task display (default: true)
---@field use_snacks boolean Use Snacks picker for task display (default: false)
local config = {
  use_neotree = false,
  use_snacks = true,
}
---
---@class MyModule
local M = {}

local setup_neotree = function()
  local neotree = require("neo-tree")
  if not neotree then
    log.error("Neotree not found - failed to setup gtd for neotree")
    return false
  end
  neotree.setup({
        sources = {
            "filesystem",
            "buffers",
            "git_status",
            -- "example",
            "tasktree"
        },
        example = {
            -- The config for your source goes here. This is the same as any other source, plus whatever
            -- special config options you add.
            --window = {...}
            --renderers = { ..}
            --etc
        },
        basic = {
            -- The config for your source goes here. This is the same as any other source, plus whatever
            -- special config options you add.
            -- window = {
            --   mappings = {
            --     ["<i>"] = "show_debug_info",
            --   },
            -- },
            --renderers = { ..}
            --etc
        },
      })
  return true
end

-- Function to show tasks using the configured method
M.show_tasks = function()
  if M.config.use_snacks then
    local picker = require("gtd.picker")
    picker.show_tasks()
  else
    -- Use Neo-tree
    vim.cmd("Neotree source=tasktree")
  end
end

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
  
  -- If Snacks is available and user wants to use it, enable it
  if has_snacks and args and args.use_snacks then
    M.config.use_snacks = true
    M.config.use_neotree = false
  end
  
  -- Setup Neo-tree if needed
  if M.config.use_neotree then
    local success = setup_neotree()
    if not success and has_snacks then
      -- Fallback to Snacks if Neo-tree setup fails
      log.info("Falling back to Snacks picker for GTD tasks")
      M.config.use_snacks = true
      M.config.use_neotree = false
    end
  end
end

return M
