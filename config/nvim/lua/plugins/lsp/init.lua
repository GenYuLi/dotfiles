local M = {
  "neovim/nvim-lspconfig",
  cmd = { "Mason", "LspInfo" },
  event = "LazyFile",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "ray-x/lsp_signature.nvim",
    "smjonas/inc-rename.nvim",

    require("plugins.lsp.mason"),
    require("plugins.lsp.null-ls"),
  },
}

function M.config()
  local on_attach = function(_client, bufnr)
    local function opts(desc)
      return { buffer = bufnr, desc = desc }
    end
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts("signature_help"))
    vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<cr>", opts("Hover doc"))
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("go to definition"))
    vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts("go to type definition"))
    vim.keymap.set("n", "gr", "<cmd>FzfLua lsp_references<cr>", opts("go to references"))
    vim.keymap.set("n", "<leader>lr", ":IncRename ", opts("Rename"))
    vim.keymap.set("n", "<leader>lR", function()
      return ":" .. require("inc_rename").config.cmd_name .. " " .. vim.fn.expand("<cword>")
    end, { buffer = bufnr, expr = true, desc = "Rename (with cword)" })

    vim.keymap.set("n", "<leader>lh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled()
      vim.lsp.inlay_hint.enable(not enabled)
      vim.notify("LSP inlay hint: " .. (not enabled and "on" or "off"))
    end, opts("toggle inlay hists"))
  end

  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  require("mason-lspconfig").setup_handlers {
    function(server)
      local opts = {
        on_attach = on_attach,
        capabilities = capabilities,
      }

      if server == "clangd" then
        -- 只讓 clangd 處理 C/C++ 相關的檔案，不包含 "proto"
        opts.filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }
      end

      local have_config, lsp_config = pcall(require, "plugins.lsp.server." .. server)
      if have_config then
        opts = vim.tbl_deep_extend("force", lsp_config, opts)
      end

      require("lspconfig")[server].setup(opts)
    end,
  }

  require("plugins.lsp.utils").setup_auto_detach()

  -- settings
  local signs = { Error = "", Info = "󰋼", Hint = "󰌵", Warn = "" }
  for name, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. name
    vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
  end

  vim.diagnostic.config {
    virtual_text = false,
    signs = {
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = true,
      border = "rounded",
      source = "if_many",
    },
  }

  -- set rounded border
  local rounded_border = {
    border = "rounded",
  }
  require("lspconfig.ui.windows").default_options = rounded_border
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, rounded_border)
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, rounded_border)
end

return M
