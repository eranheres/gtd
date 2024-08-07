local log = require("plenary.log"):new()
local utils = require("gtd.utils")
log.level = "debug"

M = {}

M.update_fields = function(task_line, fields)
  -- vim merge tables
  return vim.tbl_extend("force", task_line, fields)
end

local function parse_schedule(line)
  local str = line:match("|.*schedule:%[(.-)%]") or line:match("|.*#:%[(.-)%]")
  if str == nil then
    return nil
  end
  if str == "D" then
    return { period = "D", times = {} }
  end

  local period, times = str:match("([W|M|Y])%-(.*)")
  if period == nil or times == nil then
    return nil
  end
  return { period = period, times = vim.split(times, ",") }
end

-- Method to parse a string into fields
M.from_string = function(str)
  local task_line = {}
  task_line.status = str:match("^%- %[(.)%].*")
  task_line.priority = str:match("^%- %[.%] %(([A-D])%).*")
  task_line.text = str:match("^%- %[.%] %([A-D]%) (.*)|")
    or str:match("^%- %[.%] %([A-D]%) (.*)")
    or str:match("^%- %[.%] (.*)|")
    or str:match("^%- %[.%] (.*)")
  if task_line.text ~= nil then
    task_line.text = task_line.text:gsub("%s*$", "")
  end
  task_line.created_date = str:match("|.*created:%[(.-)%]")
  if task_line.created_date ~= nil then
    task_line.created_date = task_line.created_date:match("(%d%d%d%d%-%d%d%-%d%d).*")
  end
  task_line.due_date = str:match("|.*due:%[(.-)%]") or str:match("|.*~:%[(.-)%]")
  if task_line.due_date ~= nil then
    task_line.due_date = task_line.due_date:match("(%d%d%d%d%-%d%d%-%d%d).*")
  end
  task_line.assignee = str:match("|.*@%[(.-)%]")
  task_line.schedule = parse_schedule(str)
  task_line.log = str:match("|.*log:%[%[(.-)%]%]")
  task_line.task_id = str:match("|.*id:%[(.-)%]")
  if task_line.task_id == nil then
    task_line.task_id = utils.guid()
  end
  return task_line
end

-- Checks if the task is valid
M.is_valid = function(task_line)
  return task_line.status ~= nil
    and task_line.status ~= ""
    and task_line.text ~= nil
    and task_line.task_id ~= nil
end

local function all_values_in_range(values, from, to)
  for _, v in ipairs(values) do
    local num = tonumber(v)
    if not num then
      return false
    end
    if num < from or num > to then
      return false
    end
  end
  return true
end

M.is_schedule_valid = function(task)
  if
    M.is_valid(task) == false
    or task.schedule == nil
    or task.schedule.times == nil
    or task.schedule.period == nil
    or task.status ~= "r"
  then
    return false
  end

  if task.schedule.period == "W" and not all_values_in_range(task.schedule.times, 1, 7) then
    return false
  end
  if task.schedule.period == "M" and not all_values_in_range(task.schedule.times, 1, 31) then
    return false
  end
  if task.schedule.period == "Y" and not all_values_in_range(task.schedule.times, 1, 12) then
    for _, v in ipairs(task.schedule.times) do
      local date = vim.split(v, "/")
      if #date ~= 2 then
        return false
      end
      if not all_values_in_range({ date[1] }, 1, 12) or not all_values_in_range({ date[2] }, 1, 31) then
        return false
      end
    end
  end
  return true
end

M.is_field_valid = function(field)
  return field ~= nil and field ~= ""
end

-- Method to convert fields into a string
M.to_string = function(task_line)
  if not M.is_valid(task_line) then
    return ""
  end
  local str = "- [" .. task_line.status .. "]"
  if M.is_field_valid(task_line.priority) then
    str = str .. " (" .. task_line.priority .. ")"
  end
  str = str .. " " .. task_line.text

  if
    M.is_field_valid(task_line.due_date)
    or M.is_field_valid(task_line.task_id)
    or M.is_field_valid(task_line.created_date)
    or M.is_field_valid(task_line.assignee)
    or M.is_field_valid(task_line.again_num)
    or M.is_field_valid(task_line.schedule)
    or (task_line.schedule ~= nil and task_line.schedule.period ~= nil)
  then
    str = str .. " |"
  end

  -- if M.is_field_valid(task_line.created_date) then
  --   str = str .. " created:[" .. task_line.created_date .. "]"
  -- end

  if M.is_field_valid(task_line.due_date) then
    str = str .. " ~:[" .. task_line.due_date .. "]"
  end

  if M.is_field_valid(task_line.assignee) then
    str = str .. " @[" .. task_line.assignee .. "]"
  end

  if task_line.schedule ~= nil and task_line.schedule.period ~= nil then
    str = str .. " #:[" .. task_line.schedule.period
    if task_line.schedule.times ~= nil and #task_line.schedule.times ~= 0 then
      str = str .. "-" .. vim.fn.join(task_line.schedule.times, ",")
    end
    str = str .. "]"
  end

  if M.is_field_valid(task_line.task_id) then
    str = str .. " id:[" .. task_line.task_id.. "]"
  end

  return str
end

M.next_due_date = function(task, cur_time)
  local current_time = cur_time or os.time()
  --vim.print(os.date("%Y-%m-%d", current_time), "\n")
  local times = {}
  if task.schedule.period == "D" then
    return os.date("%Y-%m-%d", utils.get_following_day_time(current_time))
  end
  if task.schedule.period == "W" then
    times = utils.map(task.schedule.times, function(v)
      return utils.get_following_weekday_time(current_time, tonumber(v))
    end)
  end
  if task.schedule.period == "M" then
    times = utils.map(task.schedule.times, function(v)
      return utils.get_following_month_time(current_time, tonumber(v))
    end)
  end
  if task.schedule.period == "Y" then
    times = utils.map(task.schedule.times, function(v)
      return utils.get_following_year_time(current_time, v)
    end)
  end
  local min_time = utils.min(times)
  return os.date("%Y-%m-%d", min_time)
end

return M
