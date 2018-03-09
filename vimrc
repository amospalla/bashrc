" FileVersion=56

" To install Vundle:
" git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

""""""""""""""""""""""
""""""""vundle""""""""
""""""""""""""""""""""
set nocompatible
filetype off
" Global vundle
" if $USER == 'root'
" 	set rtp+=/etc/vim/bundle/vundle
" 	call vundle#rc('/etc/vim/bundle')   " Use a shared folder instead of ~/.vimrc/bundle
" else
	set rtp+=~/.vim/bundle/vundle/
	call vundle#rc()
" endif

" let Vundle manage Vundle
" required!
Bundle 'gmarik/vundle'

" original repos on github
""""""""""""""""""""""""""
" Plugin 'floobits/floobits-neovim'
Bundle 'SirVer/ultisnips'
Bundle 'vimoutliner/vimoutliner'
Bundle 'altercation/vim-colors-solarized'
Bundle 'Raimondi/delimitMate'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'godlygeek/tabular'
Bundle 'bling/vim-airline'
let g:airline#extensions#tabline#enabled = 2
" Bundle 'ervandew/supertab'
Bundle 'jnurmine/Zenburn'
Bundle 'scrooloose/nerdcommenter'
" Bundle 'vim-scripts/taglist.vim'
Bundle 'majutsushi/tagbar'
Bundle 'scrooloose/nerdtree'
Bundle 'vimwiki/vimwiki'
Bundle 'gcmt/taboo.vim'
"""""" Python """"""
" Python autocompletion. If used disable python-mode autocompletion with let g:pymode_rope=0
" Vim ide
Bundle 'davidhalter/jedi-vim'
Bundle 'klen/python-mode'
" Python indentation
Bundle 'vim-scripts/indentpython.vim'

" vim-scripts repos
"""""""""""""""""""
" Bundle 'vimwiki'
Bundle 'table-mode'
Bundle 'restore_view.vim'
Bundle 'Align'
Bundle 'AnsiEsc.vim'
Bundle 'DrawIt'
Bundle 'undotree.vim'
Bundle 'vim-signature'
Bundle 'Mark'
Bundle 'TextFormat'
Bundle 'bufexplorer.zip'
Bundle 'VisIncr'
" Bundle 'AutoComplPop' -> al introduir nova línia, autocompleta, ex: /bin/sh -> /bin/bash
" Bundle 'dwm.vim'
Bundle 'buftabs'
Bundle 'SearchComplete'
Bundle 'vim-easy-align'
Bundle 'recover.vim'

" non github repos
""""""""""""""""""
" Bundle 'git://git.wincent.com/command-t.git'

"""""""""""""""""""""""
""""""""opcions""""""""
"""""""""""""""""""""""

set t_Co=256                    " Enable 256 color mode
syntax enable
highlight Comment cterm=italic
if &diff
	set background=dark
endif
set background=dark
colorscheme solarized
" let g:solarized_termcolors=256
" let g:solarized_visibility="high"
" let g:solarized_contrast="high"

" colorscheme zenburn

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set history=50                  " How many lines of history to remember
set ignorecase smartcase        " case insensitive search, except when mixing cases
set hidden                      " allows to change buffer without saving
" set mouse=a                   " enable mouse in all modes
set noerrorbells                " don't make noise
set novisualbell                " don't blink
set exrc                        " Scan working dir for .vimrc
set secure                      " Make the above work safely
set colorcolumn=80
set cursorline
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]\ %<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P
set laststatus=2
" set textwidth=79

filetype plugin indent on


set colorcolumn=80

" http://vimcasts.org/episodes/tabs-and-spaces/
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" UI/Colors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set wildmenu                    " Show suggestions on TAB for some commands
set ruler                       " Always show current positions along the bottom
set cmdheight=1                 " the command bar is 1 high
"set number                     " turn on line numbers
"set nonumber                   " turn off line numbers (problematic with cut&paste)
set lazyredraw                  " do not redraw while running macros (much faster)
set backspace=indent,eol,start  " make backspace work normal
set whichwrap+=<,>,h,l          " make cursor keys and h,l wrap over line endings
set report=0                    " always report how many lines where changed
set fillchars=vert:\ ,stl:\ ,stlnc:\    " make the splitters between windows be blank
" set scrolloff=10                " Start scrolling this number of lines from top/bottomset noexpandtab

"================
" Show invisibles
"================
" Shortcut to rapidly toggle `set list`
nmap <leader>l :set list!<CR>
" Use the same symbols as TextMate for tabstops and EOLs
set listchars=tab:▸\ ,eol:¬,extends:>

" Restore cursor to file position in previous editing session
"       http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
"
" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
"  en windows, emprar per a la opcio n: set viminfo='10,\"100,:20,%,nc:\\some\\place\\under\\Windows\\_viminfo
" set viminfo='10,\"100,:20,%,n~/.viminfo

if has("nvim")
	set viminfo='10,\"100,:20,n~/.viminfo.nvim
else
	set viminfo='10,\"100,:20,n~/.viminfo
endif

" -> change status line depending on the vi mode
" function! InsertStatuslineColor(mode)
"   if a:mode == 'i'
"     hi statusline guibg=magenta
"   elseif a:mode == 'r'
"     hi statusline guibg=blue
"   else
"     hi statusline guibg=red
"   endif
" endfunction
"
" au InsertEnter * call InsertStatuslineColor(v:insertmode)
" au InsertLeave * hi statusline guibg=green
"
" " default the statusline to green when entering Vim
" hi statusline guibg=green

" permet seleccionar mes enlla del text amb el mode de seleccio block
set virtualedit+=block

" To enable persistent undo uncomment following section.
" The undo files will be stored in $HOME/.cache/vim
	if version >= 703
	" enable persistent-undo
	 set undofile

	 " store the persistent undo file in ~/.cache/vim
	 set undodir=~/.cache/vim/undo

	 " create undodir directory if possible and does not exist yet
	 let targetdir=$HOME . "/.cache/vim/undo"
	 if isdirectory(targetdir) != 1 && getftype(targetdir) == "" && exists("*mkdir")
	  call mkdir(targetdir, "p", 0700)
	 endif
	endif

" permet folds per identacio, i marques
" augroup vimrc
"	au BufReadPre * setlocal foldmethod=indent
"	au BufWinEnter * if &fdm == 'indent' | setlocal foldmethod=manual | endif
" augroup END

" " recordar foldings
" autocmd BufWinLeave *.* mkview
" autocmd BufWinEnter *.* silent loadview
" " per defecte es guarden en ~/.vim/view
" set viewdir=~/.cache/vim/view

" http://stackoverflow.com/questions/1549263/how-can-i-create-a-folder-if-it-doesnt-exist-from-vimrc
function! EnsureDirExists (dir)
  if !isdirectory(a:dir)
    if exists("*mkdir")
      call mkdir(a:dir,'p')
      echo "Created directory: " . a:dir
    else
      echo "Please create directory: " . a:dir
    endif
  endif
endfunction

call EnsureDirExists($HOME . '/.cache/vim/view')

" arregla colors en vimdiff
highlight DiffAdd term=reverse cterm=bold ctermbg=green ctermfg=white
highlight DiffChange term=reverse cterm=bold ctermbg=cyan ctermfg=black
highlight DiffText term=reverse cterm=bold ctermbg=gray ctermfg=black
highlight DiffDelete term=reverse cterm=bold ctermbg=red ctermfg=black

" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" " http://vim.wikia.com/wiki/Change_statusline_color_to_show_insert_or_normal_mode "
" """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" " first, enable status line always
" set laststatus=2
" " now set it up to change the status line based on mode
" if version >= 700
"   au InsertEnter * hi StatusLine term=reverse ctermbg=5 gui=undercurl guisp=Magenta
"   au InsertLeave * hi StatusLine term=reverse ctermfg=0 ctermbg=2 gui=bold,reverse
" endif

" Execute file being edited with <Shift> + b:
" map <buffer> <S-b> :w<CR>:!/bin/bash % <CR>

" UltiSnips
let g:UltiSnipsSnippetsDir="~/.vim/bundle/ultisnips/UltiSnips"
let g:UltiSnipsEditSplit="horizontal"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
let g:UltiSnipsListSnippets="<c-l>"

" <Autocompletado>
" ia ifb if [ ]; then
" ia ifc if(){}
" ia whileb while [ ]; do
" ia whilec while(){}
" ia forb for x in ; do
" ia forc for( i=0; i<; i++ ){}
" ia #b #!/bin/env bash
" ia #s #!/bin/sh
" ia #b #!/bin/bash
" ia #p #!/bin/env python
" ia #P #!/bin/env perl}

" restore_view.vim
set viewoptions=cursor,folds,slash,unix
let g:skipview_files = ['*\.vim']

" <Plegado de código!>
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=1

" <Varios>
set showcmd "display incomplete commands
set encoding=utf-8
" set wrap

" <Busquedas>
set hlsearch     " colorea los matches
set incsearch    " busqueda incremental
" set ignorecase " searches are case insen	sitive...
" set smartcase  " ...unless they contain at least one capital letter
set wrap
set linebreak
set nolist  " list disables linebreak
set textwidth=0
set wrapmargin=0
set formatoptions+=l

" vimwiki
" let g:vimwiki_list = [{'path':'~/documents/gestionat/vimwiki', 'path_html':'~/documents/gestionat/vimwiki.html/',   'ext': '.wiki', 'auto_toc': 1, 'auto_export': 1}]

let g:vimwiki_list  = [{'path':'~/documents/gestionat/vimwiki/source/', 'path_html':'~/documents/gestionat/vimwiki/html/', 'ext': '.wiki', 'auto_toc': 1, 'auto_export': 1, 'template_path': '~/documents/gestionat/vimwiki/html/assets/', 'template_default': 'default', 'template_ext': '.tpl' }]

" let g:vimwiki_list = [{'path':'~/documents/gestionat/vimwiki', 'path_html':'~/documents/gestionat/vimwiki.html/',   'ext': '.wiki', 'auto_toc': 1, 'auto_export': 1},
"                   \ {'path':'~/documents/gestionat/inventari', 'path_html':'~/documents/gestionat/inventari.html/', 'ext': '.wiki', 'auto_toc': 1, 'auto_export': 1}]

" Enable loading .vimrc per folder
set exrc
set secure

" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
  let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
  let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
  call append(line("$"), l:modeline)
endfunction
nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

" PEP8 identation
au BufNewFile,BufRead *.py set tabstop=4
au BufNewFile,BufRead *.py set textwidth=79
au BufNewFile,BufRead *.py set expandtab
au BufNewFile,BufRead *.py set autoindent
au BufNewFile,BufRead *.py set fileformat=unix
au BufNewFile,BufRead *.py set softtabstop=4
au BufNewFile,BufRead *.py set shiftwidth=4

" {{{ vimrc.local
if filereadable(glob("~/.vimrc.local"))
	source ~/.vimrc.local
endif
" }}}

" Plugin vim-airline
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
" let g:airline_left_sep = '▶'
" let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.whitespace = 'Ξ'
" let g:airline_powerline_fonts = 1

" highlight trailing white space
" :highlight ExtraWhitespace ctermbg=red guibg=red
" :match ExtraWhitespace /\s\+$/
autocmd InsertEnter * syn clear EOLWS | syn match EOLWS excludenl /\s\+\%#\@!$/
autocmd InsertLeave * syn clear EOLWS | syn match EOLWS excludenl /\s\+$/
highlight EOLWS ctermbg=red guibg=red

" Python
let g:pymode_rope=0

" Run a command on first open:
" configuration:
"	autocmd VimEnter * vnew
" command line:
"	vim -c "vnew"

let g:table_mode_border=0
