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

          -- Scope these as buffer-local on the leetcode question buffer,
          -- not global. Global mappings here lose to toggleterm whenever
          -- it gets lazy-loaded (e.g. via <leader>rB/rR in rust.lua, which
          -- `require`s toggleterm.terminal): lazy.nvim re-registers its
          -- `keys` spec on plugin load and stomps the global leet binds.
          -- Buffer-local always wins over global, so scoping fixes it.
          local storage = require("leetcode.config").storage.home:absolute()
          if storage:sub(-1) ~= "/" then
            storage = storage .. "/"
          end
          local function apply(buf)
            local opts = function(desc) return { buffer = buf, desc = desc } end
            vim.keymap.set("n", "<leader>cc", "<cmd>Leet run<cr>", opts("Leetcode run testcase"))
            vim.keymap.set("n", "<leader>cp", "<cmd>Leet submit<cr>", opts("Leetcode submit"))
            vim.keymap.set("n", "<leader>cl", "<cmd>Leet lang<cr>", opts("Leetcode change language"))
            vim.keymap.set("n", [[<c-\>]], "<cmd>Leet console<cr>", opts("Leetcode console"))
          end
          local augroup = vim.api.nvim_create_augroup("WithersLeetBufKeymaps", { clear = true })
          vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            callback = function(args)
              local fname = vim.api.nvim_buf_get_name(args.buf)
              if fname ~= "" and vim.startswith(fname, storage) then
                apply(args.buf)
              end
            end,
          })
          -- Cover the case where a leet question buffer is already current
          -- when `enter` re-fires (BufEnter wouldn't fire for it again).
          local cur = vim.api.nvim_get_current_buf()
          local cur_name = vim.api.nvim_buf_get_name(cur)
          if cur_name ~= "" and vim.startswith(cur_name, storage) then
            apply(cur)
          end
        end,
      },
    },
  },
}
