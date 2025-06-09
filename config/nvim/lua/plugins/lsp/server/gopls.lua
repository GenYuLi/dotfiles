-- 檔案路徑: plugins/lsp/server/gopls.lua

return {
  settings = {
    -- 1. 所有設定都必須包在 "gopls" 表格中
    gopls = {
      -- 啟用 gofumpt 作為格式化工具
      gofumpt = true,

      -- CodeLens 設定
      codelenses = {
        gc_details = false, -- 這個通常有點吵，設為 false 是個好選擇
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },

      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },

      -- 靜態分析工具
      analyses = {
        fieldalignment = true,
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },

      -- 其他實用設定
      usePlaceholders = true, -- 在補全函式時，為參數生成佔位符
      completeUnimported = true, -- 自動補全時，會提示尚未 import 的 package
      staticcheck = true, -- 啟用 staticcheck 分析

      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
    },
  },
}
