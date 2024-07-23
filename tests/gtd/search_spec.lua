-- Import the TaskLine class
local task_line = require("gtd.taskline")
local search = require("gtd.search")

local function tstr(str)
  local year, month, day = str:match("(%d+)-(%d+)-(%d+)")
  return os.time({ year = year, month = month, day = day })
end

local function is_task_exists(tasks, str)
  for k, v in pairs(tasks) do
    if v.text == str then
      return true
    end
  end
  return false
end

describe("Search", function()
  describe("Search", function()
    it("Search sync tests", function()
      local opts = { cwd = "tests/data" }
      local results = search.search_sync(opts)
      assert.is_true(is_task_exists(results, "This is a valid open task"))
      assert.is_false(is_task_exists(results, "This is a valid closed task"))
      assert.is_false(is_task_exists(results, "This is an invalid task 1"))
    end)
  end)
end)
