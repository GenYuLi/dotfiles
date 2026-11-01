-- NOTE: https://clangd.llvm.org/guides/system-headers#query-driver
return {
  -- 只讓 clangd 處理 C/C++ 相關的檔案，不包含 "proto"
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".clang-format" })
    if root and root ~= vim.env.HOME then
      on_dir(root)
      return
    end

    root = vim.fs.root(bufnr, {
      {
        ".clangd",
        ".clang-tidy",
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac",
      },
      {
        ".git",
      },
    })
    on_dir(root or vim.uv.cwd())
  end,
  cmd = {
    -- Low-memory hosts (the sw-dev VM) link a wrapper that caps the
    -- background indexer at 6 workers; see dotfiles home-config/bin/clangd-lean.
    vim.fn.executable("clangd-lean") == 1 and "clangd-lean" or "clangd",
    "--background-index",
    "--background-index-priority=low",
    "--clang-tidy",
    -- '--check=cppcoreguidelines-*',
    "--header-insertion=iwyu",
    "--enable-config",
    "--fallback-style=google",
    "--function-arg-placeholders=false",
    "--completion-style=detailed",
    "--query-driver=/nix/store/*gcc-wrapper*/bin/g++",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
}
