" Ward off unexpected behavior
set nocompatible
" Set color scheme to something other than Dark blue words on a black
" background
colo elflord
" Determine file type for intelligent auto-indenting
filetype indent plugin on
" Syntax highlighting
syntax on
" Sane default for yaml editing
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

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

" XML/HTML Pretty Printing Functions
function! DoPrettyXML()
        "save the filetype so we can restore it later
        let l:origft = &ft
        set ft=
        "delete the xml header if it exists. This will
        "permit us to surround the document with fake tags
        "without creating invalid xml.
        1s/<?xml .*?>//e
        "insert fake tags around the entire document.
        "This will permit us to pretty-format excerpts of
        "XML that may contain multiple top-level elements
        0put ='<PrettyXML>'
        $put ='</PrettyXML>'
        silent %!xmllint --format -
        "xmllint will insert an <?xml?> header, it's easy enough to delete
        "if you don't want it
        "delete the fake tags
        2d
        $d
        "back to home
        1
        "restore the filetype
        exe "set ft=" . l:origft
endfunction

" HTML pretty printing
function! DoPrettyHTML()
        " First, add line breaks around major HTML tags
        silent %s/></>\r</g
        " Add line breaks before opening tags of major block elements
        silent %s/<\(html\|head\|body\|div\|ul\|ol\|li\)/\r<\1/g
        " Add line breaks after closing tags of container elements only
        silent %s/<\/\(html\|head\|body\|div\|ul\|ol\)>/\r<\/\1>\r/g
        " Remove empty lines
        silent %s/^\s*$\n//g
        " Set HTML filetype and indent
        set ft=html
        normal! ggVG=
        normal! gg
endfunction

" Whitespace visualization toggle
function! DoWhitespace()
        if &list
                set nolist
                echo "Whitespace visualization: OFF"
        else
                set listchars=eol:$,tab:>-
                set list
                echo "Whitespace visualization: ON"
        endif
endfunction

" Commands for easy access
command! PrettyHtml call DoPrettyHTML()
command! PrettyXml call DoPrettyXML()
command! ShowWhitespace call DoWhitespace()

" Filter command copied from vim.wikia.com/wiki/Redirect_g_search_output
command! -nargs=? Filter let @a='' | execute 'g/<args>/y A' | new | setlocal bt=nofile | put! a
