local M = {
  "rebelot/heirline.nvim",
  event = "VeryLazy",
}

function M.config()
  local conditions = require("heirline.conditions")
  local utils = require("heirline.utils")

  -- nerd-font glyphs (literal)
  local assets = {
    cap_left = "",
    cap_right = "",
    divider = "·",
    vim = " ",
    macro = " ",
    lock = " ",
    git = " ",
    tree = " ",
    lsp = " ",
    dir = " ",
    host = "󰒋 ",
    session = " ",
    search = " ",
    search_forward = " ",
    search_backward = " ",
    diag_error = " ",
    diag_warn = " ",
  }

  -- gruvbox-material palette. Structural tones (bg/pill/text/dividers) are
  -- sourced live from highlight groups so the bar tracks the active contrast
  -- (soft/medium/hard); accent hues are gruvbox-material's stable "material"
  -- variants. Everything is returned as "#rrggbb" — the tmux mode pill below
  -- needs literal hex, so numeric hl attrs are formatted back to hex.
  local function hl_hex(group, attr, fallback)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    local v = ok and hl and hl[attr]
    if type(v) == "number" then
      return string.format("#%06x", v)
    end
    return fallback
  end

  -- gruvbox-material accent hues (stable across soft/medium/hard contrast).
  local accents = {
    red = "#ea6962",
    orange = "#e78a4e",
    yellow = "#d8a657",
    green = "#a9b665",
    aqua = "#89b482",
    blue = "#7daea3",
    purple = "#d3869b",
    grey = "#928374",
  }

  -- The catppuccin key names the components reference, remapped onto gruvbox.
  local setup_colors = function()
    return {
      bg = hl_hex("Normal", "bg", "#1d2021"),
      pill = hl_hex("CursorLine", "bg", "#282828"),
      txt = hl_hex("Normal", "fg", "#d4be98"),
      subtext0 = hl_hex("Comment", "fg", "#a89984"),
      dim = accents.grey,
      divider = hl_hex("LineNr", "fg", "#7c6f64"),

      lavender = accents.blue,
      green = accents.green,
      mauve = accents.purple,
      flamingo = accents.orange,
      red = accents.red,
      yellow = accents.yellow,
      peach = accents.orange,
      sapphire = accents.blue,
      teal = accents.aqua,
      blue = accents.blue,
      pink = accents.purple,
    }
  end

  -- raw hex palette, used to build literal tmux #[fg=..] directives for the
  -- piped mode pill (tpipeline). Keyed by the names mode_color maps to.
  local C = {
    lavender = accents.blue,
    green = accents.green,
    mauve = accents.purple,
    peach = accents.orange,
    red = accents.red,
    pink = accents.purple,
    yellow = accents.yellow,
    subtext0 = "#a89984",
    bg = "#1d2021",
  }

  -- Gap/caps carry NO bg so the bar stays transparent between pills — each pill
  -- floats as a discrete lozenge on the (translucent) terminal background rather
  -- than fusing into one opaque strip.
  local Gap = { provider = " " }
  local Divider = { provider = " " .. assets.divider .. " ", hl = { fg = "divider" } }

  -- wrap a list of components in a rounded pill of background `bg`. The caps'
  -- fg is the pill colour on a transparent bg, so the rounded ends float; the
  -- inner children inherit `bg` and the muted `txt` fg, accents set only `fg`.
  local function pill(bg, children, condition, no_gap)
    local inner = { hl = { bg = bg, fg = "txt" }, { provider = " " } }
    for _, child in ipairs(children) do
      inner[#inner + 1] = child
    end
    inner[#inner + 1] = { provider = " " }
    local p = {
      condition = condition,
      { provider = assets.cap_left, hl = { fg = bg } },
      inner,
      { provider = assets.cap_right, hl = { fg = bg } },
    }
    if not no_gap then
      p[#p + 1] = Gap
    end
    return p
  end

  -- When piped into tmux via vim-tpipeline, fold tmux's prefix/copy/sync state
  -- into the mode pill (the only element that carries state colour).
  --
  -- This is emitted as ONE raw tmux conditional. tmux splits #{?cond,a,b} on
  -- commas, so every #[..] inside a branch must be a SINGLE attribute — a
  -- #[fg=x,bg=y] (with a comma) would corrupt the branch. Hence literal #[fg=..]
  -- only; the pill bg/bold come from the surrounding heirline hl (outside the
  -- conditional, where commas are safe).
  -- vim glyph (U+E62B) for the mode badge when we're in nvim (piped via
  -- tpipeline). The tmux-native status-left uses the oct-terminal glyph instead,
  -- so the icon tells you at a glance whether the focused pane is nvim or a
  -- shell.
  local TERMICON = "\238\152\171"

  local function wrap_tmux_highlight(mode)
    if not require("core.utils").is_tmux_active() then
      return mode
    end
    -- Emit a FILLED rounded badge as raw tmux directives (caps + bg + fg all in
    -- the mode colour). tmux splits #{?cond,a,b} on commas, so every #[..] must
    -- be a SINGLE attribute (no #[fg=x,bg=y]). Structurally identical to the
    -- tmux-native badge in config/tmux/tmux.conf.
    local cl, cr, base = assets.cap_left, assets.cap_right, C.bg
    local function badge(color, label)
      return ("#[fg=%s]#[bg=%s]%s#[bg=%s]#[fg=%s]#[bold] %s %s #[nobold]#[fg=%s]#[bg=%s]%s"):format(
        color,
        base,
        cl,
        color,
        base,
        TERMICON,
        label,
        color,
        base,
        cr
      )
    end
    return {
      static = mode.static,
      init = function(self)
        self.mode = vim.fn.mode(1)
        self.short = self.mode:sub(1, 1)
      end,
      provider = function(self)
        local label = self.mode_alias[self.mode] or self.mode_alias[self.short] or "NORMAL"
        local hex = C[self.mode_color[self.short] or "lavender"] or C.lavender
        return ("#{?client_prefix,%s,#{?pane_in_mode,%s,#{?pane_synchronized,%s,%s}}}"):format(
          badge(C.pink, "PREFIX"),
          badge(C.yellow, "COPY"),
          badge(C.green, "SYNC"),
          badge(hex, label)
        )
      end,
      update = { "ModeChanged", "RecordingEnter", "RecordingLeave" },
    }
  end

  -- ── mode (individual lead pill) ──────────────────────────────────────────
  local Mode = {
    init = function(self)
      self.mode = vim.fn.mode(1)
      self.short_mode = self.mode:sub(1, 1)
    end,
    static = {
      mode_alias = {
        ["n"] = "NORMAL",
        ["no"] = "O-PEND",
        ["nov"] = "O-PEND",
        ["noV"] = "O-PEND",
        ["niI"] = "NORMAL",
        ["niR"] = "NORMAL",
        ["niV"] = "NORMAL",
        ["v"] = "VISUAL",
        ["vs"] = "VISUAL",
        ["V"] = "V-LINE",
        ["Vs"] = "V-LINE",
        ["\22"] = "V-BLOCK",
        ["\22s"] = "V-BLOCK",
        ["s"] = "SELECT",
        ["S"] = "S-LINE",
        ["\19"] = "S-BLOCK",
        ["i"] = "INSERT",
        ["ic"] = "INSERT",
        ["ix"] = "INSERT",
        ["R"] = "REPLACE",
        ["Rc"] = "REPLACE",
        ["Rv"] = "V-REPLACE",
        ["Rx"] = "REPLACE",
        ["c"] = "COMMAND",
        ["cv"] = "COMMAND",
        ["ce"] = "COMMAND",
        ["r"] = "PROMPT",
        ["rm"] = "MORE",
        ["r?"] = "CONFIRM",
        ["!"] = "SHELL",
        ["t"] = "TERMINAL",
        ["nt"] = "TERMINAL",
      },
      mode_color = {
        ["n"] = "lavender",
        ["i"] = "green",
        ["v"] = "mauve",
        ["V"] = "mauve",
        ["\22"] = "mauve",
        ["c"] = "peach",
        ["s"] = "green",
        ["S"] = "green",
        ["\19"] = "green",
        ["R"] = "red",
        ["r"] = "red",
        ["!"] = "lavender",
        ["t"] = "lavender",
      },
    },
    {
      provider = function(self)
        local label = self.mode_alias[self.mode] or self.mode_alias[self.short_mode] or "NORMAL"
        return assets.vim .. label
      end,
      hl = function(self)
        return { fg = self.mode_color[self.short_mode] or "lavender", bold = true }
      end,
    },
    update = { "ModeChanged", "RecordingEnter", "RecordingLeave" },
  }

  -- ── left group: file · treesitter · git · diagnostics ────────────────────
  local function ts_active()
    return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
  end

  local Treesitter = {
    condition = ts_active,
    provider = assets.tree,
    hl = { fg = "teal" },
  }

  local Macro = {
    condition = function(self)
      self.reg = vim.fn.reg_recording()
      return self.reg ~= ""
    end,
    provider = function(self)
      return assets.macro .. "rec @" .. self.reg
    end,
    hl = { fg = "red" },
    update = { "RecordingEnter", "RecordingLeave" },
  }

  local FileType = {
    {
      provider = function()
        local ft = vim.bo.filetype
        local icon = require("nvim-web-devicons").get_icon_by_filetype(ft, { default = true })
        return (icon and (icon .. " ") or "") .. (ft ~= "" and ft or "[none]")
      end,
    },
    {
      condition = function()
        return not vim.bo.modifiable or vim.bo.readonly
      end,
      provider = assets.lock,
      hl = { fg = "peach" },
    },
    Treesitter,
  }

  local FileBlock = {
    fallthrough = false,
    Macro,
    FileType,
  }

  local Git = {
    condition = conditions.is_git_repo,
    init = function(self)
      ---@diagnostic disable-next-line: undefined-field
      self.status_dict = vim.b.gitsigns_status_dict
    end,
    Divider,
    { provider = assets.git, hl = { fg = "green" } },
    {
      provider = function(self)
        return self.status_dict.head
      end,
    },
  }

  local Diagnostics = {
    condition = conditions.has_diagnostics,
    init = function(self)
      self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    end,
    update = { "DiagnosticChanged", "BufEnter" },
    {
      condition = function(self)
        return self.errors > 0 or self.warnings > 0
      end,
      Divider,
    },
    {
      condition = function(self)
        return self.errors > 0
      end,
      provider = function(self)
        return assets.diag_error .. self.errors .. " "
      end,
      hl = { fg = "red" },
    },
    {
      condition = function(self)
        return self.warnings > 0
      end,
      provider = function(self)
        return assets.diag_warn .. self.warnings
      end,
      hl = { fg = "yellow" },
    },
  }

  -- ── right group 1: lsp · search · showcmd ────────────────────────────────
  -- dividers are gated on a preceding segment being present, so a grouped pill
  -- never starts with a stray "·".
  local LSPActive = {
    condition = conditions.lsp_attached,
    update = { "LspAttach", "LspDetach", "BufEnter" },
    { provider = assets.lsp, hl = { fg = "sapphire" } },
    {
      provider = function()
        local names = {}
        for _, server in pairs(vim.lsp.get_clients { bufnr = 0 }) do
          names[#names + 1] = server.name
        end
        return table.concat(names, " ")
      end,
    },
  }

  local SearchCount = {
    condition = function(self)
      if vim.v.hlsearch ~= 0 then
        local ok, res = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 250 })
        if ok and res.total then
          self.search = res
          return true
        end
      end
      return false
    end,
    {
      provider = function(self)
        local direction = vim.v.searchforward == 1 and assets.search_forward or assets.search_backward
        local res = self.search
        if res.incomplete == 1 then
          return ("%s?/??%s"):format(assets.search, direction)
        end
        local stat = res.incomplete
        return ("%s%s%d/%s%d%s"):format(
          assets.search,
          (stat == 2 and res.current > res.maxcount) and ">" or "",
          res.current,
          stat == 2 and ">" or "",
          res.total,
          direction
        )
      end,
      hl = { fg = "mauve" },
    },
  }

  -- lsp by default; search takes the slot while a search is active (never both)
  local LspOrSearch = {
    fallthrough = false,
    SearchCount,
    LSPActive,
  }

  -- showcmd: standalone (no pill), leftest component in right-status so its changing width
  -- never shifts the pills; only when NOT piped into tmux.
  local ShowCmd = {
    condition = function()
      return not require("core.utils").is_tmux_active()
    end,
    provider = "%S ",
    hl = { fg = "dim" },
  }

  local function right1_active()
    return conditions.lsp_attached() or vim.v.hlsearch ~= 0
  end

  -- ── right group 2: session/dir · host ────────────────────────────────────
  local SessionOrDir = {
    fallthrough = false,
    {
      condition = function()
        return require("core.utils").is_tmux_active()
      end,
      { provider = assets.session, hl = { fg = "mauve" } },
      { provider = "#S" },
    },
    {
      { provider = assets.dir, hl = { fg = "mauve" } },
      {
        provider = function()
          return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        end,
        update = "DirChanged",
      },
    },
  }

  local Host = {
    Divider,
    { provider = assets.host, hl = { fg = "flamingo" } },
    {
      provider = function()
        return vim.fn.hostname()
      end,
      update = "BufEnter",
    },
  }

  -- ── assembly ─────────────────────────────────────────────────────────────
  local Align = { provider = "%=" }

  -- Piped through tmux (tpipeline): the mode is a self-contained filled badge
  -- (its own caps) so it matches the tmux-native bar exactly; just add the
  -- inter-pill Gap. Otherwise fall back to the plain grey pill.
  local ModeElement = require("core.utils").is_tmux_active() and { wrap_tmux_highlight(Mode), Gap }
    or pill("pill", { Mode })

  local StatusLine = {
    ModeElement,
    pill("pill", { FileBlock, Git, Diagnostics }),
    Align,
    ShowCmd,
    pill("pill", { LspOrSearch }, right1_active),
    pill("pill", { SessionOrDir, Host }, nil, true),
  }

  require("heirline").setup {
    statusline = StatusLine,
    opts = {
      colors = setup_colors(),
    },
  }
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      utils.on_colorscheme(setup_colors)
    end,
  })

  if require("core.utils").is_tmux_active() then
    require("plugins.tpipeline").setup()
    require("lazy").load { plugins = { "vim-tpipeline" } }
  end
end

return M
