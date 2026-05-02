return {
  init_options = {
    format = { enable = true },
    scan_cmake_in_package = true,
  },
  -- NOTE: 用 function 而非 root_markers 的 list-of-lists 形式 — nvim 0.11
  -- 的 vim.lsp.enable 在 auto-attach path 上不支援 priority groups，
  -- 即使 vim.fs.root 本身支援 (見 :h vim.fs.root)。
  -- 強組: 真正定義專案位置；弱組: 退而求其次以單檔 cmake 為 root。
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(
      vim.fs.root(fname, { ".git", "compile_commands.json" })
        or vim.fs.root(fname, { "CMakeLists.txt" })
    )
  end,
}
