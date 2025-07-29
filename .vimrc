" An example for a vimrc file.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2019 Dec 17
"
" To use it, copy it to
"	       for Unix:  ~/.vimrc
"	      for Amiga:  s:.vimrc
"	 for MS-Windows:  $VIM\_vimrc
"	      for Haiku:  ~/config/settings/vim/vimrc
"	    for OpenVMS:  sys$login:.vimrc

if has('persistent_undo')
  call system('mkdir ' . '$HOME/.vim/')
  let undoDir = expand('$HOME/.vim/undodir')
  call system('mkdir ' . undoDir)
  let &undodir = undoDir
  set undofile
endif

" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
if(!has('nvim'))
  source $VIMRUNTIME/defaults.vim
endif

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
augroup END

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initializtion.
if has('syntax') && has('eval')
  packadd! matchit
endif

set ignorecase
set smartcase
set nu
set tabstop=2
set expandtab
set shiftwidth=2
set ruler
set wrapscan
set scrolloff=1
set mouse=a
set encoding=utf-8

call plug#begin()
if(has('nvim')) 
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.6' }
  Plug 'zbirenbaum/copilot.lua'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'CopilotC-Nvim/CopilotChat.nvim', { 'branch': 'canary' }
endif


Plug 'github/copilot.vim'
Plug 'preservim/tagbar',
Plug 'phpactor/phpactor', {'for': 'php', 'tag': '*', 'do': 'composer install --no-dev -o' }
Plug 'neovim/nvim-lspconfig'
Plug 'editorconfig/editorconfig-vim'

if !has('nvim')
  Plug 'ctrlpvim/ctrlp.vim'
endif

Plug 'nordtheme/vim'
Plug 'rking/ag.vim'
Plug 'vim-test/vim-test'
Plug 'airblade/vim-gitgutter'
Plug 'freitass/todo.txt-vim',
Plug 'XadillaX/json-formatter.vim', { 'do': 'npm install -g jjson' }
Plug 'AndrewRadev/undoquit.vim', {'tag': 'v0.1.0'}
Plug 'NLKNguyen/pipe.vim'
"Plug 'TysonAndre/php-vim-syntax'
Plug 'altercation/vim-colors-solarized'
Plug 'chrisbra/vim-xml-runtime'
Plug 'easymotion/vim-easymotion'
Plug 'michaeljsmith/vim-indent-object'
Plug 'nicwest/vim-http',
Plug 'preservim/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-airline/vim-airline'
Plug 'vim-scripts/ReplaceWithRegister'
call plug#end()


let g:vim_http_tempbuffer=1
let g:vim_http_split_vertically=1
let g:netrw_liststyle=3
let phpunit_bin="./vendor/bin/phpunit"

set textwidth=71
set nomodeline
call togglebg#map("<F5>")

" Nord related settings
colorscheme nord

" Visual selection highlight workaround
let s:nord2_gui = "#434C5E"
let s:nord8_term = "6"

function! s:hi(group, guifg, guibg, ctermfg, ctermbg, attr, guisp)
  let cmd = ""
  if a:guifg != ""
    let cmd = cmd . " guifg=" . a:guifg
  endif
  if a:guibg != ""
    let cmd = cmd . " guibg=" . a:guibg
  endif
  if a:ctermfg != ""
    let cmd = cmd . " ctermfg=" . a:ctermfg
  endif
  if a:ctermbg != ""
    let cmd = cmd . " ctermbg=" . a:ctermbg
  endif
  if a:attr != ""
    let cmd = cmd . " gui=" . a:attr . " cterm=" . substitute(a:attr, "undercurl", s:underline, "")
  endif
  if a:guisp != ""
    let cmd = cmd . " guisp=" . a:guisp
  endif
  if cmd != ""
    exec "hi " . a:group . cmd
  endif
endfunction

call s:hi("Visual", "", s:nord2_gui, "", s:nord8_term, "", "")

set background=dark

command Errors normal oini_set('display_errors','1');<Esc>
command TemplateTestCase normal iuse PHPUnit\Framework\TestCase;class FooTest extends TestCase{function test(){}}<Esc>
command TrimTraillingWhiteSpaces %s/\s\+$//g | noh

" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>

" Easymotion
map <Leader> <Plug>(easymotion-prefix)

" Easymotion. hjkl config
map <Leader>l <Plug>(easymotion-lineforward)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
map <Leader>h <Plug>(easymotion-linebackward)

let g:EasyMotion_startofline = 0 " keep cursor column when JK motion

" Git Gutter (Prevent conflict with Easymotion hjkl config
nmap <Leader>up <Plug>(GitGutterPreviewHunk)
nmap <Leader>uu <Plug>(GitGutterUndoHunk)
nmap <Leader>us <Plug>(GitGutterStageHunk)
xmap <Leader>us <Plug>(GitGutterStageHunk)

" Telescope
if has('nvim')
  " Telescope
  nnoremap <C-p> :Telescope find_files<cr>
  nnoremap <Leader><C-u> :Telescope buffers<cr>
  nnoremap <Leader>O :Telescope find_files<cr>
endif

" Lazy window switch mappings
nmap <silent> <C-j> :wincmd j<CR>
nmap <silent> <C-k> :wincmd k<CR>
nmap <silent> <C-h> :wincmd h<CR>
nmap <silent> <C-l> :wincmd l<CR>

" Ergonomic tab switch mappings (unimpaired inspired)
nmap <silent> >t :tabnext<cr>
nmap <silent> <t :tabprev<cr>

" Vim airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" CtrlP
if !has('nvim')
  map <Leader><C-u> :CtrlPBuffer<cr>
endif

function! DefineTermCommand(cmd, term)
    execute 'command' a:cmd 'edit term://' . a:term . ' | file' a:cmd . ' | normal a'
endfunction

" Lazygit command
call DefineTermCommand('LazyGit', 'lazygit')

" Terminal command
call DefineTermCommand('Terminal', 'bash')

