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
          vim.keymap.set("n", "<leader>cc", "<cmd>Leet run<cr>", { desc = "Leetcode run testcase" })
          vim.keymap.set("n", "<leader>cp", "<cmd>Leet submit<cr>", { desc = "Leetcode submit" })
          vim.keymap.set("n", "<leader>cl", "<cmd>Leet lang<cr>", { desc = "Leetcode change language" })
          vim.keymap.set("n", [[<c-\>]], "<cmd>Leet console<cr>", { desc = "Leetcode console" })
        end,
      },
    },
  },
}
