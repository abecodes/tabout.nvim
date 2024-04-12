if vim.g.loaded_tabout_nvim then
  return
end

if not vim.treesitter or type(vim.treesitter.get_parser) ~= "function" then
  vim.notify("tabout.nvim requires a Neovim version with treesitter support", vim.log.levels.ERROR)
end

vim.g.loaded_tabout_nvim = true
