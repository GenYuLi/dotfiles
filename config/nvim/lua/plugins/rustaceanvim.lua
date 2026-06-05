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
        -- Scope `check.workspace` per project. The leetcode storage is one
        -- big Cargo workspace holding every solved problem as a member, so
        -- a workspace-wide check on save would re-check the whole backlog.
        -- Restrict flycheck to the current package there; real projects
        -- keep the default workspace-wide check (catches cross-crate
        -- breakage). Set explicitly each call — never mutate-and-leak — so
        -- switching from a leetcode buffer to a normal project can't carry
        -- a stale `workspace = false`.
        settings = function(project_root, default_settings)
          local rs = default_settings["rust-analyzer"]
          local leet_root = vim.fs.joinpath(vim.fn.stdpath("data"), "leetcode")
          rs.check = rs.check or {}
          rs.check.workspace = not (project_root and vim.startswith(project_root, leet_root))
          return default_settings
        end,
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
            -- On: leetcode questions are real Cargo crates under a parent
            -- workspace (see leet_patches), so cargo check surfaces real
            -- type errors (E0308 "expected usize, found i32", etc.) on
            -- save. Tradeoff: a lone .rs with no Cargo.toml in its tree
            -- hits cargo's single-file script mode (needs nightly) and
            -- complains — accepted, since the standalone rustc flow
            -- (<leader>rB/rR) covers those files.
            checkOnSave = true,
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
