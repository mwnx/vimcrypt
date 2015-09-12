" Folding functions. Useful for instance in the case that you have a file
" containing all your passwords and you don't wish for them to be revealed
" all at once.

function! vimcrypt#fold#setup_pwdfold()
    "fold by paragraph:
    setlocal foldexpr=
        \getline(v:lnum)=~'^\\s*$'&&getline(v:lnum+1)=~'\\S'?'<1':1
    setlocal foldmethod=expr
    "show only first word of paragraph:
    setlocal foldtext='['.(v:foldend-v:foldstart+1).']\ '.
                \matchstr(getline(v:foldstart),'[^\ ]*')
    setlocal foldlevel=0
endfunction
