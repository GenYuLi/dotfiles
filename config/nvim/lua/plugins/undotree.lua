local M = {
  "mbbill/undotree",
}

local function undotree()
  vim.cmd.UndotreeShow()
end

M.config = function()
  vim.g.undotree_WindowLayout = 4
  vim.g.undotree_SetFocusWhenToggle = 4
end

M.keys = {
  { "<leader>bu", undotree, desc = "Undo tree" },
}

return M
