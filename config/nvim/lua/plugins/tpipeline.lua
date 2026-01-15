local M = {
  "vimpostor/vim-tpipeline",
  lazy = true,
  commit = "5f663e863df6fba9749ec6db0a890310ba4ad0a9",
}

function M.setup()
  vim.g.tpipeline_cursormoved = 1
  vim.g.tpipeline_restore = 1
  vim.g.tpipeline_clearstl = 1
  vim.g.tpipeline_size = 300

  -- https://github.com/vimpostor/vim-tpipeline/issues/19#issuecomment-1000844167
  vim.opt.fillchars:append {
    stl = "─",
    stlnc = "─",
  }
end

function M.config()
  local augroup = vim.api.nvim_create_augroup("dotfiles_tpipeline_integration", { clear = true })
  local focused = true
  local need_update = true

  -- unset tmux option to the one set in tmux.conf
  local function unset_tmux_option(opt)
    vim.system { "tmux", "set-option", "-u", opt }
  end

  -- set window name to current directory
  local function set_tmux_window_name_to_cwd()
    local ok, cwd = pcall(vim.fn.fnamemodify, vim.uv.cwd(), ":t")
    if ok and cwd then
      vim.system { "tmux", "rename-window", cwd }
    end
  end

  -- update tmux status by neovim statusline
  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "RecordingEnter" }, {
    desc = "update tpipeline",
    command = "call tpipeline#update()",
    group = augroup,
  })

  -- sync status style on CursorHold
  local function sync_tmux_status_style()
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      once = true,
      group = vim.api.nvim_create_augroup("dotfiles_force_update_tpipeline", { clear = true }),
      callback = function()
        -- check if neovim is still focused
        if not focused then
          return
        end

        if need_update then
          set_tmux_window_name_to_cwd()
          need_update = false
        end
      end,
    })
  end
  sync_tmux_status_style()

  -- matched tmux status style and statusline
  vim.api.nvim_create_autocmd({ "ColorScheme", "FocusGained" }, {
    callback = function(e)
      if e.event == "FocusGained" then
        focused = true
        need_update = true
      end
      sync_tmux_status_style()
    end,
    group = augroup,
  })

  -- rename tmux window with CWD
  vim.api.nvim_create_autocmd({ "DirChanged", "LspAttach" }, {
    callback = set_tmux_window_name_to_cwd,
    group = augroup,
  })

  -- reset tmux options set by neovim
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.system { "tmux", "setw", "automatic-rename", "on" }
      unset_tmux_option("status-left")
      unset_tmux_option("status-right")
      unset_tmux_option("status-style")
    end,
    group = augroup,
  })
end

return M
