-- NOTE: https://clangd.llvm.org/guides/system-headers#query-driver
return {
  -- 只讓 clangd 處理 C/C++ 相關的檔案，不包含 "proto"
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  cmd = {
    "clangd",
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
