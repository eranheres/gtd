local log = require("plenary.log"):new()
log.level = "debug"

M = {}

M.update_fields = function(task_line, fields)
  -- vim merge tables
  return vim.tbl_extend("force", task_line, fields)
end

local function parse_schedule(line)
  local str = line:match("|.*schedule:%[(.-)%]")
  if str == "D" then
    return { period = "D", times = {} }
  end
  local period, times = line:match("([W|M|Y])%-(.*)")
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
  task_line.due_date = str:match("|.*due:%[(.-)%]")
  task_line.assignee = str:match("|.*@%[(.-)%]")
  task_line.followup_date = str:match("|.*~:%[(.-)%]")
  task_line.schedule = parse_schedule(str)
  task_line.note = str:match("|.*note:%[%[(.-)%]%]")
  return task_line
end

-- Checks if the task is valid
M.is_valid = function(task_line)
  return task_line.status ~= nil and task_line.status ~= "" and task_line.text ~= nil and task_line.text ~= ""
end

local generate_list = function(from_val, to_val)
  local list = {}
  for i = from_val, to_val do
    table.insert(list, "" .. i)
  end
  return list
end

local function all_values_in_list(values, list)
  for _, v in ipairs(values) do
    if not vim.tbl_contains(list, v) then
      return false
    end
  end
  return true
end

M.is_schedule_valid = function(task_line)
  if
    task_line.schedule == nil
    or task_line.schedule.times == nil
    or task_line.schedule.period == nil
    or task_line.status ~= "r"
  then
    return false
  end

  local weekdays = generate_list(1, 7)
  local monthdays = generate_list(1, 31)
  local yearmonths = generate_list(1, 12)
  if task_line.schedule.period == "W" and not all_values_in_list(task_line.schedule.times, weekdays) then
    return false
  end
  if task_line.schedule.period == "M" and not all_values_in_list(task_line.schedule.times, monthdays) then
    return false
  end
  if task_line.schedule.period == "Y" and not all_values_in_list(task_line.schedule.times, monthdays) then
    for _, v in ipairs(task_line.schedule.times) do
      local date = vim.split(v, "/")
      if #date ~= 2 then
        return false
      end
      if not all_values_in_list({date[1]}, yearmonths) or not all_values_in_list({date[2]}, monthdays) then
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
  local str = "- [" .. task_line.status .. "]"
  if M.is_field_valid(task_line.priority) then
    str = str .. " (" .. task_line.priority .. ")"
  end
  str = str .. " " .. task_line.text

  if
    M.is_field_valid(task_line.due_date)
    or M.is_field_valid(task_line.created_date)
    or M.is_field_valid(task_line.assignee)
    or M.is_field_valid(task_line.followup_date)
    or M.is_field_valid(task_line.again_num)
    or M.is_field_valid(task_line.note)
  then
    str = str .. " |"
  end

  if M.is_field_valid(task_line.created_date) then
    str = str .. " created:[" .. task_line.created_date .. "]"
  end

  if M.is_field_valid(task_line.due_date) then
    str = str .. " due:[" .. task_line.due_date .. "]"
  end

  if M.is_field_valid(task_line.assignee) then
    str = str .. " @[" .. task_line.assignee .. "]"
  end

  if M.is_field_valid(task_line.followup_date) then
    str = str .. " ~:[" .. task_line.followup_date .. "]"
  end

  if M.is_field_valid(task_line.again_num) then
    str = str .. " again:+" .. task_line.again_num .. task_line.again_period
  end

  if M.is_field_valid(task_line.note) then
    str = str .. " note:[[" .. task_line.note .. "]]"
  end

  return str
end

return M
