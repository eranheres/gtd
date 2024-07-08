local log = require("plenary.log"):new()
log.level = "debug"

local M = {}

-- General helpers
M.guid = function()
    local template ='xxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- list helpers
M.map = function(list, f)
  local new_list = {}
  for i, v in ipairs(list) do
    new_list[i] = f(v)
  end
  return new_list
end

M.min = function (list)
  local min = list[1]
  for _, v in ipairs(list) do
    if v < min then
      min = v
    end
  end
  return min
end

M.list_inject = function(dest, source, pos)
  local first = vim.list_slice(dest, 0, pos-1)
  local last  = vim.list_slice(dest, pos)
  local target = {}
  target = vim.list_extend(target, first)
  target = vim.list_extend(target, source)
  target = vim.list_extend(target, last)
  return target
end

-- Date related helpers
M.get_following_day_time = function(time)
  local days_to_add = 1
  local next_day = time + (days_to_add * 24 * 60 * 60)
  -- vim.print("Following day:",os.date("%Y-%m-%d", next_day), "\n")
  return next_day
end

M.get_following_weekday_time = function(time, weekday)
  local ntime = time
  repeat
    --vim.print("Looking for :",weekday, " currently on ", os.date("*t", ntime).wday, "\n")
    ntime = M.get_following_day_time(ntime)
  until os.date("*t", ntime).wday == weekday
  return ntime
end

M.get_following_month_time = function(time, monthday)
  local current_date = os.date("*t", time)
  local year = current_date.year
  local month = current_date.month
  if current_date.day > monthday then
    month = month + 1
    if current_date.month > 12 then
      year = year + 1
      month = 1
    end
  end
  return os.time({ year = year, month = month, day = monthday })
end

M.get_following_year_time = function(time, monthandday)
  local split = vim.split(monthandday, "/")
  local month = tonumber(split[1])
  local day = tonumber(split[2])
  if month == nil or day == nil then
    return 0
  end
  local current_date = os.date("*t", time)
  local year = current_date.year
  if current_date.month > month then
    year = year + 1
  elseif current_date.month == month and current_date.day > day then
    year = year + 1
  end
  return os.time({ year = year, month = month, day = day })
end



return M
