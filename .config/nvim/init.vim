" Disable mouse integration except for Visual mode
set mouse=v

" Display tabs in files
set list
set listchars=tab:>-

" Install plug if no data_dir - To be checked
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Map leader to SPACE 
let mapleader = " "

call plug#begin('~/.vim/plugged')
" A cool status bar
Plug 'vim-airline/vim-airline'
" Airline themes
Plug 'vim-airline/vim-airline-themes'
" Solarized colorscheme
Plug 'altercation/vim-colors-solarized'
" Sublime themes
Plug 'tomasr/molokai'
" suda.vim (Allow sudo to write/read files not accessible by the user)
Plug 'lambdalisue/suda.vim'
let g:suda_smart_edit = 1
let g:suda#nopass = 1

set diffopt=internal,filler,closeoff,context:4,algorithm:patience

" Diable syntax in vimdiff mode
if &diff
  syntax off
else
  " Comment/Uncomment tool
  Plug 'scrooloose/nerdcommenter'
  " Switch to the begining and the end of a block by pressing %
  Plug 'tmhedberg/matchit'
  " A Tree-like side bar for better navigation
  Plug 'scrooloose/nerdtree'
  " Nord
  Plug 'arcticicestudio/nord-vim'
  " Better syntax-highlighting for filetypes in vim - Required by coc-ansible
  " for proper filetype detection
  Plug 'sheerun/vim-polyglot'
  " Git integration
  Plug 'tpope/vim-fugitive'
  " Auto-close braces and scopes
  Plug 'jiangmiao/auto-pairs'
  Plug 'jpalardy/vim-slime', { 'for': 'python' }
  Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }
  " Python code folding - zo zO zc zC
  Plug 'tmhedberg/SimpylFold'
  Plug 'tpope/vim-surround'
  Plug 'arouene/vim-ansible-vault', { 'for': ['yaml', 'yaml.ansible'] }
  Plug 'hkupty/iron.nvim'
endif
call plug#end()

" Folding settings
set foldlevel=2

" Set a color column in column ...
" Typically 80... but 80 use to be too short on modern terminal
set colorcolumn=120

" Ansible-Vault
nnoremap <Leader>av :AnsibleVault<CR>
nnoremap <Leader>au :AnsibleUnvault<CR>

" Slime
let g:slime_target = "tmux"
let g:slime_default_config = {"socket_name": get(split($TMUX, ","), 0), "target_pane": ":.1"}
let g:slime_python_ipython = 1

if !exists("g:slime_dispatch_ipython_pause")
  let g:slime_dispatch_ipython_pause = 100
end

function! _EscapeText_python(text)
  if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1
    return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--\n"]
  else
    let empty_lines_pat = '\(^\|\n\)\zs\(\s*\n\+\)\+'
    let no_empty_lines = substitute(a:text, empty_lines_pat, "", "g")
    let dedent_pat = '\(^\|\n\)\zs'.matchstr(no_empty_lines, '^\s*')
    let dedented_lines = substitute(no_empty_lines, dedent_pat, "", "g")
    let except_pat = '\(elif\|else\|except\|finally\)\@!'
    let add_eol_pat = '\n\s[^\n]\+\n\zs\ze\('.except_pat.'\S\|$\)'
    return substitute(dedented_lines, add_eol_pat, "\n", "g")
  end
endfunction

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

" Use templates
" autocmd BufNewFile * silent! 0r ~/.vim/templates/%:e.tpl
if has("autocmd")
  augroup templates
    autocmd BufNewFile *.sh 0r /user/.config/nvim/templates/sh.tpl
    autocmd BufNewFile *.py 0r /user/.config/nvim/templates/python.tpl
    autocmd BufNewFile Dockerfile 0r /user/.config/nvim/templates/dockerfile.tpl
  augroup END
endif

" Select Colors Solarized
set t_Co=256
set background=dark
" colorscheme solarized
colorscheme molokai

" Display line number by default (can be overriden by ftplugin)
set number

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Space for displaying messages. (Set 1 or 2)
set cmdheight=1

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=number

" Alt mappings for moving between panes
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

" Better contrast for CocFloating (default 248)
" highlight CocFloating ctermbg=253 guibg=#b3b3b3
highlight CocFloating ctermbg=256  guibg=#b3b3b3

" Sane defaults
set shiftwidth=4
set softtabstop=4
set expandtab
set splitright

" NERDTree
nnoremap <C-t> :NERDTreeToggle<CR>

" Start NERDTree when Vim is started without file arguments.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
