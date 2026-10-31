-- .txtpb has no LSP. On save, validate the file against its "# proto-file" /
-- "# proto-message" header with txtpbcheck (dotfiles config/tools) and show
-- the result as diagnostics. txtpbfmt formatting is wired through conform.
if vim.fn.executable("txtpbcheck") == 0 then
  return
end

local ns = vim.api.nvim_create_namespace("txtpbcheck")
local buf = vim.api.nvim_get_current_buf()

vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = buf,
  group = vim.api.nvim_create_augroup("txtpbcheck." .. buf, { clear = true }),
  callback = function(ev)
    vim.system(
      { "txtpbcheck", ev.file },
      { text = true },
      vim.schedule_wrap(function(out)
        local diags = {}
        for line in ((out.stdout or "") .. (out.stderr or "")):gmatch("[^\n]+") do
          local lnum, col, msg = line:match("^.-:(%d+):(%d+): (.*)$")
          if lnum then
            local warn = msg:match("^warning: (.*)$")
            diags[#diags + 1] = {
              lnum = tonumber(lnum) - 1,
              col = tonumber(col) - 1,
              message = warn or msg,
              severity = warn and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
              source = "txtpbcheck",
            }
          elseif out.code ~= 0 then
            -- protoc output without a position (missing import, bad header)
            diags[#diags + 1] = { lnum = 0, col = 0, message = line, source = "txtpbcheck" }
          end
        end
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.diagnostic.set(ns, ev.buf, diags)
        end
      end)
    )
  end,
})
