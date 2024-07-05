local log = require("plenary.log"):new()
log.level = "debug"

local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local Calendar = require("orgmode.objects.calendar")
local Date = require("orgmode.objects.date")
require("gtd.taskline")

local log = require("plenary.log"):new()
log.level = "debug"

---@class CustomModule
local M = {}

M.input_prompt = function(title, field, callback, opts)
  local input = Input({
    position = "50%",
    size = { width = "85%" },
    border = {
      style = "double",
      text = { top = "[ " .. title .. " ]", top_align = "center" },
    },
    win_options = { winhighlight = "Normal:Normal,FloatBorder:Normal" },
  }, {
    prompt = "> ",
    default_value = "",
    on_close = function()
      callback()
    end,
    on_submit = function(value)
      opts[field] = value
      callback()
    end,
  })

  -- mount/open the component
  input:mount()
  -- unmount input by pressing `<Esc>` in normal mode
  input:map("n", "<Esc>", function()
    input:unmount()
  end, { noremap = true })
  -- unmount component when cursor leaves buffer
  input:on(event.BufLeave, function()
    input:unmount()
  end)
end
M.input_prompt("test", "test", function() end, {})

M.date_picker = function(title, field_name, callback, opts)
  Calendar.new({
    Date.today(),
    border = "double",
    title = "[ " .. title .. " ]",
  })
    :open()
    :next(function(new_date)
      opts[field_name] = new_date:to_string()
      callback()
      return nil
    end)
end

M.options_picker = function(title, field_name, options, callback, opts)
  local menu = Menu({
    position = "50%",
    size = {
      width = 20,
      height = 5,
    },
    border = {
      style = "double",
      text = {
        top = "[ " .. title .. " ]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = options,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      callback()
    end,
    on_submit = function(item)
      opts[field_name] = item.value
      callback()
    end,
  })

  -- mount the component
  menu:mount()
end

return M
