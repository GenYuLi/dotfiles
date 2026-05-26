-- Override the hardcoded "LEETCODE" ascii banner before any page module
-- loads it. menu-header.lua returns an *instance*, so we replace it the
-- same way. Done in a `config` function so it runs before setup() and
-- before pages require the header.
local function override_banner()
  local banner = {
    [[██╗    ██╗██╗████████╗██╗  ██╗███████╗██████╗ ███████╗]],
    [[██║    ██║██║╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝]],
    [[██║ █╗ ██║██║   ██║   ███████║█████╗  ██████╔╝███████╗]],
    [[██║███╗██║██║   ██║   ██╔══██║██╔══╝  ██╔══██╗╚════██║]],
    [[╚███╔███╔╝██║   ██║   ██║  ██║███████╗██║  ██║███████║]],
    [[ ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝]],
  }
  local Lines = require("leetcode-ui.lines")
  local Header = Lines:extend("LeetMenuHeader")
  function Header:init()
    Header.super.init(self, {}, { hl = "Keyword" })
    for _, line in ipairs(banner) do
      self:append(line):endl()
    end
  end
  package.loaded["leetcode-ui.lines.menu-header"] = Header()
end

return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  cmd = "Leet",
  config = function(_, opts)
    override_banner()
    require("leetcode").setup(opts)
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
