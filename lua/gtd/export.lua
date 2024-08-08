local search = require("gtd.search")
local gtd_obs = require("gtd.obsidian")

local M = {}

M.to_lines = function(opts)
  local results = search.search_sync(opts)
  local time = os.time()
  local date_str = os.date("%Y-%m-%d", time)
  local lines = {
    "# Tasks for " .. date_str,
    "",
  }
  local project_name
  for i, task in pairs(results) do
    if task.due_date and task.due_date <= date_str then
      local project = gtd_obs.get_project_name(task.path)
      if project ~= project_name then
        project_name = project
        table.insert(lines, "")
        table.insert(lines, "## " .. project_name)
      end
      local line = "- [ ] " .. task.text
      table.insert(lines, line)
    end
  end
  return lines
end

M.to_buffer = function(opts)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set the new buffer as the current buffer
  vim.api.nvim_set_current_buf(buf)

  local lines = M.to_lines(opts)
  -- Set the lines in the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  return buf
end
--
-- Function to save current buffer as a PDF
M.save_buffer_as_pdf = function(buf, pdf_path)
  -- Get the current buffer number
  --local buf = vim.api.nvim_get_current_buf()

  -- Get the lines of the buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Create a temporary file to save the buffer content
  local temp_filename = vim.fn.tempname() .. ".md"
  local temp_file = io.open(temp_filename, "w")

  -- Write the buffer content to the temporary file
  for _, line in ipairs(lines) do
    temp_file:write(line .. "\n")
  end
  temp_file:close()

  -- Command to convert the temporary file to a PDF
  local cmd = string.format('pandoc %s -o "%s"', temp_filename, pdf_path)

  -- Execute the command
  os.execute(cmd)

  -- Optionally, remove the temporary file
  os.remove(temp_filename)

  print("Buffer saved as PDF: " .. pdf_path)
end

M.to_pdf = function(pdf_path, opts)
  local buf = M.to_buffer(opts)
  M.save_buffer_as_pdf(buf, pdf_path)
end

return M
