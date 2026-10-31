-- Neovim has no builtin helm detection; without this, chart templates are
-- plain `yaml` and helm_ls (filetypes = { "helm" }) never attaches.
vim.filetype.add {
  pattern = {
    [".*/templates/.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/NOTES%.txt"] = "helm",
  },
}
