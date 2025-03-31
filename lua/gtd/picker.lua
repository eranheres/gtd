local search = require("gtd.search")
local gtd_utils = require("gtd.utils")
local tasks = require("gtd.tasks")
local tasklog = require("gtd.logs")
local task_line = require("gtd.taskline")
local gtd_obs = require("gtd.obsidian")

local M = {}

-- Function to get all tasks and organize them by date
local function get_tasks_by_date()
  local all_results = search.search_sync()
  local time = os.time()
  local organized_tasks = {}
  local non_repeat_count = 0
  
  -- Create date categories (similar to your tasktree implementation)
  for i = 1, 10 do
    local date_str = os.date("%Y-%m-%d", time)
    local name = os.date("%A, %Y-%m-%d", time)
    if i == 10 then
      name = "Backlog"
    end
    
    local date_tasks = {}
    
    -- Assign tasks to appropriate date categories
    for _, task in pairs(all_results) do
      if (task.due_date and (task.due_date == date_str or (i == 1 and task.due_date < date_str)))
         or (i == 10 and (task.due_date and task.due_date >= date_str)) then
        
        if task.status ~= "r" then
          non_repeat_count = non_repeat_count + 1
        end
        
        -- Add task to this date category
        table.insert(date_tasks, {
          text = task.text,
          path = task.path,
          line = task.line - 1,
          task = task,
          date_category = name,
          date_str = date_str
        })
      end
    end
    
    -- Add this date category to organized tasks
    organized_tasks[name] = {
      tasks = date_tasks,
      count = #date_tasks,
      date_str = date_str
    }
    
    -- Move to next day
    time = gtd_utils.get_following_day_time(time)
  end
  
  return organized_tasks, non_repeat_count
end

-- Format tasks for Snacks explorer-like picker
local function format_tasks_for_picker(organized_tasks)
  local items = {}
  local date_names = {}
  
  -- Collect date names to ensure consistent ordering
  for date_name, _ in pairs(organized_tasks) do
    table.insert(date_names, date_name)
  end
  
  -- Sort date names (keeping "Backlog" at the end)
  table.sort(date_names, function(a, b)
    if a == "Backlog" then return false end
    if b == "Backlog" then return true end
    return a < b
  end)
  
  for _, date_name in ipairs(date_names) do
    local date_data = organized_tasks[date_name]
    
    -- Add a header item for the date (folder-like)
    table.insert(items, {
      text = date_name .. " (" .. date_data.count .. ")",
      kind = "folder",
      date_str = date_data.date_str,
      is_folder = true,
      is_open = true, -- Folders start open by default
      children = date_data.tasks
    })
    
    -- Add all tasks for this date as children
    if date_data.count > 0 then
      for _, task in ipairs(date_data.tasks) do
        local priority_icons = {
          A = "⏫",
          B = "🔼",
          C = "🔽",
          D = "⏬"
        }
        
        local icon = task.task.status == "r" and "🔁" or (priority_icons[task.task.priority] or "")
        local project_name = gtd_obs.get_project_name(task.path) or ""
        local project_icon = gtd_obs.get_project_icon(task.path) or ""
        
        table.insert(items, {
          text = task.text,
          path = task.path,
          line = task.line,
          task = task.task,
          kind = "task",
          icon = icon,
          project_name = project_name,
          project_icon = project_icon,
          date_category = date_name,
          parent_folder = date_name
        })
      end
    end
  end
  
  return items
end

-- Open the tasks in Snacks picker with explorer-like interface
M.show_tasks = function()
  -- Check if Snacks is available
  if not package.loaded["snacks"] then
    vim.notify("Snacks.nvim is not available. Please install it first.", vim.log.levels.ERROR)
    return
  end
  
  local Snacks = require("snacks")
  local organized_tasks, non_repeat_count = get_tasks_by_date()
  local items = format_tasks_for_picker(organized_tasks)
  
  -- Define custom format function for tasks
  local format = function(item, picker)
    local highlights = {}
    
    if item.is_folder then
      -- Format for date folders
      local folder_icon = item.is_open and "󰝰 " or "󰉋 "
      table.insert(highlights, {folder_icon .. item.text, "NeoTreeDirectoryName"})
    else
      -- Format for tasks
      local indent = "    "
      local icon = item.icon and (item.icon .. " ") or ""
      local project = ""
      if item.project_icon and item.project_icon ~= "" then
        project = item.project_icon .. " "
      elseif item.project_name and item.project_name ~= "" then
        project = "[" .. item.project_name .. "] "
      end
      
      table.insert(highlights, {indent .. icon .. project .. item.text, "NeoTreeFileName"})
    end
    
    return highlights
  end
  
  -- Define preview function
  local preview = function(ctx)
    if not ctx.item or ctx.item.is_folder then
      return false
    end
    
    local task = ctx.item.task
    local content = {}
    
    table.insert(content, "# Task Details")
    table.insert(content, "")
    table.insert(content, "**Text**: " .. task.text)
    table.insert(content, "**Status**: " .. (task.status == " " and "Open" or 
                                            (task.status == "x" and "Completed" or 
                                             (task.status == "r" and "Recurring" or task.status))))
    table.insert(content, "**Priority**: " .. (task.priority or "None"))
    table.insert(content, "**Due Date**: " .. (task.due_date or "None"))
    table.insert(content, "**Created Date**: " .. (task.created_date or "None"))
    
    if task.schedule then
      local schedule_info = "**Schedule**: " .. task.schedule.period
      if task.schedule.times and #task.schedule.times > 0 then
        schedule_info = schedule_info .. " (" .. table.concat(task.schedule.times, ", ") .. ")"
      end
      table.insert(content, schedule_info)
    end
    
    if task.assignee then
      table.insert(content, "**Assignee**: " .. task.assignee)
    end
    
    -- Add file path info
    table.insert(content, "")
    table.insert(content, "**File**: " .. ctx.item.path)
    table.insert(content, "**Line**: " .. (ctx.item.line + 1))
    
    if ctx.item.project_name and ctx.item.project_name ~= "" then
      table.insert(content, "**Project**: " .. ctx.item.project_name)
    end
    
    -- Try to show file preview with the task highlighted
    if vim.fn.filereadable(ctx.item.path) == 1 then
      table.insert(content, "")
      table.insert(content, "## File Preview")
      table.insert(content, "```markdown")
      
      local file_lines = vim.fn.readfile(ctx.item.path)
      local start_line = math.max(1, ctx.item.line - 2)
      local end_line = math.min(#file_lines, ctx.item.line + 3)
      
      for i = start_line, end_line do
        if i == ctx.item.line + 1 then
          table.insert(content, file_lines[i] .. " <-- CURRENT TASK")
        else
          table.insert(content, file_lines[i])
        end
      end
      
      table.insert(content, "```")
    end
    
    ctx.preview.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(ctx.preview.buf, 0, -1, false, content)
    vim.api.nvim_buf_set_option(ctx.preview.buf, "filetype", "markdown")
    
    return true
  end
  
  -- Define actions for tasks
  local actions = {
    toggle_folder = function(picker, item)
      if not item or not item.is_folder then return end
      
      item.is_open = not item.is_open
      picker:refresh()
    end,
    
    complete_task = function(picker, item)
      if not item or item.is_folder then return end
      
      -- Navigate to the file and line
      vim.cmd("edit " .. item.path)
      vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
      
      -- Complete the task
      tasks.complete_task()
      
      -- Close picker and reopen to refresh
      picker:close()
      M.show_tasks()
    end,
    
    set_due_date = function(picker, item)
      if not item or item.is_folder then return end
      
      -- Navigate to the file and line
      vim.cmd("edit " .. item.path)
      vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
      
      -- Set due date
      tasks.set_due_date()
      
      -- Close picker and reopen to refresh
      picker:close()
      M.show_tasks()
    end,
    
    set_priority = function(picker, item)
      if not item or item.is_folder then return end
      
      -- Navigate to the file and line
      vim.cmd("edit " .. item.path)
      vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
      
      -- Set priority
      tasks.set_priority()
      
      -- Close picker and reopen to refresh
      picker:close()
      M.show_tasks()
    end,
    
    edit_task = function(picker, item)
      if not item then return end
      
      if item.is_folder then
        -- Toggle folder open/closed
        item.is_open = not item.is_open
        picker:refresh()
      else
        -- Navigate to the file and line
        vim.cmd("edit " .. item.path)
        vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
        
        -- Close picker
        picker:close()
      end
    end,
    
    new_task = function(picker)
      picker:close()
      tasks.new_task()
    end,
    
    new_quick_task = function(picker)
      picker:close()
      tasks.new_quick_task()
    end,
    
    push_to_backlog = function(picker, item)
      if not item or item.is_folder then return end
      
      -- Navigate to the file and line
      vim.cmd("edit " .. item.path)
      vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
      
      -- Push to backlog
      tasks.push_to_backlog()
      
      -- Close picker and reopen to refresh
      picker:close()
      M.show_tasks()
    end,
    
    add_log = function(picker, item)
      if not item or item.is_folder then return end
      
      -- Navigate to the file and line
      vim.cmd("edit " .. item.path)
      vim.api.nvim_win_set_cursor(0, {item.line + 1, 0})
      
      -- Add log
      tasks.add_log()
      
      -- Close picker and reopen to refresh
      picker:close()
      M.show_tasks()
    end
  }
  
  -- Configure and show the Snacks picker with explorer-like interface
  Snacks.picker({
    items = items,
    title = "GTD Tasks (" .. non_repeat_count .. ")",
    format = format,
    preview = preview,
    actions = actions,
    layout = { preset = "sidebar", preview = "main" }, -- Use sidebar layout for explorer-like feel
    focus = "list", -- Focus the list by default
    win = {
      input = {
        keys = {
          ["<CR>"] = "edit_task",
          ["<c-n>"] = "new_task",
          ["<c-q>"] = "new_quick_task",
          ["<c-c>"] = "complete_task",
          ["<c-d>"] = "set_due_date",
          ["<c-p>"] = "set_priority",
          ["<c-b>"] = "push_to_backlog",
          ["<c-l>"] = "add_log",
        }
      },
      list = {
        keys = {
          ["<CR>"] = "edit_task",
          ["<Space>"] = "toggle_folder",
          ["c"] = "complete_task",
          ["d"] = "set_due_date",
          ["p"] = "set_priority",
          ["n"] = "new_task",
          ["q"] = "new_quick_task",
          ["b"] = "push_to_backlog",
          ["l"] = "add_log",
        }
      }
    }
  })
end

return M
