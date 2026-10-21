local M = {
  "williamboman/mason.nvim",
  build = ":MasonUpdate",
}

---@type MasonSettings | { ensure_installed: string[] }
M.opts = {
  PATH = "append",
  ui = {
    border = "rounded",
    height = 0.8,
  },
  ensure_installed = {
    -- lsp
    "clangd",
    "lua-language-server",
    "neocmakelsp",
    "pyright",
    "rust-analyzer",
    "ruff",
    "starpls", -- bazel BUILD/.bzl: goto-def on labels/targets/load()
    "texlab",
    "typescript-language-server",

    -- formatter / linter
    "selene",
    "shfmt",
    "sqlfluff",
    "stylua",
    "prettier",
  },
}

M.config = function(_, opts)
  require("mason").setup(opts)

  local registry = require("mason-registry")
  registry:on("package:install:success", function()
    vim.defer_fn(function()
      -- trigger FileType event to possibly load this newly installed LSP server
      require("lazy.core.handler.event").trigger {
        event = "FileType",
        buf = vim.api.nvim_get_current_buf(),
      }
    end, 100)
  end)

  -- mason has no linux-aarch64 builds for these (the OrbStack sw-dev VM).
  -- clangd comes from the distro (clang-tools-extra), starpls from its GitHub
  -- release (home-config/install-tools.sh); selene is simply skipped.
  local unsupported = {}
  if vim.uv.os_uname().machine == "aarch64" then
    unsupported = { clangd = true, starpls = true, selene = true }
  end

  registry.refresh(function()
    for _, tool in ipairs(opts.ensure_installed) do
      if not unsupported[tool] then
        local p = registry.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end
  end)
end

return M
