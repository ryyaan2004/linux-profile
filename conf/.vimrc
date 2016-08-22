" Ward off unexpected behavior
set nocompatible
" Set color scheme to something other than Dark blue words on a black
" background
colo elflord
" Determine file type for intelligent auto-indenting
filetype indent plugin on
" Syntax highlighting
syntax on

" Highlight searches
set hlsearch
" Case insensitive searches, execpt when using capital letters
set ignorecase
set smartcase
" Keep the same indenting as current line when opening a new line and there is
" no file type specific indenting enabled.
set autoindent
" Not all movements go to the first character in a line
set nostartofline
" Display the cursor position on last line of screen
set ruler
" Raise a dialogue asking if you wish to save changed files
set confirm
" Use the mouse (all modes)
set mouse=a
" Command window height is 2 lines
set cmdheight=2
" Show 'hybrid' mode numbers where current line is absolute and all others are
" relative.
set number
set relativenumber

" Toggle between relative and absolute line numbering
function! RelativeNumberToggle()
	if(&relativenumber == 1)
		set norelativenumber
	else
		set relativenumber
	endif
endfunc

nnoremap <C-n> :call RelativeNumberToggle()<cr>
