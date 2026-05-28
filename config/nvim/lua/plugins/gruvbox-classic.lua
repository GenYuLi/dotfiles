-- Companion to plugins/gruvbox.lua (sainnhe's material variant). Installs the
-- "classic" ellisonleao/gruvbox.nvim with contrast="hard" — visually equivalent
-- to Jon Gjengset's `gruvbox-dark-hard` from wincent/base16-nvim: max saturation,
-- deep black #1d2021 background, original gruvbox palette.
--
-- Does NOT call vim.cmd.colorscheme — gruvbox-material wins startup. Switch on
-- demand with:
--     :colorscheme gruvbox          -- this plugin (Jon-style hard original)
--     :colorscheme gruvbox-material -- the soft default
--     :Telescope colorscheme        -- preview-and-pick UI
--
-- priority = 999 keeps it below gruvbox-material (1000) so the material variant
-- loads last and stays the active default after startup.

local M = {
  "ellisonleao/gruvbox.nvim",
  name = "gruvbox-classic",
  lazy = false,
  priority = 999,
}

function M.config()
  require("gruvbox").setup({
    contrast = "hard",
    terminal_colors = true,
    bold = true,
    italic = {
      strings = false,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    inverse = true,
    transparent_mode = false,
    dim_inactive = false,
    overrides = {
      -- Same back-compat shim as gruvbox-material — heirline.lua reads
      -- `@parameter` (deprecated in nvim 0.10+) for its `red` color.
      ["@parameter"] = { link = "@variable.parameter" },
    },
  })
  -- Intentionally NOT calling vim.cmd.colorscheme — gruvbox-material is default.
end

return M
