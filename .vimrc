set fenc=utf-8

set number

syntax on

set list

set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

set expandtab

set tabstop=2

set showmatch

set autoindent

set whichwrap=b,s,[,],<,>

set softtabstop=0

set virtualedit=block

function! HardMode ()
  noremap <Up> <Nop>
  noremap <Down> <Nop>
  noremap <Left> <Nop>
  noremap <Right> <Nop>
endfunction

function! EasyMode ()
  noremap <Up> <Up>
  noremap <Down> <Down>
  noremap <Left> <Left>
  noremap <Right> <Right>
endfunction

command! HardMode call HardMode()
command! EasyMode call EasyMode()
