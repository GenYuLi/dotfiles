local M = {
  "akinsho/bufferline.nvim",
  event = "LazyFile",
}

function M.config()
  require("bufferline").setup {
    options = {
      mode = "tabs",
      numbers = "none",
      show_close_icon = false,
      separator_style = "slant",
      always_show_bufferline = false,
      hover = {
        enabled = true,
        delay = 100,
        reveal = { "close" },
      },
    },
    -- Disabled for gruvbox trial. Re-enable to revert. See plugins/gruvbox.lua.
    -- highlights = require("catppuccin.special.bufferline").get_theme(),
  }
end

return M
