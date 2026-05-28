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
  -- gruvbox-material material palette (hex):
  --   red    #ea6962   yellow #d8a657   blue   #7daea3   green #a9b665
  --   orange #e78a4e   purple #d3869b   aqua   #89b482
  --
  -- Defaults route the keyword family to three different colors, which
  -- visibly fractures a `pub fn` block. catppuccin-macchiato unifies the
  -- whole verb column to one mauve; mirror that on gruvbox's red:
  --   * @keyword / @keyword.function / @keyword.return /
  --     @keyword.import / @keyword.conditional / @keyword.repeat → Red ✓
  --   * @keyword.operator (in, as, is, dyn)                      → Orange → Red
  --   * @keyword.storage  (let, mut, const, static)              → Orange → Red
  --   * @type.qualifier   (`pub` via treesitter)                 → Orange → Red
  --   * @lsp.type.modifier (`pub`/`mut`/`async` via rust-analyzer
  --     semantic tokens — beats treesitter, this is the actually-
  --     visible color in attached rust buffers)                  → Orange → Red
  --
  -- @variable.parameter defaults to Fg (no distinction from regular text).
  -- catppuccin gives parameter names a maroon tint distinct from types;
  -- gruvbox-material's purple (#d3869b) is the temperament match — pinkish,
  -- doesn't collide with type-yellow or member-blue.
  --
  -- @parameter is a back-compat shim for heirline.lua, which still reads
  -- the pre-nvim-0.10 capture name for its `red` slot.
  -- @variable.member picks struct fields out of the foreground in blue
  -- (catppuccin habit of lavender fields, mapped onto gruvbox-material's blue).
  local function apply_highlights()
    vim.api.nvim_set_hl(0, "@parameter", { link = "@variable.parameter" })
    vim.api.nvim_set_hl(0, "@variable.member", { fg = "#7daea3" })

    for _, group in ipairs({
      "@keyword.operator",
      "@keyword.storage",
      "@type.qualifier",
      "@lsp.type.modifier",
    }) do
      vim.api.nvim_set_hl(0, group, { link = "@keyword" })
    end

    vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#d3869b" })
    vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "@variable.parameter" })

    -- Namespace path segments (std/option, crate & module names). gruvbox
    -- routes @module/@namespace/@lsp.type.namespace to YellowItalic, but
    -- enable_italic=0 defines YellowItalic WITHOUT italic, so they render
    -- upright — unlike catppuccin, where @lsp.type.namespace → @module is
    -- italic. Re-add italic on just these groups (yellow kept) instead of
    -- flipping the global gruvbox_material_enable_italic (which would also
    -- italicise keywords/types/etc.). The priority-127 semantic winner
    -- @lsp.typemod.namespace.* links to a cleared @lsp, so the priority-125
    -- @lsp.type.namespace below shows through.
    local ns_italic = { fg = "#d8a657", italic = true }
    vim.api.nvim_set_hl(0, "@module", ns_italic)
    vim.api.nvim_set_hl(0, "@namespace", ns_italic)
    vim.api.nvim_set_hl(0, "@lsp.type.namespace", ns_italic)
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
