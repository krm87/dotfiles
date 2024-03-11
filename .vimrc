set number
set linebreak
set showbreak=+++
set textwidth=100
set showmatch
 
set incsearch
set hlsearch

set smartcase
set ignorecase
 
set expandtab
set shiftwidth=4
set smartindent
set smarttab
set softtabstop=4

set ruler
set undolevels=1000
set backspace=indent,eol,start

set showmode
set so=5
set nu rnu
set wildmenu
set cmdheight=1
set rtp+=/opt/homebrew/bin/fzf

set encoding=utf8

syntax on
filetype plugin indent on

call plug#begin('~/.vim/plugged')
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'purescript-contrib/purescript-vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'easymotion/vim-easymotion'
Plug 'machakann/vim-highlightedyank'
Plug 'tpope/vim-surround'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'haya14busa/incsearch.vim'
Plug 'neovimhaskell/haskell-vim'
Plug 'cespare/vim-toml'
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'ionide/Ionide-vim', {
      \ 'do':  'make fsautocomplete',
      \}

call plug#end()

syntax enable
colorscheme dracula
autocmd InsertEnter,InsertLeave * set cul!

let g:fzf_layout = { 'down': '~40%' }

let g:haskell_enable_quantification = 1   " to enable highlighting of `forall`
let g:haskell_enable_recursivedo = 1      " to enable highlighting of `mdo` and `rec`
let g:haskell_enable_arrowsyntax = 1      " to enable highlighting of `proc`
let g:haskell_enable_pattern_synonyms = 1 " to enable highlighting of `pattern`
let g:haskell_enable_typeroles = 1        " to enable highlighting of type roles
let g:haskell_enable_static_pointers = 1  " to enable highlighting of `static`
let g:haskell_backpack = 1                " to enable highlighting of backpack keywords

map <Leader>w <Plug>(easymotion-w)

