local log = require("plenary.log"):new()
log.level = "debug"

M = {}

M.update_fields = function(task_line, fields)
  -- vim merge tables
  return vim.tbl_extend("force", task_line, fields)
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
  task_line.again_num, task_line.again_period = str:match("|.*again:%+(%d+)(%a)")
  task_line.note = str:match("|.*note:%[%[(.-)%]%]")
  return task_line
end

-- Checks if the task is valid
M.is_valid = function(task_line)
  return task_line.status ~= nil and task_line.status ~= "" and task_line.text ~= nil and task_line.text ~= ""
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
