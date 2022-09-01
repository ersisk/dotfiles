" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

Plug 'junegunn/vim-easy-align'
Plug 'https://github.com/junegunn/vim-github-dashboard.git'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
Plug 'fatih/vim-go', { 'tag': '*' }
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'vim-scripts/taglist.vim'
Plug 'StanAngeloff/php.vim'
Plug 'ervandew/supertab'
Plug 'vim-airline/vim-airline'
Plug 'borissov/vim-mysql-suggestions'
Plug 'jparise/vim-graphql'
Plug 'scrooloose/syntastic'
Plug 'yggdroot/indentline'
Plug 'symfony/symfony'
Plug 'amiorin/vim-project'
Plug 'kristijanhusak/defx-git'
Plug 'kristijanhusak/defx-icons'
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'kchmck/vim-coffee-script', { 'for': 'coffee' }
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'phpactor/phpactor'
Plug 'StanAngeloff/php.vim' 
Plug 'ncm2/ncm2'
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
Plug 'phpactor/ncm2-phpactor'

let g:deoplete#enable_at_startup = 1
call plug#end()

set number
syntax enable
set background=dark
colorscheme onedark
set laststatus=2
set tabstop=4
set softtabstop=0 noexpandtab
set shiftwidth=4
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
set autoindent
set backspace=indent,eol,start

nnoremap <silent> <C-f> :Files<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

nmap <Leader>u :call phpactor#UseAdd()<CR>

" Invoke the context menu
nmap <Leader>mm :call phpactor#ContextMenu()<CR>

" Invoke the navigation menu
nmap <Leader>nn :call phpactor#Navigate()<CR>

" Goto definition of class or class member under the cursor
nmap <Leader>o :call phpactor#GotoDefinition()<CR>

" Show brief information about the symbol under the cursor
nmap <Leader>K :call phpactor#Hover()<CR>

" Transform the classes in the current file
nmap <Leader>tt :call phpactor#Transform()<CR>

" Generate a new class (replacing the current file)
nmap <Leader>cc :call phpactor#ClassNew()<CR>

" Extract expression (normal mode)
nmap <silent><Leader>ee :call phpactor#ExtractExpression(v:false)<CR>

" Extract expression from selection
vmap <silent><Leader>ee :<C-U>call phpactor#ExtractExpression(v:true)<CR>

" Extract method from selection
vmap <silent><Leader>em :<C-U>call phpactor#ExtractMethod()<CR>

" some extra phpactor maps
map <silent><Leader>pfm :call phpactor#MoveFile()<CR>
nmap <Leader>e :call phpactor#ClassExpand()<CR>
nmap <Leader>cv :call phpactor#ChangeVisibility()<CR>
nmap <silent><Leader>K :call phpactor#Hover()<CR>

" phpactor additional config
let g:phpactorPhpBin = 'php' " php executable to use
let g:phpactorBranch = 'master' " phpactor branch to use
let g:phpactorOmniAutoClassImport = v:true " automatically import classes with omnicomplete
