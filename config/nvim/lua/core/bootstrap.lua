local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.notify("Installing package manager...")
  vim.fn.system { "git", "clone", "--single-branch", "https://github.com/folke/lazy.nvim.git", lazypath }
  local f = io.open(vim.fn.stdpath("config") .. "/lazy-lock.json", "r")
  if f then
    local data = f:read("*a")
    local lock = vim.json.decode(data)
    vim.fn.system { "git", "-C", lazypath, "checkout", lock["lazy.nvim"].commit }
    f:close()
  end
end
vim.opt.runtimepath:prepend(lazypath)

require("core.utils").lazy_file()

require("lazy").setup("plugins", {
  install = {
    colorscheme = { "catppuccin", "habamax" },
  },
  ui = {
    border = "rounded",
    icons = {
      list = { "", "", "", "" },
    },
  },
  diff = {
    cmd = "terminal_git",
  },
  change_detection = {
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "matchit",
        "matchparen",
        "netrwPlugin",
      },
    },
  },
  dev = {
    path = "~/git",
  },
})
