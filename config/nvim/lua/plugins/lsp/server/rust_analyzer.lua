-- return {
--   settings = {
--     ["rust-analyzer"] = {
--       checkOnSave = true,
--       check = { command = "clippy", features = "all" },
--       assist = {
--         importGranularity = "module",
--         importPrefix = "self",
--       },
--       diagnostics = {
--         enable = true,
--         enableExperimental = true,
--       },
--       cargo = {
--         loadOutDirsFromCheck = true,
--         features = "all", -- avoid error: file not included in crate hierarchy
--       },
--       procMacro = {
--         enable = true,
--       },
--       inlayHints = {
--         chainingHints = true,
--         parameterHints = true,
--         typeHints = true,
--       },
--     },
--   },
-- }
--
--


-- 檔案路徑: plugins/lsp/server/rust-analyzer.lua (根據你的專案結構)

return {
  settings = {
    ["rust-analyzer"] = {
      -- 1. Cargo 設定: 啟用所有 features，並載入 build script 的輸出
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        buildScripts = {
          enable = true,
        },
      },

      -- 2. Proc Macro 設定: 啟用屬性宏和函數宏的支援
      procMacro = {
        enable = true,
        ignored = {
          -- 如果有特定宏導致效能問題，可以在此忽略
          -- ["async-trait"] = { "async_trait" },
        },
      },

      -- 3. 診斷與存檔時檢查: 使用 clippy 進行更嚴格的檢查
      check = {
        command = "clippy",
        -- 推薦的新寫法，取代 checkOnSave = true
        onSave = true,
        extraArgs = { "--no-deps" }, -- 可選：加快檢查速度，不檢查依賴
      },

      -- 4. 補全所有 Inlay Hints，並微調以減少雜訊
      inlayHints = {
        -- 類型提示
        typeHints = {
          enable = true,
          -- 減少雜訊：當賦值的值已經明確表明類型時，隱藏左側的類型提示
          hideInsideAssignedValue = true,
        },
        -- 鏈式呼叫提示
        chainingHints = {
          enable = true,
        },
        -- 參數名提示
        parameterHints = {
          enable = true,
        },
        -- 閉合大括號提示，對長函數和 async block 特別有用
        closingBraceHints = {
          enable = true,
          minLength = 25, -- 程式碼塊超過 25 行才顯示
        },
        -- 顯示被省略的生命週期
        lifetimeElisionHints = {
          enable = true,
          useParameterNames = true, -- 使用參數名而非 'a, 'b
        },
        -- 其他實用提示
        reborrowHints = { enable = true },
        discriminantHints = { enable = true },
      },

      -- 5. 啟用 CodeLens (程式碼鏡頭)
      lens = {
        enable = true,
        -- 你可以選擇性地關閉某些 lens
        locations = { "method", "impl" },
        runnable = true,
        references = true,
        implementations = true,
        methodReferences = false, -- 這個有時有點吵，預設關閉
      },

      -- 6. 啟用懸浮視窗中的可操作按鈕
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

      -- 7. 程式碼輔助相關
      assist = {
        importGranularity = "module",
        importPrefix = "crate", -- 'crate' 是另一種常見風格，相對於 'self'
      },
      
      -- 8. 實驗性功能 (可選)
      experimental = {
        -- 'procAttrMacros' 是對屬性宏的進一步支援，可以嘗試開啟
        procAttrMacros = true,
      }
    },
  },
}}
