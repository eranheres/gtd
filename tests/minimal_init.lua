-- local function load_plugin(name, git, sub, config)
--   local dir = "/tmp/" .. name
--   local is_not_a_directory = vim.fn.isdirectory(dir) == 0
--   if is_not_a_directory then
--     vim.fn.system({ "git", "clone", git, dir })
--   end
--
--   vim.opt.rtp:append(".")
--   vim.opt.rtp:append(dir)
--
--   vim.cmd("runtime plugin/" .. name)
--   if config ~= nil then
--     require(sub).setup(config)
--   else
--     require(sub)
--   end
-- end
--
-- load_plugin("plenary.vim", "https://github.com/nvim-lua/plenary.nvim", "plenary.busted", nil)
-- load_plugin("obsidian.vim", "https://github.com/epwalsh/obsidian.nvim", "obsidian", {
--        workspaces = {
--          {
--            name = "personal",
--            path = "/tmp/",
--          }
--    }})
--
local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0
if is_not_a_directory then
  vim.fn.system({"git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir})
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

