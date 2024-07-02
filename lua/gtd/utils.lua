local log = require("plenary.log"):new()
log.level = "debug"

local M = {}

local enumerate = require("obsidian.itertools").enumerate

---Replace up to `n` occurrences of `what` in `s` with `with`.
---@param s string
---@param what string
---@param with string
---@param n integer|?
---@return string
---@return integer
local string_replace = function(s, what, with, n)
  local count = 0

  local function replace(s_)
    if n ~= nil and count >= n then
      return s_
    end

    local b_idx, e_idx = string.find(s_, what, 1, true)
    if b_idx == nil or e_idx == nil then
      return s_
    end

    count = count + 1
    return string.sub(s_, 1, b_idx - 1) .. with .. replace(string.sub(s_, e_idx + 1))
  end

  s = replace(s)
  return s, count
end

local escape_magic_characters = function(text)
  return text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local toggle_checkbox = function(opts, line_num)
  -- Allow line_num to be optional, defaulting to the current line if not provided
  line_num = line_num or unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  local checkbox_pattern = "^%s*- %[.] "
  local checkboxes = opts or { " ", "x" }

  if not string.match(line, checkbox_pattern) then
    local unordered_list_pattern = "^(%s*)[-*+] (.*)"
    if string.match(line, unordered_list_pattern) then
      line = string.gsub(line, unordered_list_pattern, "%1- [ ] %2")
    else
      line = string.gsub(line, "^(%s*)", "%1- [ ] ")
    end
  else
    for i, check_char in enumerate(checkboxes) do
      if string.match(line, "^%s*- %[" .. escape_magic_characters(check_char) .. "%].*") then
        if i == #checkboxes then
          i = 0
        end
        line = string_replace(line, "- [" .. check_char .. "]", "- [" .. checkboxes[i + 1] .. "]", 1)
        break
      end
    end
  end
  -- 0-indexed
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, true, { line })
end
local NuiPopup = require("nui.popup")
local NuiText = require("nui.text")

-- Function to create a floating window
local function create_floating_window(title, callback)
  -- Define the popup options
  local popup = NuiPopup({
    enter = true,
    focusable = true,
    border = {
      style = "double",
      text = {
        top = title,
        top_align = "center",
        bottom = " <Ctrl-Enter> to submit ",
        bottom_align = "center",
      },
    },
    position = "50%",
    size = {
      width = 40,
      height = 10,
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  })

  -- Function to handle input from the floating window
  local function handle_input()
    local lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
    popup:unmount()
    return lines
  end

  -- Map Ctrl-Enter to handle the input and close the window
  popup:map("n", "<C-CR>", function()
    callback(handle_input())
  end, { noremap = true, silent = true })

  popup:map("i", "<C-CR>", function()
    vim.cmd("stopinsert")
    callback(handle_input())
  end, { noremap = true, silent = true })

  -- Open the popup and enter insert mode
  popup:mount()
  vim.cmd("startinsert")
end

M.task_complete = function()
  create_floating_window("Completion details", function(lines)
    toggle_checkbox()
    local modified_lines = {}
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(modified_lines, "  " .. line)
      end
    end
    local date = os.date("%Y-%m-%d")
    table.insert(modified_lines, 1, "  ----------------------------")
    table.insert(modified_lines, 2, "  *COMPLETION NOTES [" .. date .. "]:*")
    table.insert(modified_lines, "  ----------------------------")

    local buf = vim.api.nvim_get_current_buf()
    local line_number = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(buf, line_number, line_number, false, modified_lines)
  end)
end

return M
