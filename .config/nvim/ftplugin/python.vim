set shiftwidth=4
set softtabstop=4
set expandtab

"augroup numbertoggle
  "autocmd!
  "autocmd BufEnter,FocusGained,InsertLeave,WinEnter * set rnu
  "autocmd BufLeave,FocusLost,InsertEnter,WinLeave * set nornu
"augroup END

" From https://www.reddit.com/r/neovim/comments/gcxprs/compile_and_run_inside_vim/
command! Run :vsplit | terminal ipython
vnoremap <leader>R y<c-w>lpa<cr>
