local M = {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-emoji",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp",
    "saadparwaiz1/cmp_luasnip",
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
    "lukas-reineke/cmp-rg",
    "zbirenbaum/copilot.lua",
    "zbirenbaum/copilot-cmp",
  },
}

function M.config()
  require("luasnip/loaders/from_vscode").lazy_load()

  local function has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
  end

  local function remove_leading_chr(s)
    if string.sub(s, 1, 1) == " " then
      s = s:sub(2)
    end
    return s:gsub('•', '')
  end

  local luasnip = require("luasnip")
  local s = luasnip.snippet
  local t = luasnip.text_node
  local i = luasnip.insert_node

  -- NOTE: https://github.com/molleweide/LuaSnip-snippets.nvim#how-to-compose-snippets
  vim.schedule(function()
    luasnip.add_snippets("cpp", {
      s("incp", {
        t({ "#include <bits/stdc++.h>", "" }),
        t({ "using namespace std;", "", "" }),
        i(0)
      })
    })
  end)

  local cmp = require("cmp")
  local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }

  local mappings = {
    ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item(cmp_select_opts), { "i", "c" }),
    ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item(cmp_select_opts), { "i", "c" }),
    ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
    ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
    ["<C-c>"] = cmp.mapping {
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    },
    ["<CR>"] = cmp.mapping(cmp.mapping.confirm { select = false }, { "i", "c" }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item(cmp_select_opts)
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { 'i', 'c', 's', }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item(cmp_select_opts)
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 'c', 's', }),
  }

  require("copilot").setup {
    -- suggestion = { enabled = false },
    panel = { enabled = false },
  }
  require("copilot_cmp").setup()

  local sorting = require("cmp.config.default")().sorting
  table.insert(sorting.comparators, 1, require("copilot_cmp.comparators").prioritize)

  cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    sorting = sorting,
    mapping = mappings,
    ---@diagnostic disable-next-line: missing-fields
    formatting = {
      format = function(_, item)
        local icon = require("mini.icons").get("lsp", item.kind)
        item.kind = string.format("%s %s", icon, item.kind)
        item.abbr = remove_leading_chr(item.abbr)
        return item
      end,
    },
    sources = cmp.config.sources({
      { name = "lazydev" }, -- set group index to 0 to skip loading LuaLS completions
    }, {
      { name = "copilot" },
      { name = "nvim_lsp" },
      { name = "path" },
      { name = "rg", keyword_length = 3 },
      { name = "render-markdown" },
      { name = "luasnip" },
      { name = "emoji" },
    }),
    preselect = cmp.PreselectMode.None,
    confirm_opts = {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    window = {
      documentation = cmp.config.window.bordered(),
      completion = cmp.config.window.bordered {
        col_offset = -1,
      }
    },
    experimental = {
      ghost_text = true,
    },
  }

  cmp.setup.cmdline(':', {
    mapping = mappings,
    sources = {
      { name = "path" },
      { name = "cmdline" },
    },
  })

  cmp.setup.cmdline({ '/', '?' }, {
    mapping = mappings,
    sources = {
      { name = "buffer" },
    },
  })
end

return M
