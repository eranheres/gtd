
-- Import the TaskLine class
local export = require("gtd.export")

describe("Export", function()
  describe("Export", function()
    it("Exports tests", function()
      local opts = { cwd = "tests/data" }
      local lines = export.to_lines(opts)
    end)
  end)
  describe("Export", function()
    it("Exports tests", function()
      local opts = { cwd = "tests/data" }
      local buf = export.to_buffer(opts)
      export.save_buffer_as_pdf(buf, "output.pdf")
    end)
  end)
end)
