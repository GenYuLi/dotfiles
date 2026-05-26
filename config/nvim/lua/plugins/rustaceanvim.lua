-- rustaceanvim handles rust-analyzer attach (workspace + standalone single-file
-- mode). Replaces the `vim.lsp.enable("rust_analyzer")` path; the corresponding
-- `after/lsp/rust_analyzer.lua` is intentionally absent to avoid double-attach.
-- mason installs the binary; rustaceanvim finds it via PATH.

return {
  "mrcjkb/rustaceanvim",
  version = "^7",
  lazy = false, -- already lazy via filetype
  init = function()
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            procMacro = {
              enable = true,
            },
            -- Master switch: disable check-on-save entirely. cargo check
            -- on lone .rs (no Cargo.toml in tree) triggers cargo's
            -- single-file script mode which requires nightly. The
            -- top-level `checkOnSave` boolean is the only way to stop
            -- it; nesting it under `check.onSave` is silently ignored
            -- because that key doesn't exist in rust-analyzer's schema.
            checkOnSave = false,
            -- `check` still governs HOW to check when manually invoked
            -- (e.g. <leader>rC runs cargo clippy directly).
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            inlayHints = {
              typeHints = {
                enable = true,
                hideInsideAssignedValue = true,
              },
              chainingHints = { enable = true },
              parameterHints = { enable = true },
              closingBraceHints = {
                enable = true,
                minLength = 25,
              },
              lifetimeElisionHints = {
                enable = true,
                useParameterNames = true,
              },
              reborrowHints = { enable = true },
              discriminantHints = { enable = true },
            },
            lens = {
              enable = true,
              locations = { "method", "impl" },
              runnable = true,
              references = true,
              implementations = true,
              methodReferences = false,
            },
            hover = {
              actions = {
                enable = true,
                implementations = true,
                references = true,
                run = true,
                debug = true,
                gotoTypeDef = true,
              },
            },
            assist = {
              importGranularity = "module",
              importPrefix = "crate",
            },
            experimental = {
              procAttrMacros = true,
            },
          },
        },
      },
    }
  end,
}
