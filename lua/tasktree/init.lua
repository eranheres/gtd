local vim = vim
local renderer = require("neo-tree.ui.renderer")

local search = require("gtd.search")
local gtd_utils = require("gtd.utils")

local M = {
  name = "basic",
  display_name = "Basic",
}
local get_debug_items = function()
  return {
    {
      id = "1",
      name = "root",
      type = "directory",
      children = {
        {
          id = "1.1",
          name = "child1",
          path = "test",
          extra = { data = "sdfsd" },
          type = "directory",
          children = {
            {
              id = "1.1.1",
              path = "test",
              extra = { data = "sdfsd" },
              name = "child1.1 (you'll need a custom renderer to display this properly)",
              type = "file",
            },
          },
          --   {
          --     id = "1.1.2",
          --     name = "child1.2",
          --     type = "file",
          --     stat_provider = "example-custom",
          --   },
          -- },
        },
      },
    },
  }
end

local get_items = function()
  local all = {}
  local all_results = search.search_sync()
  local time = os.time()
  for i = 1, 10 do
    local node_id = "1." .. i
    local date_str = os.date("%Y-%m-%d", time)
    local date_node = {
      id = node_id,
      name = os.date("%A, %Y-%m-%d", time),
      type = "directory",
      --type = "custom",
      --stat_provider = "tasktree-custom",
      children = {},
    }
    local count = 0
    for j, task in pairs(all_results) do
      if task.due_date and (task.due_date == date_str or (count == 0 and task.due_date < date_str)) then
        -- log.info(task.due_date)
        count = count + 1
        local item = {
          id = node_id .. "." .. count,
          name = task.text,
          type = "file",
          path = task.path,
          extra = {
            position = { task.line - 1, 0 },
            task = task,
          },
        }
        table.insert(date_node.children, item)
      end
    end
    date_node.name = date_node.name .. " (" .. #date_node.children .. ")"
    table.insert(all, date_node)
    time = gtd_utils.get_following_day_time(time)
  end
  --log.info(all)

  return {
    {
      id = "1",
      name = "root",
      type = "directory",
      --stat_provider = "tasktree-custom",
      children = all,
    },
  }
end
---Navigate to the given path.
---@param path string Path to navigate to. If empty, will navigate to the cwd.
M.navigate = function(state, path)
  if path == nil then
    path = vim.fn.getcwd()
  end
  state.path = path

  -- Do something useful here to get items
  local items = get_items()
  --local items = get_debug_items()
  renderer.show_nodes(items, state)
end

---Configures the plugin, should be called before the plugin is used.
---@param config table Configuration table containing any keys that the user
--wants to change from the defaults. May be empty to accept default values.
M.setup = function(config, global_config) end

return M
