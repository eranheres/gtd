-- This file contains the built-in components. Each componment is a function
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

local gtd_obs = require("gtd.obsidian")

local M = {}

M.custom = function(config, node, state)
  local text = node.extra.custom_text or "DDD"
  local highlight = highlights.DIM_TEXT
  return {
    text = text .. " ",
    highlight = highlight,
  }
end

M.icon = function(config, node, state)
  local icon = config.default or " "
  local padding = config.padding or " "
  local highlight = config.highlight or highlights.FILE_ICON

  if node.type == "directory" then
    highlight = highlights.DIRECTORY_ICON
    if node:is_expanded() then
      icon = config.folder_open or "-"
    else
      icon = config.folder_closed or "+"
    end
  elseif node.type == "file" then
    if node.extra.task.status == "r" then
      icon = "🔁"
    else
      local icon_map = {
        A = "⏫",
        B = "🔼",
        C = "🔽",
        D = "⏬",
      }
      icon = icon_map[node.extra.task.priority] or icon
    end
    local project_icon = gtd_obs.get_project_icon(node.path)
    if project_icon and icon then
      icon = project_icon .. " " .. icon
    else
      icon = "   " .. icon
    end
  end

  return {
    text = icon .. padding,
    highlight = highlight,
  }
end

-- M.name = function(config, node, state)
--   local highlight = config.highlight or highlights.FILE_NAME
--   if node.type == "directory" then
--     highlight = highlights.DIRECTORY_NAME
--   end
--   if node:get_depth() == 1 then
--     highlight = highlights.ROOT_NAME
--   end
--   return {
--     text = "date"..node.name,
--     highlight = highlight,
--   }
-- end

return vim.tbl_deep_extend("force", common, M)
