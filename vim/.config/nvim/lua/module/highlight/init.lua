local config = require("module.highlight.config")

local plugins = {
  ["nvim-treesitter/nvim-treesitter"] = {
    run = ":TSUpdate",
    event = { "BufRead", "BufNewFile" },
    module = "nvim-treesitter",
    cmd = "TSUpdate",
    commit = "4cccb6f494eb255b32a290d37c35ca12584c74d0",
    config = config.treesitter
  },

  ["p00f/nvim-ts-rainbow"] = {
    after = "nvim-treesitter",
  },

  ["andymass/vim-matchup"] = {
    after = "nvim-treesitter",
    config = function()
      vim.g.matchup_matchparen_offscreen = {
        method = 'popup',
        fullwidth = 1
      }
    end
  },

  ["nvim-treesitter/nvim-treesitter-context"] = {
    after = "nvim-treesitter",
  },

  ["JoosepAlviste/nvim-ts-context-commentstring"] = {
    module = "ts_context_commentstring",
  },

  ["nvim-treesitter/playground"] = {
    cmd = { "TSPlaygroundToggle" , "TSHighlightCapturesUnderCursor" }
  },

  ["windwp/nvim-ts-autotag"] = {
    after = "nvim-treesitter",
    config = config.autotag
  },

  ["windwp/nvim-autopairs"] = {
    after = "nvim-treesitter",
    config = config.autopairs
  },

  ["norcalli/nvim-colorizer.lua"] = {
    after = "nvim-treesitter",
    config = config.colorizer
  },

  ["folke/todo-comments.nvim"] = {
    after = "nvim-treesitter",
    config = config.todo
  },

  ["RRethy/vim-illuminate"] = {
    after = "nvim-treesitter",
    module = "illuminate",
    config = config.illuminate
  },

  ["lukas-reineke/indent-blankline.nvim"] = {
    after = "nvim-treesitter",
    config = config.indentline
  },

  ["folke/twilight.nvim"] = {
    cmd = "ZenMode",
    config = config.twilight
  },

  ["folke/zen-mode.nvim"] = {
    after = "twilight.nvim",
    config = config.zen
  },
}

return plugins
