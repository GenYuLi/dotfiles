return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  cmd = { "Leet", "LeetGoogle" },
  config = function(_, opts)
    -- setup() must run first: leetcode.cache.cookie and friends read
    -- config.cache at module-load time, so our patches (which require
    -- leetcode-ui.question transitively) crash on a nil cache before
    -- setup populates it. Patches still take effect because the menu
    -- pages and Question class are required lazily on first :Leet.
    require("leetcode").setup(opts)
    require("withers.leet_patches").apply()
  end,
  opts = {
    keys = {
      quit = "q",
      reset_testcases = "R",
    },
    injector = {
      ["cpp"] = {
        before = {
          "#include <bits/stdc++.h>",
          "#include <ranges>", -- leetcode didn't include this by default
          "using namespace std;",
        },
      },
    },
    hooks = {
      ["enter"] = {
        function()
          -- Rust path patch must run AFTER leetcode.start() has
          -- populated config.storage; the `enter` hook is the
          -- earliest safe point. The patch itself is idempotent.
          require("withers.leet_patches").apply_rust_patch()
          require("copilot.command").disable()
          vim.g.copilot_disabled = true
          vim.g.autoformat = true
        end,
      },
      -- Fires once the question's code buffer is mounted (question.lua
      -- passes us the Question, q.bufnr = that code buffer). Scope the leet
      -- action keys buffer-local here rather than global: global mappings
      -- lose to toggleterm whenever it gets lazy-loaded (e.g. <leader>rB/rR
      -- in rust.lua `require`s toggleterm.terminal, which makes lazy.nvim
      -- re-register its `keys` spec and stomp the global leet binds).
      -- Buffer-local always wins. `question_enter` (vs a BufEnter+path
      -- match) means the maps exist the instant the buffer is first shown,
      -- with no race over when the buffer becomes current.
      ["question_enter"] = {
        function(q)
          local buf = q.bufnr
          if not buf or not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          local opts = function(desc) return { buffer = buf, desc = desc } end
          vim.keymap.set("n", "<leader>cc", "<cmd>Leet run<cr>", opts("Leetcode run testcase"))
          vim.keymap.set("n", "<leader>cp", "<cmd>Leet submit<cr>", opts("Leetcode submit"))
          vim.keymap.set("n", "<leader>cl", "<cmd>Leet lang<cr>", opts("Leetcode change language"))
          vim.keymap.set("n", [[<c-\>]], "<cmd>Leet console<cr>", opts("Leetcode console"))

          -- which-key (v3) builds a buffer's <space> trigger from the
          -- buffer-local <leader> maps present at build time, and rebuilds
          -- on BufEnter/BufReadPost/LspAttach. We add the maps here — at
          -- handle_mount's end, AFTER which-key already built this buffer —
          -- and rust-analyzer's async LspAttach then CLEARS the buffer's
          -- triggers with no rebuild until the next access. In that window
          -- the buffer-local <leader> maps exist but which-key has no
          -- buffer-local <space> trigger, so its global trigger is shadowed
          -- by them and the popup never shows until you nudge it (mode
          -- change, re-enter). Force a rebuild now and once more after LSP
          -- attaches. pcall: which-key.buf is internal, degrade gracefully.
          local function wk_refresh()
            pcall(function()
              require("which-key.buf").get({ buf = buf, update = true })
            end)
          end
          vim.schedule(wk_refresh)
          vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("WithersLeetWkRefresh_" .. buf, { clear = true }),
            buffer = buf,
            callback = function()
              vim.schedule(wk_refresh)
            end,
          })
        end,
      },
    },
  },
}
