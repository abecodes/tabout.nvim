if !has('nvim-0.5')
  echohl WarningMsg
  echom "tabout.nvim needs Neovim >= 0.5"
  echohl None
  finish
endif

if exists('g:loaded_tabout') | finish | endif " prevent loading file twice

let g:loaded_tabout = 1
