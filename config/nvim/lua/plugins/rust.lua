-- Rust workflow: fzf picker for rust-analyzer runnables
-- Queries `experimental/runnables` from the running rust-analyzer instance
-- and presents them via fzf-lua. No extra plugins needed.

local function rust_runnables()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params()

  vim.lsp.buf_request(bufnr, "experimental/runnables", params, function(err, result)
    if err then
      vim.notify("rust-analyzer: " .. err.message, vim.log.levels.ERROR)
      return
    end
    if not result or #result == 0 then
      vim.notify("rust-analyzer: no runnables found")
      return
    end

    -- Build display list and a label→runnable map
    local labels = {}
    local by_label = {}
    for _, r in ipairs(result) do
      table.insert(labels, r.label)
      by_label[r.label] = r
    end

    require("fzf-lua").fzf_exec(labels, {
      prompt = "Rust Runnables❯ ",
      winopts = {
        height = 0.4,
        width = 0.6,
      },
      actions = {
        -- Enter: run
        ["default"] = function(selected)
          local r = by_label[selected[1]]
          if not r then return end
          local args = r.args
          -- Assemble the cargo command
          local cargo_cmd = table.concat(args.cargoArgs or {}, " ")
          if args.cargoExtraArgs and #args.cargoExtraArgs > 0 then
            cargo_cmd = cargo_cmd .. " " .. table.concat(args.cargoExtraArgs, " ")
          end
          local exec_args = args.executableArgs or {}
          local cmd = "cd " .. vim.fn.shellescape(args.workspaceRoot)
            .. " && cargo " .. cargo_cmd
          if #exec_args > 0 then
            cmd = cmd .. " -- " .. table.concat(exec_args, " ")
          end
          require("toggleterm.terminal").Terminal:new({
            cmd = cmd,
            direction = "float",
            close_on_exit = false,
          }):toggle()
        end,
        -- Alt-Enter: edit the command before running
        ["alt-enter"] = function(selected)
          local r = by_label[selected[1]]
          if not r then return end
          local args = r.args
          local cargo_cmd = table.concat(args.cargoArgs or {}, " ")
          if args.cargoExtraArgs and #args.cargoExtraArgs > 0 then
            cargo_cmd = cargo_cmd .. " " .. table.concat(args.cargoExtraArgs, " ")
          end
          local default_cmd = "cargo " .. cargo_cmd
          if args.executableArgs and #args.executableArgs > 0 then
            default_cmd = default_cmd .. " -- " .. table.concat(args.executableArgs, " ")
          end
          vim.ui.input(
            { prompt = "Run: ", default = default_cmd },
            function(input)
              if not input or input == "" then return end
              local cmd = "cd " .. vim.fn.shellescape(args.workspaceRoot) .. " && " .. input
              require("toggleterm.terminal").Terminal:new({
                cmd = cmd,
                direction = "float",
                close_on_exit = false,
              }):toggle()
            end
          )
        end,
      },
    })
  end)
end

return {
  {
    -- Dummy spec to attach Rust keymaps on FileType rust
    "neovim/nvim-lspconfig",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function(ev)
          local opts = function(desc) return { buffer = ev.buf, desc = desc } end
          -- <leader>rr: fzf picker for all runnables (tests + binaries + examples)
          vim.keymap.set("n", "<leader>rr", rust_runnables, opts("Rust: pick & run"))
          -- <leader>rt: run test under cursor via experimental/runnables
          vim.keymap.set("n", "<leader>rt", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local params = vim.lsp.util.make_position_params()
            vim.lsp.buf_request(bufnr, "experimental/runnables", params, function(err, result)
              if err then
                vim.notify("rust-analyzer: " .. err.message, vim.log.levels.ERROR)
                return
              end
              if not result or #result == 0 then
                vim.notify("No runnables found at cursor", vim.log.levels.WARN)
                return
              end
              -- Find the first test runnable (skip the generic "cargo test" / "cargo check")
              local test_runnable
              for _, r in ipairs(result) do
                if r.label:match("^test ") or r.label:match("^doctest ") then
                  test_runnable = r
                  break
                end
              end
              if not test_runnable then
                vim.notify("No test found at cursor", vim.log.levels.WARN)
                return
              end
              local args = test_runnable.args
              local cargo_cmd = table.concat(args.cargoArgs or {}, " ")
              if args.cargoExtraArgs and #args.cargoExtraArgs > 0 then
                cargo_cmd = cargo_cmd .. " " .. table.concat(args.cargoExtraArgs, " ")
              end
              local cmd = "cd " .. vim.fn.shellescape(args.workspaceRoot)
                .. " && cargo " .. cargo_cmd
              if args.executableArgs and #args.executableArgs > 0 then
                cmd = cmd .. " -- " .. table.concat(args.executableArgs, " ")
              end
              require("toggleterm.terminal").Terminal:new({
                cmd = cmd,
                direction = "float",
                close_on_exit = false,
              }):toggle()
            end)
          end, opts("Rust: run test under cursor"))
          -- <leader>rb: cargo build
          vim.keymap.set("n", "<leader>rb", function()
            vim.cmd('TermExec cmd="cargo build"')
          end, opts("Rust: cargo build"))
          -- <leader>rc: cargo check (faster than build)
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd('TermExec cmd="cargo check"')
          end, opts("Rust: cargo check"))
          -- <leader>rx: cargo clippy
          vim.keymap.set("n", "<leader>rx", function()
            vim.cmd('TermExec cmd="cargo clippy"')
          end, opts("Rust: cargo clippy"))
        end,
      })
    end,
  },
}
