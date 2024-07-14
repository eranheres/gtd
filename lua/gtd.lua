---
local log = require("plenary.log"):new()
log.level = "debug"
---


---@class Config
---@field opt string Your config option
local config = {
}
---
---@class MyModule
local M = {}

local setup_neotree = function()
  local neotree = require("neo-tree")
  if not neotree then
    log.error("Neotree not found - failed to setup gtd for neotree")
  end
  neotree.setup({
        sources = {
            "filesystem",
            "buffers",
            "git_status",
            "example",
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
end


---
---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  setup_neotree()
end

return M
