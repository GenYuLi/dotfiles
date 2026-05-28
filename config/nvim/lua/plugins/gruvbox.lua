-- One-week trial. To revert:
--   1. uncomment `vim.cmd.colorscheme("catppuccin")` in plugins/catppuccin.lua
--   2. uncomment the bufferline catppuccin highlights line in plugins/bufferline.lua
--   3. revert lazy install colorscheme list in core/bootstrap.lua
--   4. delete this file
--
-- gruvbox.nvim with contrast="hard" felt too harsh on markdown heading bg-fills,
-- contrast="medium" felt too washed out. gruvbox-material is sainnhe's softer
-- repaint of the gruvbox palette — desaturates yellow/green/orange and uses
-- a "material" foreground variant that's easier on long sessions. Different
-- plugin, different config API (vim.g.* globals instead of lua setup()).

local M = {
  "sainnhe/gruvbox-material",
  name = "gruvbox-material",
  priority = 1000,
  lazy = false,
}

function M.config()
  -- "hard" (#1d2021) for Jon-like deep black, paired with material foreground
  -- (softer palette) so it doesn't read as harsh as the original gruvbox hard.
  -- Switch to "medium" (#282828) or "soft" (#32302f) if too dark.
  vim.g.gruvbox_material_background = "hard"

  -- "material" softens fg colors (the namesake). Alternatives: "mix", "original".
  vim.g.gruvbox_material_foreground = "material"

  vim.g.gruvbox_material_better_performance = 1

  -- enable_italic = 1 italicises types/namespaces/keywords/modules — too noisy
  -- vs Catppuccin's upright-by-default look. Keep at 0 so only comments italic.
  vim.g.gruvbox_material_enable_italic = 0

  vim.o.background = "dark"
  vim.cmd.colorscheme("gruvbox-material")

  -- Highlight overrides applied on top of gruvbox-material defaults.
  --   * `@parameter` — back-compat shim for heirline.lua, which reads this
  --     deprecated (pre-nvim-0.10) group for its `red` color.
  --   * `@variable.member` — color struct fields explicitly. Gruvbox defaults
  --     blend them into the foreground; this picks them out in blue (mirrors
  --     the Catppuccin habit of lavender struct fields, mapped to a blue tone
  --     that fits the gruvbox-material material palette).
  local function apply_highlights()
    vim.api.nvim_set_hl(0, "@parameter", { link = "@variable.parameter" })
    vim.api.nvim_set_hl(0, "@variable.member", { fg = "#7daea3" })
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "gruvbox-material",
    callback = apply_highlights,
  })
  apply_highlights()

  -- :GruvboxBg <hard|medium|soft> — switch background variant live.
  -- sainnhe's plugin reads g:gruvbox_material_background only when the
  -- colorscheme is sourced, so we set the var then re-apply.
  vim.api.nvim_create_user_command("GruvboxBg", function(opts)
    local valid = { hard = true, medium = true, soft = true }
    if not valid[opts.args] then
      vim.notify(
        "GruvboxBg: invalid value '" .. opts.args .. "'. Use hard, medium, or soft.",
        vim.log.levels.ERROR
      )
      return
    end
    vim.g.gruvbox_material_background = opts.args
    vim.cmd.colorscheme("gruvbox-material")
  end, {
    nargs = 1,
    complete = function() return { "hard", "medium", "soft" } end,
    desc = "Switch gruvbox-material background (hard/medium/soft)",
  })
end

return M
